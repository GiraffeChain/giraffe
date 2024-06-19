# "Blockchain"
A generic, unbranded blockchain protocol. It leverages Taktikos for its consensus layer and an extended UTxO model for its application layer.

Similar to other protocols, the network is made up of relay nodes which verify correctness of the chain and distribute information to other peers. Unlike other protocols, block production is performed client-side within user wallets.

Similar to other application layers, tokens are distributed and spent using an "Unspent Transaction Output" model. Unlike other UTxO models, each UTxO may represent a "vertex" or "edge" of a ledger-wide graph data structure. Connecting two "vertex" UTxOs with a new "edge" UTxO requires permission from each of the "vertex" UTxOs.

## Implementation
Models are defined in protobuf. The backend/relay node is defined in Scala. The frontend/wallet is defined in Dart/Flutter. The "frontend" is capable of running the full protocol, but for performance, the Scala version is the preferred relay node implementation.

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
