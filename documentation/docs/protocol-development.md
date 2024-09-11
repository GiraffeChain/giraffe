---
title: Protocol Development
description: Information about developing, testing, and contributing to the protocol.
sidebar_position: 6
---

# Protocol Development

Contribution guidelines haven't yet been formalized. Ideas and suggestions are welcome in this regard. For now, if you have a change you'd like to make, pleae feel free to submit a Pull Request!

## Dependencies
- JDK 17+
- SBT/Scala
- Flutter
- NodeJS 20+

## Launch
1. Start the relay node.
    - `cd scala`
    - `sbt relay/run`
1. Start the wallet.
    - `cd ../dart/wallet`
    - `flutter run`

## Implementation & Directory Structure
- Models are defined in protobuf, and you can find them in the `proto/` directory.
  - Misc/support files are defined in `external_proto/`
  - Protobuf models are served over JSON-RPC, not gRPC
- The backend/relay node is defined in Scala, and you can find it in the `scala/` directory.
  - Most of the code is defined in the `node` module
  - Compiled protobuf files are defined in the `protobuf` module
- The wallet is defined in Dart/Flutter, and you can find it in the `dart/` directory.
  - The `sdk` directory contains a client, codecs, wallet, and miscellaneous utilities for interacting with the chain
  - The `wallet` directory is an application with a built-in wallet, block explorer, staker, and social explorer
- The SDK is defined in Typescript, and you can find it in the `typescript/sdk/` directory.
