
## Approach

### Idea 1
The Blockchain is a choose-your-adventure book, written by members of the community.  It employs a "Proof-of-Human" consensus approach where block production, block validation, and chain selection are interactive and subjective.  Most of the underlying systems are still automated, but consensus is derived through creativity.  Everyone is welcome to participate at any moment, with no registration required.

The blockchain begins with a "genesis" block.  This block contains an open-ended story prompt.  Each subsequent block adds a small continuation to the story, written by a human.  Humans interactively select the most human-sounding continuations to the story.

### Idea 2

Proof-of-Human using a "credibility" system.  Users send other users "credibility" tokens.


### Idea 3

Application is split into three:
- P2P Service
  An application-agnostic service which acts as a reverse-proxy.  Running a P2P network on mobile networks (3G/4G/5G) isn't generally possible because carriers block inbound connections.  A P2P Service could instead run in the cloud (or on a home network with proper NAT) and accept inbound connections on behalf of a mobile phone.  All traffic would be forwarded.  This service could be encrypted and incentivized to allow users to share their strong network connections with other users.
- Storage Service
  An application-agnostic database and filesystem that allows a user to offload data storage to a remote destination.  This enables servers without local filesystems (i.e. "serving" from a web browser).
- Blockchain
  Acts as a node in a blockchain network.  Produces blocks, validates blocks/transactions, and performs consensus.  By leveraging the P2P Service and Storage Service, the blockchain itself (and all staking operations) can run on a user's local machine, even in a web browser.

All three pieces would be written in Dart/Flutter, and all three could be run in one application for users on desktop with public network connections.  The separation of the three simply enables non-desktop users to run virtually the same application.