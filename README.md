# "Blockchain"
A generic, unbranded blockchain protocol. It leverages Taktikos for its consensus layer and an extended UTxO model for its application layer.

Similar to other protocols, the network is made up of relay nodes which verify correctness of the chain and distribute information to other peers. Unlike other protocols, block production is performed client-side within user wallets.

Similar to other application layers, tokens are distributed and spent using an "Unspent Transaction Output" model. Unlike other UTxO models, each UTxO may represent a "vertex" or "edge" of a ledger-wide graph data structure. Connecting two "vertex" UTxOs with a new "edge" UTxO requires permission from each of the "vertex" UTxOs.

## Implementation
- Models are defined in protobuf, and you can find them in the `proto/` directory.
  - Misc/support files are defined in `external_proto/`
- The backend/relay node is defined in Scala, and you can find it in the `scala/` directory.
  - Most of the code is defined in the `core` module
  - Compiled protobuf files are defined in the `protobuf` module
- The frontend/wallet is defined in Dart/Flutter, and you can find it in the `dart/` directory.
  - The code is split between the `sdk` and `app` packages
  - Compiled protobuf files are defined in the `protobuf_dart` package

## Development & Testing
### Dependencies
- JDK 17+
- SBT/Scala
- Flutter

### Launch
1. Start the relay node.
    - `cd scala`
    - `sbt core/run`
1. Start the frontend.
    - `cd ../dart/app`
    - `flutter run`

## Platform Support
- While the intention is to support staking-based wallets on web and mobile, Linux desktop is currently the most stable.
  - Android support should generally work. iOS will probably work, but I have no means of testing.
  - Web support currently suffers an base-52 limitation somewhere in the VRF code. As such, it currently produces invalid blocks.

## Upcoming Goals
- SDK support for JS/TS
- Stability, resiliency, and error handling of wallet-staking
- Testing
- Documentation