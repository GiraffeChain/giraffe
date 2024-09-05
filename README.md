# Giraffe Chain
**Blockchain** | **Mobile+Web Staking** | **Graph Database** | **Experimental**

### [Documentation](https://seancheatham.github.io/giraffe/)

You've found the repository for yet another blockchain protocol. This protocol uses proof-of-stake for consensus and UTxOs for its ledger.

Similar to other application layers, tokens are distributed and spent using an "Unspent Transaction Output" model. *Unlike* other UTxO models, each UTxO may represent a "vertex" or "edge" of a **ledger-wide graph data structure**. Connecting two "vertex" UTxOs with a new "edge" UTxO requires permission from each of the "vertex" UTxOs. The intention is to provide a developer-friendly graph database that is backed by a decentralized blockchain.

Similar to other protocols, the network is made up of relay nodes which verify correctness of the chain and distribute information to other peers. *Unlike* other protocols, **block production is performed client-side within user wallets**. The intention is to decentralize as much as possible by making it simple for everyday people to stake. The ideal outcome is for millions of people to participate from their phones.

To demonstrate the utility of the graph database, the wallet includes a mini **social network** which allows people to share and connect.

The whole thing is included here, in a monorepo.

This blockchain is still in very **early development**. Everything is **experimental**. You are more than welcome to use the code in this repository, but there are no guarantees that it'll be bug-free. **Don't use real money** (as if such a thing exists). If nothing else, this project aims to experiment with web3 ideas.

## Limitations
- Staking currently requires significant trust in the connected relay node.
- To limit an explosion of storage, graph data is encumbered by tokens/funds. There is a limit on the vertex/edge information that can be stored.
- Blocks are currently produced every ~30 seconds.

## Run
At the moment, there are no public testnets. That'll happen eventually. You can instead launch a local private testnet.
1. `docker run --rm -p 2024:2024 seancheatham/giraffe-node:latest`
1. Open the [wallet](http://localhost:2024) in your browser
1. Select the "Public" wallet (this is a shared wallet meant for testing purposes)
1. Select the "Stake" Tab. Click the little "warning" triangle to enter advanced mode. In the staker index dropdown, select `0`. Click "Start".

## SDK

The SDK is written in TypeScript and is published to NPM. Other languages will be supported in the future. Feel free to create a new Issue if you have a suggestion for the next language.

### Install
<details>
  <summary>Click to Expand</summary>

  Install SDK module:
  ```sh
  npm install @giraffechain/giraffe-sdk
  ```
</details>

### Initialize
<details>
  <summary>Click to Expand</summary>

  #### First launch
  ```ts
  import * as g from "@giraffechain/giraffe-sdk";
  // The user of your app should record this mnemonic somewhere (using pen and paper preferably)
  const mnemonic = g.GiraffeWallet.generateMnemonic();
  // The user of your app should provide their own password
  const password = "";
  // This key can be saved somewhere (securely) for future retrieval
  const sk = await g.GiraffeWallet.keyFromMnemonic(mnemonic, password);
  // "giraffe" is your entrypoint into the rest of the SDK
  const giraffe = await g.Giraffe.init("http://localhost:2024/api", g.GiraffeWallet.fromSk(sk));

  // Because this is a new wallet, it has no funds. You can receive funds from the "genesis" wallet
  await giraffe.transferFromGenesisWallet(5000000);

  // Funds will be available in the main wallet after the next block
  await giraffe.client.nextBlockId();
  ```

  #### Subsequent launches
  ```ts
  import * as g from "@giraffechain/giraffe-sdk";
  // Implement your own functionality to load the key you saved from the first launch
  const sk = loadKey();
  const giraffe = await g.Giraffe.init("http://localhost:2024", g.GiraffeWallet.fromSk(sk));
  ```
</details>

### Send funds
<details>
  <summary>Click to Expand</summary>

  ```ts
  // This function adds the necessary inputs to fund the desired outputs, handles fees, signs, and broadcasts the transaction.
  const tx = await giraffe.paySignBroadcast(
    g.Transaction.fromJSON(
      {
        outputs: [
          {
            lockAddress: g.decodeLockAddress("a_123456"),
            value: {
              quantity: 5000,
            }
          }
        ],
      }
    )
  );
  ```
</details>

### Create graph data
<details>
  <summary>Click to Expand</summary>

  ```ts
  await giraffe.paySignBroadcast(
    Transaction.fromJSON(
      {
        outputs: [
          giraffe.graph.createVertexOutput("user", undefined),
          giraffe.graph.createVertexOutput("profile", {"firstName": "Alan", "lastName": "Turing"})
          // Creates an edge connecting two vertices from _this_ transaction
          giraffe.graph.createEdgeOutput("userProfile", {transactionId: undefined, index: 1}, {transactionId: undefined, index: 0}, {})
        ]
      }
    )
  );
  ```
</details>

### Query graph data
<details>
  <summary>Click to Expand</summary>

  ```ts
  const vertexIds = await giraffe.client.queryVertices("profile", [["firstName", "==", "Alan"]]);
  for(const vertexId of vertexIds) {
    const output = await giraffe.client.getTransactionOutput(vertexId);
    const vertex = output.value?.graphEntry?.vertex!;
    const lastName = vertex.data["lastName"];
  }
  ```
</details>

## Wallet Platform Support
- While the intention is to support staking-based wallets on web and mobile, Linux desktop is currently the most stable.
  - Web doesn't easily support multithreading, so some aspects of the wallet are slow.
  - Android support should generally work.
  - iOS is not setup yet, and I have no means of testing it. If any Mac/iPhone user wants to lend a hand here, I'd appreciate it.
  - MacOS is not setup yet, and I have no means of testing it. If any Mac user wants to lend a hand here, I'd appreciate it.
  - Windows is also not setup yet. I sort of have a means of testing it, but at the moment it's not a high priority. Feel free to create an Issue if you'd like to see this added sooner.

## Development & Testing
<details>
  <summary>Click to Expand</summary>

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

### Implementation & Directory Structure
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
</details>
