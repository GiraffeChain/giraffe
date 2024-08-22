import 'package:fetch_client/fetch_client.dart';
import 'package:http/http.dart';

final corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "*",
  "Access-Control-Allow-Methods": "POST,GET,DELETE,PUT,OPTIONS",
};

Client makeHttpClient() =>
    FetchClient(mode: RequestMode.cors, streamRequests: false);
