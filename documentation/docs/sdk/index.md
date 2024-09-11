---
description: Information about the Giraffe Chain SDK
slug: /sdk
sidebar_position: 4
---

# Software Development Kit (SDK)
The Giraffe SDK provides programmatic access to Giraffe Chain data. At this time, the SDK is offered in TypeScript, although more languages will be supported in the future.

## Install
  Install SDK module:
  ```sh
  npm install @giraffechain/giraffe-sdk
  ```

## Initialize
  ### First launch
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

  ### Subsequent launches
  ```ts
  import * as g from "@giraffechain/giraffe-sdk";
  // Implement your own functionality to load the key you saved from the first launch
  const sk = loadKey();
  const giraffe = await g.Giraffe.init("http://localhost:2024", g.GiraffeWallet.fromSk(sk));
  ```

## Send funds

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

## Create graph data

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

## Query graph data

  ```ts
  const vertexIds = await giraffe.client.queryVertices("profile", [["firstName", "==", "Alan"]]);
  for(const vertexId of vertexIds) {
    const output = await giraffe.client.getTransactionOutput(vertexId);
    const vertex = output.value?.graphEntry?.vertex!;
    const lastName = vertex.data["lastName"];
  }
  ```
