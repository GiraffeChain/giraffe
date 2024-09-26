# 🦒 Giraffe Chain 
**⛓ Blockchain** | **📱 Mobile+Web Staking** | **🖫 Graph Database** | **🧪 Experimental**

### [🏠 Home](https://giraffechain.com)
### [📖 Documentation](https://docs.giraffechain.com)
### [🖥️ Testnet](https://testnet.giraffechain.com)

## About
You've found the repository for yet another blockchain protocol. This protocol uses proof-of-stake for consensus and UTxOs for its ledger.

Similar to other application layers, tokens are distributed and spent using an "Unspent Transaction Output" model. *Unlike* other UTxO models, each UTxO may represent a "vertex" or "edge" of a **ledger-wide graph data structure**. Connecting two "vertex" UTxOs with a new "edge" UTxO requires permission from each of the "vertex" UTxOs. The intention is to provide a developer-friendly graph database that is backed by a decentralized blockchain.

Similar to other protocols, the network is made up of relay nodes which verify correctness of the chain and distribute information to other peers. *Unlike* other protocols, **block production is performed client-side within user wallets**. The intention is to decentralize as much as possible by making it simple for everyday people to stake. The ideal outcome is for millions of people to participate from their phones.

To demonstrate the utility of the graph database, the wallet includes a mini **social network** which allows people to share and connect.

The whole thing is included here, in a monorepo.

## Status
This blockchain is still in very **early development**. Everything is **experimental**. You are more than welcome to copy the code in this repository, but there are no guarantees that it'll be bug-free. **Don't use real money** (as if such a thing exists). If nothing else, this project aims to experiment with web3 ideas.

## Limitations
- Staking currently requires significant trust in the connected relay node.
- To limit an explosion of storage, graph data is encumbered by tokens/funds. There is a limit on the vertex/edge information that can be stored.
