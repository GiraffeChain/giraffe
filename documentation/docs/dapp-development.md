---
title: dApp Development
description: Information about developing and testing dApps (decentralized applications).
sidebar_position: 3
---

# dApp Development
When developing decentralized applications, it often helps to test against private local testnets that can be created and destroyed as needed.

## Launch Private Testnet
1. `docker run --rm -p 2024:2024 seancheatham/giraffe-node:dev`
1. Take note of a line near the top of the logs that looks like this: `INFO  Testnet - Testnet Staker 0: A498AybCn9K9Btmar1tKnyR8...`
  Copy the long string of text after the `: `.
1. Open the [wallet](http://localhost:2024) in your browser
1. Select the "Public" wallet (this is a shared wallet meant for testing purposes)
1. Select the "Stake" Button. Click the little "warning" triangle to enter advanced mode. Paste the string from the previous text into the `Import` input. Click `Import`.
1. Click "Start".

Blocks should be produced automatically in the background. You can now use normal Wallet and/or SDK functionality.

## Development
To create a decentralized application, you can use the [TypeScript SDK](./sdk). Using a funded wallet, you can add new data to the ledger-wide graph. If you can model your application or idea using objects and relations, you can probably store it on the Giraffe Chain!