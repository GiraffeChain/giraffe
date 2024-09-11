---
description: Information about the data types used in Giraffe Chain.
sidebar_position: 5
---

# Data Models
Giraffe Chain's models and data types are primarily defined using Protobuf and then compiled into target languages. These definitions are located [here](https://github.com/SeanCheatham/giraffe/blob/main/proto/models/core.proto).

While not a comprehensive list, here is a general summary:

## Transaction
Represents a change to the ledger - the spending of inputs and creation of outputs.
- **inputs**: A list of things being spent
- **outputs**: A list of things being created
- **attestation**: Provides authorization that the inputs can be spent
- **rewardParentBlockId**: Only provided by block producers, this is the ID of the block that came before the one being created

## TransactionInput
Spends a TransactionOutput.
- **reference**: The reference to the UTxO to spend
- **value**: A copy of the "value" of the UTxO to spend

## TransactionOutput
An entry in the blockchain ledger.
- **lockAddress**: The hash of a lock that secures this output
- **value**: Contains the quantity, account, and graph information
- **account**: A reference to a UTxO containing an account registration. When provided, funds will be added to the staking account.

## Witness
Provides authorization proof to spend a UTxO.
- **lockAddress**: A hash of the lock
- **lock**: The full set of constraints that need to be satisfied. Should correspond to the "lockAddress" property.
- **key**: Satisfies the constraints of the lock.

## Value
The contents of a Transaction Output.
- **quantity**: The number of tokens
- **accountRegistration**: An optional registration for a new staking account
- **graphEntry**: An optional record in the graph database

## Graph Entry
One of:
- **vertex**: An entity
- **edge**: A relationship between two vertices

## Vertex
An entity or data object of a graph database
- **label**: A class or group name
- **data**: A JSON object
- **edgeLockAddress**: A constraint that must be satisfied in order to connect to this vertex

## Edge
A connection or relationship between two vertices
- **label**: A class or group name
- **data**: A JSON object
- **a**: A reference to a vertex output
- **b**: A reference to a vertex output

## Block Header
Holds metadata about a block, primarily for the purposes of consensus.
- **parentHeaderId**: The ID of the block that came before this one. This field is what makes a blockchain a "chain"
- **parentSlot**: The "slot" of the block that came before this one.
- **txRoot**: A commitment to the Block Body
- **timestamp**: The UTC UNIX timestamp at which the block was created
- **height**: The 1-based index of the block within the chain
- **slot**: The window of time in which the block was created.
- **stakerCertificate**: A certificate containing proof-of-eligibility as well as a signature of the block
- **account**: A reference to a UTxO containing an account registration
- **settings**: A key-value map of changes to the protocol

## Block Body
Holds just the transaction IDs of a block.
- **transactionIds**: The IDs of the transactions included in a block.


## Full Block Body
Holds the full transaction data of a block.
- **transactions**: The transactions included in a block.

## Block
Holds the header and body of a block.
- **header**: The Block Header of the block
- **body**: The block body of the block

## Full Block
Holds the header and full body of a block.
- **header**: The Block Header of the block
- **fullBody**: The full block body of the block

