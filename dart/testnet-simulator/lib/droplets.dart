import 'dart:convert';

import 'package:giraffe_protocol/protocol.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:giraffe_testnet_simulator/log.dart';

class RelayDroplet {
  final String id;
  final String ip;
  final String region;

  RelayDroplet({required this.id, required this.ip, required this.region});

  static Future<RelayDroplet> create(
    String simulationId,
    int index,
    String digitalOceanToken,
    String genesisUrl,
    List<String> peers,
  ) async {
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $digitalOceanToken",
    };
    final launchScript = """#!/bin/bash
ufw allow 2023
ufw allow 2024
docker run -d --restart=always --pull=always --name giraffe-simulation-relay -p 2023:2023 -p 2024:2024 giraffechain/node:dev --genesis $genesisUrl${peers.map((p) => " --peer $p").join("")}
    """;
    final region = regions[index % regions.length];
    final bodyJson = {
      "name": "giraffe-simulation-relay-$simulationId-$index",
      "region": region,
      "size": "s-1vcpu-1gb",
      "image": "docker-20-04",
      "user_data": launchScript,
      "tags": [dropletTag],
    };
    final response = await httpClient.post(
        Uri.parse("https://api.digitalocean.com/v2/droplets"),
        headers: headers,
        body: utf8.encode(jsonEncode(bodyJson)));
    final bodyUtf8 = utf8.decode(response.bodyBytes);
    if (response.statusCode != 202) {
      throw StateError(
          "Failed to create relay droplet. status=${response.statusCode} body=${bodyUtf8}");
    }

    final body = jsonDecode(bodyUtf8);
    final id = (body["droplet"]["id"] as int).toString();
    final ip = await dropletIp(digitalOceanToken, id);
    log.info("Created relay container id=$id ip=$ip region=$region");
    return RelayDroplet(id: id, ip: ip, region: region);
  }

  BlockchainClient get client =>
      BlockchainClientFromJsonRpc(baseAddress: "http://$ip:2024/api");
}

class StakingDroplet {
  final String id;
  final String ip;

  StakingDroplet({required this.id, required this.ip});

  static Future<StakingDroplet> create(
    String simulationId,
    int index,
    String digitalOceanToken,
    StakingAccount account,
    RelayDroplet relay,
  ) async {
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $digitalOceanToken",
    };
    final apiAddress = "http://${relay.ip}:2024/api";
    final stakerData = account.stakerData.serialized;
    final launchScript = """#!/bin/bash
docker run -d --restart=always --pull=always --name giraffe-simulation-staker giraffechain/staker:dev --api-address $apiAddress --staker-data $stakerData
    """;
    final bodyJson = {
      "name": "giraffe-simulation-staker-$simulationId-$index",
      "region": relay.region,
      "size": "s-1vcpu-1gb",
      "image": "docker-20-04",
      "user_data": launchScript,
      "tags": [dropletTag],
    };
    final response = await httpClient.post(
        Uri.parse("https://api.digitalocean.com/v2/droplets"),
        headers: headers,
        body: utf8.encode(jsonEncode(bodyJson)));
    final bodyUtf8 = utf8.decode(response.bodyBytes);
    if (response.statusCode != 202) {
      throw StateError(
          "Failed to create staker droplet. status=${response.statusCode} body=${bodyUtf8}");
    }
    final body = jsonDecode(bodyUtf8);
    final id = (body["droplet"]["id"] as int).toString();
    final ip = await dropletIp(digitalOceanToken, id);
    log.info(
        "Created staking container id=$id ip=$ip region=${relay.region} relay=${relay.ip}");
    return StakingDroplet(id: id, ip: ip);
  }
}

// https://docs.digitalocean.com/platform/regional-availability/#droplets
// These regions are roughly sorted by geographic distribution
const regions = [
  "nyc2",
  "syd1",
  "ams3",
  "sfo2",
  "fra1",
  // These regions do not support the `docker-20-04` DigitalOcean image
  // "nyc3",
  // "nyc1",
  // "sfo1",
  // "ams2",
  // "sgp1",
  // "lon1",
  // "tor1",
  // "blr1",
  // "sfo3",
];

Future<String> dropletIp(String digitalOceanToken, String id) =>
    retryableFuture(() async {
      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $digitalOceanToken",
      };
      final response = await httpClient.get(
        Uri.parse("https://api.digitalocean.com/v2/droplets/$id"),
        headers: headers,
      );
      final bodyUtf8 = utf8.decode(response.bodyBytes);
      if (response.statusCode != 200) {
        throw StateError(
            "Failed to get droplet. status=${response.statusCode} body=${bodyUtf8}");
      }
      final body = jsonDecode(bodyUtf8);
      final ips = body["droplet"]["networks"]["v4"] as List<dynamic>;
      if (ips.isEmpty) {
        throw StateError("No public ip found for droplet $id");
      }
      final ip = ips.firstWhere((ip) => ip["type"] == "public")["ip_address"];
      if (ip == null) {
        throw StateError("No public ip found for droplet $id");
      }
      return ip as String;
    }, retries: 60, delay: const Duration(seconds: 3));

Future<void> deleteSimulationDroplets(String digitalOceanToken) async {
  final headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer $digitalOceanToken",
  };
  final response = await httpClient.delete(
    Uri.parse("https://api.digitalocean.com/v2/droplets?tag_name=$dropletTag"),
    headers: headers,
  );
  if (response.statusCode >= 300) {
    throw StateError(
        "Failed to delete droplets. status=${response.statusCode}");
  }
}

const dropletTag = "giraffe-testnet-simulation";
