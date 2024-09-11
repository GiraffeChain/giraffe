---
title: Testnets
description: Information about the Giraffe Chain public testnets.
sidebar_position: 5
---

# Testnets

The "current" testnet is located here: https://testnet.giraffechain.com

Running block production on phones is a rather amibitious goal. I'm not entirely sure if it'll work in the real world. To find out, I need your help.

Running a global/public graph database on top of a blockchain is also a rather ambitious goal. I need your help to push its use-cases.

Because this chain is still in development, it is extremely likely that a public testnet will need to be reset in order to implement backwards-incompatible changes.

My goal is to make it as easy as possible to _use_ the testnets. At the moment, I simply fund the public wallet and invite you to transfer _some_ tokens from it as needed. That will most likely be abused at some point, so I'll come up with a different faucet approach soon.

The 0th testnet has already been wiped, Giraffe is now on the 1st testnet.

## Testnet 1
Open the [Wallet/App](https://testnet.giraffechain.com) to see the current state of the chain, access your funds, stake, and more.

If you want to help with relay operations, you can do so using Docker.
1. `docker volume create giraffe`
1. `docker run -d --name giraffe --restart=always -p 2023:2023 -p 2024:2024 -v giraffe:/giraffe giraffechain/node:dev --genesis https://github.com/SeanCheatham/blockchain/raw/genesis/b_9JabitnBvokxRXfsoCGMrahsub3FpTCwKsUXY9XHW22M.pbuf --peer testnet.giraffechain.com:2023`
    - Note: If you are able to open your firewall for public access on port 2023, you can add the `--p2p-public-host auto` argument
