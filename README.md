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
  - Most of the code is defined in the `node` module
  - Compiled protobuf files are defined in the `protobuf` module
- The wallet is defined in Dart/Flutter, and you can find it in the `dart/` directory.
  - The `sdk` directory contains a client, codecs, wallet, and miscellaneous utilities for interacting with the chain
  - The `wallet` directory is an application with a built-in wallet, block explorer, staker, and social explorer
- The SDK is defined in Typescript, and you can find it in the `typescript/sdk/` directory.

## Launching
At the moment, there are no public testnets. You can instead launch a local private testnet.
1. `docker run --rm -p 2024:2024 seancheatham/giraffe-node:dev`
1. Open the [wallet](http://localhost:2024) in your browser
1. Select the "Public" wallet (this is a shared/reusable wallet where the secret key is all zeros)
1. Select the "Stake" Tab. Click the little "warning" triangle to enter advanced mode. In the staker index dropdown, select `0`. Click "Start".

## Development & Testing
### Dependencies
- JDK 17+
- SBT/Scala
- Flutter
- NodeJS 20+

### Launch
1. Start the relay node.
    - `cd scala`
    - `sbt relay/run`
1. Start the wallet.
    - `cd ../dart/app`
    - `flutter run`

## Wallet Platform Support
- While the intention is to support staking-based wallets on web and mobile, Linux desktop is currently the most stable.
  - Web doesn't easily support multithreading, so some aspects of the wallet are slow.
  - Android support should generally work.
  - iOS is not setup yet, and I have no means of testing it. If any Mac/iPhone user wants to lend a hand here, I'd appreciate it.
  - MacOS is not setup yet, and I have no means of testing it. If any Mac user wants to lend a hand here, I'd appreciate it.
  - Windows is also not setup yet. I sort of have a means of testing it, but at the moment it's not a high priority. Feel free to create an Issue if you'd like to see this added sooner.

## Upcoming Goals
- Stability, resiliency, and error handling of wallet-staking
- Testing
- Documentation
