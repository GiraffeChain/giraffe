---
title: Faucet
description: Obtaining free testnet tokens
sidebar_position: 6
---

# Faucet

While Giraffe strives to be money-free, there still needs to be a currency in order for the protocol to function. Obtaining testnet tokens is generally done through a "faucet".

There are many approaches to faucet implementation, and most of them involve a centralized backend to keep track of deposits and impose rate limiting.

Giraffe is trying something different. Anyone with a GitHub account can use the faucet by following these steps:
1. Get your address
   - Open the [Giraffe Wallet](https://testnet.giraffechain.com) app
   - Create a new wallet
   - Copy your address
1. Click the ⭐ Star button on the [Giraffe repository](https://github.com/GiraffeChain/giraffe)
1. Create a new public [Gist](https://gist.github.com/)
   - **Gist description...**: Leave empty
   - **Filename including extension...**: `{address}.giraffe_faucet`
      - Don't include the curly braces `{}`
      - Example: `a_86eTia5YDjNxE6fc917aJB6VsttYzepbve8TJghkuZPE.giraffe_faucet`
   - **Contents**: Anything
   - [Example](https://gist.github.com/SeanCheatham/49930ef9c697ada824c89bf950507ccd)
1. Done! Periodically, the faucet will run in the background and deposit funds at your address.

## Implementation
Everything runs through GitHub.
- View the workflow status [here](https://github.com/GiraffeChain/giraffe/actions/workflows/faucet.yml).
- View the code [here](https://github.com/GiraffeChain/giraffe/tree/main/typescript/faucet).