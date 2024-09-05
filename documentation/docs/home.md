---
sidebar_position: 1
title: Home
---

# Giraffe Chain Docs

Welcome to the official documentation portal for Giraffe Chain. You'll find information on how to run and interact with the chain. You'll also find some general information about blockchains and graph databases.

If you're unfamiliar with blockchains or web3, head on over to the [Fundamentals](./fundamentals.md) page for a short introduction. While Giraffe aims to be intuitive for all users, web3 requires a shift in a mindset from what we're all used to.

## Quick Start

### Run
At the moment, there are no public testnets. That'll happen eventually. You can instead launch a local private testnet.
1. `docker run --rm -p 2024:2024 seancheatham/giraffe-node:latest`
1. Open the [wallet](http://localhost:2024) in your browser
1. Select the "Public" wallet (this is a shared wallet meant for testing purposes)
1. Select the "Stake" Tab. Click the little "warning" triangle to enter advanced mode. In the staker index dropdown, select `0`. Click "Start".

### SDK

The SDK is written in TypeScript and is published to NPM. Other languages will be supported in the future. Feel free to create a new Issue if you have a suggestion for the next language.

#### Install
<details>
  <summary>Click to Expand</summary>

  Install SDK module:
  ```sh
  npm install @giraffechain/giraffe-sdk
  ```
</details>

#### Initialize
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

  ##### Subsequent launches
  ```ts
  import * as g from "@giraffechain/giraffe-sdk";
  // Implement your own functionality to load the key you saved from the first launch
  const sk = loadKey();
  const giraffe = await g.Giraffe.init("http://localhost:2024", g.GiraffeWallet.fromSk(sk));
  ```
</details>

#### Send funds
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

#### Create graph data
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

#### Query graph data
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
