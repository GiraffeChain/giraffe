---
title: Limitations
description: Known limitations of the Giraffe Chain ecosystem
sidebar_position: 9
---

# Limitations
Giraffe Chain is **very** far from perfect. For transparency, here are some of the bigger limitations right now.

## Unorthodox
Right from the get-go, it's important to understand that this chain strives to be anything but typical. There are literally thousands of blockchains out there, and only a handful of them do something truly novel. The limitation is that this chain will buck certain standards and trends that have been embraced by the web3 ecosystem.

## Testing
This chain is not well tested. It has a few unit tests in its cryptography and codec compatibility, but beyond that, most testing is manual. Generally, this isn't a recommended engineering practice. My excuse: This chain is experimental and is meant to rapidly change. Formal testing acts as cement, which is great for strength and resiliency, but it's not-so-great if you're still laying rebar.

## Scripts / "Smart"Contracts / Locks
Right now, there is exactly one way to lock up a token: An Ed25519 signing routine. There is no special contract language; no special DSL; no thresholds; no height locks.

That can all be implemented. It's territory I'd very much like to explore with this chain soon, because there is a ton of creativity involved. But it's also extremely important to get the experience right. That's why it's primitive right now.

## Staking and Relay Trust
Staking is intended to happen remotely from a client device, like a phone or browser. I want Giraffe Chain to be as mobile-friendly as possible, and I'm working on improving the capabilities of clients and frontends. In particular, I don't want "clients" and "servers" to be a thing. But right now, staking and block production rely heavily on trusting a relay node. This poses security concerns if someone runs a malicious relay node that lies about data on the chain. Over time, I will incorporate more and more chain validation into the frontends.

## Transaction Throughput
I don't know what the maximum transactions-per-second of the chain is. (Frankly, that's a poor metric for comparing blockchains anyway.) With that said, there's absolutely no way this chain can support the same transaction throughput as a chain that is meant to run on servers with virtually infinite resources. The goal is to run as much as possible on a normal, everyday phone. It's actually quite impressive what these little rectangles can do, but they're still miles away from the capabilities of a server.

## P2P Security
Running anything that's publicly accessible is a scary and daunting task. It's especially scary if you're running a system that is responsible for securing other people's money or data. Giraffe's P2P system is generally quite performant, and it'll reject any data that is invalid. It has mechanisms in place that will help things perform better as the peer graph grows.

But it also has security concerns:
- Data is not garbage collected. A malicious peer could feed long segments of valid but non-canonical chain data that would be saved under certain circumstances but never removed.
- A malicious peer could request massive amounts of data and provide nothing in return. (i.e. bootstrap, erase, repeat)

## Code Quality/Standards
I am a Scala developer and have lived in the backend for my entire career. The frontend and UI will not be as polished as you might hope. The Dart and TypeScript code may not use standards that you're used to. If someone else is able to improve any of it, I'd be thrilled! In the meantime, it-is-what-it-is.