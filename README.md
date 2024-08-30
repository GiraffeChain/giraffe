# Giraffe Chain
**Blockchain** | **Mobile Staking** | **Graph Database**

You've found the repository for yet another blockchain protocol. This protocol uses proof-of-stake for consensus and UTxOs for its ledger.

Similar to other protocols, the network is made up of relay nodes which verify correctness of the chain and distribute information to other peers. **Unlike** other protocols, block production is performed client-side within user wallets. The intention is to decentralize as much as possible by making it as simple as possible for normal users to stake. The ideal outcome is for millions of people to stake from their phones.

Similar to other application layers, tokens are distributed and spent using an "Unspent Transaction Output" model. **Unlike** other UTxO models, each UTxO may represent a "vertex" or "edge" of a ledger-wide graph data structure. Connecting two "vertex" UTxOs with a new "edge" UTxO requires permission from each of the "vertex" UTxOs. The intention is to provide a developer-friendly graph database that is backed by a decentralized blockchain.

To demonstrate the utility of the graph database, the wallet includes a mini social network which allows people to share and connect.

This blockchain is still in very early development. Everything is experimental. Don't use real money (as if such a thing exists). You are more than welcome to use the code in this repository, but there are no guarantees that it'll be bug-free.

## Implementation
- Models are defined in protobuf, and you can find them in the `proto/` directory.
  - Misc/support files are defined in `external_proto/`
  - Protobuf models are served over JSON-RPC, not gRPC
- The backend/relay node is defined in Scala, and you can find it in the `scala/` directory.
  - Most of the code is defined in the `core` module
  - Compiled protobuf files are defined in the `protobuf` module
- The wallet is defined in Dart/Flutter, and you can find it in the `dart/` directory.
  - The code is split between the `sdk` and `wallet` packages
- The SDK is defined in Typescript, and you can find it in the `typescript/sdk/` directory.

## Development & Testing
### Dependencies
- JDK 17+
- SBT/Scala
- Flutter
- NodeJS 20+

### Launch
1. Start the relay node.
    - `cd scala`
    - `sbt core/run`
1. Start the wallet.
    - `cd ../dart/app`
    - `flutter run`

## Wallet Platform Support
- While the intention is to support staking-based wallets on web and mobile, Linux desktop is currently the most stable.
  - Android support should generally work. iOS will probably work, but I have no means of testing.
  - Web support currently suffers an base-52 limitation somewhere in the VRF code. As such, it currently produces invalid blocks.
  - Web doesn't easily support multithreading, so some aspects of the wallet are slow

## Upcoming Goals
- Stability, resiliency, and error handling of wallet-staking
- Testing
- Documentation
