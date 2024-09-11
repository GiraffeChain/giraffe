import { BlockBody, BlockHeader, BlockId, FullBlock, LockAddress, Transaction, TransactionConfirmation, TransactionId, TransactionOutput, TransactionOutputReference } from "./models";
import Long from "long";

import { requireDefined } from "./utils";
import { decodeBlockId, showBlockId, showLockAddress, showTransactionId, showTransactionOutputReference } from "./codecs";

/**
 * Represents a client for interacting with the Giraffe blockchain. Blockchain and graph data can be queried using this client. Transactions can also be broadcasted.
 */
export abstract class GiraffeClient {
    /**
     * Retrieve a block header by its ID, if it exists.
     * @param id - The Block ID
     * @returns A Promise that resolves to the BlockHeader, or undefined if the block does not exist.
     */
    abstract getHeaderOpt(id: BlockId): Promise<BlockHeader | undefined>;
    /**
     * Retrieve a block body by its ID, if it exists.
     * @param id - The Block ID
     * @returns A Promise that resolves to the BlockBody, or undefined if the block does not exist.
     */
    abstract getBodyOpt(id: BlockId): Promise<BlockBody | undefined>;
    /**
     * Retrieve a full block by its ID, if it exists.
     * @param id - The Block ID
     * @returns A Promise that resolves to the FullBlock, or undefined if the block does not exist.
     */
    abstract getBlockOpt(id: BlockId): Promise<FullBlock | undefined>;
    /**
     * Retrieve a transaction by its ID, if it exists.
     * @param id - The Transaction ID
     * @returns A Promise that resolves to the Transaction, or undefined if the block does not exist.
     */
    abstract getTransactionOpt(id: TransactionId): Promise<Transaction | undefined>;

    /**
     * Retrieve a transaction output by its reference, if it exists.
     * @param reference - The TransactionOutputReference
     * @returns A Promise that resolves to the TransactionOutput, or undefined if the output does not exist.
     */
    abstract getTransactionOutputOpt(reference: TransactionOutputReference): Promise<TransactionOutput | undefined>;

    /**
     * Retrieve a transaction confirmation by its ID, if it exists.
     * @param id - The Transaction ID
     * @returns A Promise that resolves to the TransactionConfirmation, or undefined if the confirmation does not exist.
     */
    abstract getTransactionConfirmationOpt(id: TransactionId): Promise<TransactionConfirmation | undefined>;

    /**
     * Retrieve the Block ID at a given height, if it exists.
     * @param height - The height of the block. If `0` is provided, the current chain tip is provided. If a negative value is provided, the block is retrieved by depth.
     * @returns A Promise that resolves to the Block ID, or undefined if the chain hasn't reached the target height.
     */
    abstract getBlockIdAtHeightOpt(height: Long): Promise<BlockId | undefined>;
    /**
     * Get the Transaction Output References that are currently spendable by the given lock address
     * @param address - The Lock Address
     * @returns A Promise that resolves to the Transaction Output References that are currently spendable by the given lock address
     */
    abstract getLockAddressState(address: LockAddress): Promise<TransactionOutputReference[]>;
    /**
     * Broadcast a transaction to the network.
     * @param transaction - The transaction to broadcast.
     * @returns A Promise that resolves when the transaction has been broadcast. The transaction is not immediately included in the chain.
     */
    abstract broadcastTransaction(transaction: Transaction): Promise<void>;
    /**
     * Follow the chain and receive updates when the chain tip changes.
     * @returns An AsyncGenerator that yields TipChange objects.
     */
    abstract follow(): AsyncGenerator<TipChange, any, void>;
    /**
     * Retrieve all edges of a vertex.
     * @param vertex - The vertex to retrieve the edges for.
     * @returns A Promise that resolves to the TransactionOutputReferences of the associated edges.
     */
    abstract getEdges(vertex: TransactionOutputReference): Promise<TransactionOutputReference[]>;
    /**
     * Retrieve incoming edges of a vertex.
     * @param vertex - The vertex to retrieve the incoming edges for.
     * @returns A Promise that resolves to the TransactionOutputReferences of the associated incoming edges.
     */
    abstract getInEdges(vertex: TransactionOutputReference): Promise<TransactionOutputReference[]>;
    /**
     * Retrieve outgoing edges of a vertex.
     * @param vertex - The vertex to retrieve the outgoing edges for.
     * @returns A Promise that resolves to the TransactionOutputReferences of the associated outgoing edges.
     */
    abstract getOutEdges(vertex: TransactionOutputReference): Promise<TransactionOutputReference[]>;
    /**
     * Retrieve the reference to the vertex contained at the given edge's `a`.
     * @param vertex - The reference to the edge containing `a`.
     * @returns A Promise that resolves to the TransactionOutputReference `a` edge.
     */
    abstract getInVertex(edge: TransactionOutputReference): Promise<TransactionOutputReference>;
    /**
     * Retrieve the reference to the vertex contained at the given edge's `b`.
     * @param vertex - The reference to the edge containing `b`.
     * @returns A Promise that resolves to the TransactionOutputReference `b` edge.
     */
    abstract getOutVertex(edge: TransactionOutputReference): Promise<TransactionOutputReference>;
    /**
     * Query vertices in the graph.
     * @param label - The label of the vertices to query.
     * @param where - The conditions to filter the vertices by.
     * @returns A Promise that resolves to the TransactionOutputReferences of the vertices that match the query.
     */
    abstract queryVertices(label: String, where: [string, string, any][]): Promise<TransactionOutputReference[]>;
    /**
     * Query edges in the graph.
     * @param label - The label of the edges to query.
     * @param a - The reference to the `a`/source/in vertex.
     * @param a - The reference to the `b`/destination/out vertex.
     * @param where - The conditions to filter the edges by.
     * @returns A Promise that resolves to the TransactionOutputReferences of the edges that match the query.
     */
    abstract queryEdges(label: String, a: TransactionOutputReference | undefined, b: TransactionOutputReference | undefined, where: [string, string, any][]): Promise<TransactionOutputReference[]>;

    /**
     * Retrieves the header of a block with the specified ID.
     * 
     * @param id - The ID of the block.
     * @returns A promise that resolves to the block header.
     * @throws An error if the block does not exist.
     */
    async getHeader(id: BlockId): Promise<BlockHeader> {
        const t = await this.getHeaderOpt(id);
        return requireDefined(t);
    }
    /**
     * Retrieves the body of a block with the specified ID.
     * 
     * @param id - The ID of the block.
     * @returns A promise that resolves to the block body.
     * @throws An error if the block does not exist.
     */
    async getBody(id: BlockId): Promise<BlockBody> {
        const t = await this.getBodyOpt(id);
        return requireDefined(t);
    }
    /**
     * Retrieves a full block with the specified ID.
     * 
     * @param id - The ID of the block.
     * @returns A promise that resolves to the full block.
     * @throws An error if the block does not exist.
     */
    async getBlock(id: BlockId): Promise<FullBlock> {
        const t = await this.getBlockOpt(id);
        return requireDefined(t);
    }
    /**
     * Retrieves a transaction with the specified ID.
     * 
     * @param id - The ID of the transaction.
     * @returns A promise that resolves to the transaction.
     * @throws An error if the transaction does not exist.
     */
    async getTransaction(id: TransactionId): Promise<Transaction> {
        const t = await this.getTransactionOpt(id);
        return requireDefined(t);
    }
    /**
     * Retrieves a transaction output with the specified reference.
     * 
     * @param reference - The reference of the transaction output.
     * @returns A promise that resolves to the transaction output.
     * @throws An error if the transaction output does not exist.
     */
    async getTransactionOutput(reference: TransactionOutputReference): Promise<TransactionOutput> {
        const t = await this.getTransactionOutputOpt(reference);
        return requireDefined(t);
    }
    /**
     * Retrieves the block ID at the specified height.
     * 
     * @param height - The height of the block.
     * @returns A promise that resolves to the block ID.
     * @throws An error if the block does not exist.
     */
    async getBlockIdAtHeight(height: Long): Promise<BlockId> {
        const t = await this.getBlockIdAtHeightOpt(height);
        return requireDefined(t);
    }
    /**
     * Retrieves the canonical head block ID.
     * @returns A promise that resolves to the canonical head block ID.
     */
    getCanonicalHeadId(): Promise<BlockId> {
        return this.getBlockIdAtHeight(Long.ZERO);
    }
    /**
     * Retrieves the genesis block ID.
     * @returns A promise that resolves to the genesis block ID.
     */
    getGenesisId(): Promise<BlockId> {
        return this.getBlockIdAtHeight(Long.ONE);
    }

    async nextBlockId(): Promise<BlockId> {
        for await (const t of this.follow()) {
            if (t.type === TipChangeType.APPLIED) {
                return t.blockId;
            }
        }
        throw new Error("Failed to get next block id");
    }
}

/**
 * Represents a change to the canonical head of the blockchain.
 */
export interface TipChange {
    type: TipChangeType;
    blockId: BlockId;
}

export enum TipChangeType {
    APPLIED,
    UNAPPLIED
}

export class RpcGiraffeClient extends GiraffeClient {
    async getInVertex(edge: TransactionOutputReference): Promise<TransactionOutputReference> {
        const response = await fetch(`${this.baseAddress}/graph/${showTransactionId(edge.transactionId!)}/${edge.index}/in-vertex`);
        if (!response.ok) {
            throw new Error(`Failed to get inVertex for edge: ${edge}`);
        }
        return TransactionOutputReference.fromJSON(await response.json());
    }
    async getOutVertex(edge: TransactionOutputReference): Promise<TransactionOutputReference> {
        const response = await fetch(`${this.baseAddress}/graph/${showTransactionId(edge.transactionId!)}/${edge.index}/out-vertex`);
        if (!response.ok) {
            throw new Error(`Failed to get inVertex for edge: ${edge}`);
        }
        return TransactionOutputReference.fromJSON(await response.json());
    }
    async queryVertices(label: String, where: [string, string, any][]): Promise<TransactionOutputReference[]> {
        const body = {
            "label": label,
            "where": where
        };

        const response = await fetch(`${this.baseAddress}/graph/query-vertices`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(body)
        });
        if (!response.ok) {
            throw new Error(`Failed to query vertices for label: ${label}`);
        }
        const arr = await response.json();
        return arr.map(TransactionOutputReference.fromJSON);
    }
    async queryEdges(label: String, a: TransactionOutputReference | undefined, b: TransactionOutputReference | undefined, where: [string, string, any][]): Promise<TransactionOutputReference[]> {
        let body = {
            "label": label,
            "where": where
        };
        if (a !== undefined) {
            body["a"] = a;
        }
        if (b !== undefined) {
            body["b"] = b;
        }

        const response = await fetch(`${this.baseAddress}/graph/query-edges`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(body)
        });
        if (!response.ok) {
            throw new Error(`Failed to query vertices for label: ${label}`);
        }
        const arr = await response.json();
        return arr.map(TransactionOutputReference.fromJSON);
    }
    async getHeaderOpt(id: BlockId): Promise<BlockHeader | undefined> {
        const response = await fetch(`${this.baseAddress}/block-headers/${showBlockId(id)}`);
        if (!response.ok) {
            if (response.status === 404) {
                return undefined;
            } else {
                throw new Error(`Failed to get block header for id: ${showBlockId(id)}`);
            }
        }
        return BlockHeader.fromJSON(await response.json());
    }
    async getBodyOpt(id: BlockId): Promise<BlockBody | undefined> {
        const response = await fetch(`${this.baseAddress}/block-bodies/${showBlockId(id)}`);
        if (!response.ok) {
            if (response.status === 404) {
                return undefined;
            } else {
                throw new Error(`Failed to get block body for id: ${id}`);
            }
        }
        return BlockBody.fromJSON(await response.json());
    }

    async getBlockOpt(id: BlockId): Promise<FullBlock | undefined> {
        const response = await fetch(`${this.baseAddress}/blocks/${showBlockId(id)}`);
        if (!response.ok) {
            if (response.status === 404) {
                return undefined;
            } else {
                throw new Error(`Failed to get block for id: ${showBlockId(id)}`);
            }
        }
        return FullBlock.fromJSON(await response.json());
    }
    async getTransactionOpt(id: TransactionId): Promise<Transaction | undefined> {
        const response = await fetch(`${this.baseAddress}/transactions/${showTransactionId(id)}`);
        if (!response.ok) {
            if (response.status === 404) {
                return undefined;
            } else {
                throw new Error(`Failed to get transaction for id: ${showTransactionId(id)}`);
            }
        }
        return Transaction.fromJSON(await response.json());
    }

    async getTransactionOutputOpt(reference: TransactionOutputReference): Promise<TransactionOutput | undefined> {
        const response = await fetch(`${this.baseAddress}/transaction-outputs/${showTransactionId(reference.transactionId!)}/${reference.index}`);
        if (!response.ok) {
            if (response.status === 404) {
                return undefined;
            } else {
                throw new Error(`Failed to get transaction output for reference: ${showTransactionOutputReference(reference)}`);
            }
        }
        return TransactionOutput.fromJSON(await response.json());
    }

    async getTransactionConfirmationOpt(id: TransactionId): Promise<TransactionConfirmation | undefined> {
        const response = await fetch(`${this.baseAddress}/transactions/${showTransactionId(id)}/confirmation`);
        if (!response.ok) {
            if (response.status === 404) {
                return undefined;
            } else {
                throw new Error(`Failed to get transaction confirmation for id: ${showTransactionId(id)}`);
            }
        }
        return TransactionConfirmation.fromJSON(await response.json());
    }

    async getBlockIdAtHeightOpt(height: Long): Promise<BlockId | undefined> {
        const response = await fetch(`${this.baseAddress}/block-ids/${height}`);
        if (!response.ok) {
            if (response.status === 404) {
                return undefined;
            } else {
                throw new Error(`Failed to get block id for height: ${height}`);
            }
        }
        return decodeBlockId((await response.json())["blockId"]);
    }

    async getLockAddressState(address: LockAddress): Promise<TransactionOutputReference[]> {
        const response = await fetch(`${this.baseAddress}/address-states/${showLockAddress(address)}`);
        if (!response.ok) {
            throw new Error(`Failed to get lock address state for address: ${showLockAddress(address)}`);
        }
        const arr = await response.json();
        return arr.map(TransactionOutputReference.fromJSON);
    }

    async broadcastTransaction(transaction: Transaction): Promise<void> {
        const response = await fetch(`${this.baseAddress}/transactions`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(Transaction.toJSON(transaction))
        });
        if (!response.ok) {
            throw new Error(`Failed to broadcast transaction: ${transaction}`);
        }
    }

    async *follow(): AsyncGenerator<TipChange, any, void> {
        const response = await fetch(`${this.baseAddress}/follow`, {
            method: "GET",
            headers: {
                "Content-Type": "application/json"
            },
        });
        if (!response.ok) {
            throw new Error(`Failed to follow chain`);
        }
        const stream = response.body;
        if (!stream) throw Error("Null follow stream");
        for await (const change of jsonLineStream(stream)) {
            if (change["adopted"] !== undefined) {
                yield { type: TipChangeType.APPLIED, blockId: change["adopted"] };
            } else if (change["unadopted"] !== undefined) {
                yield { type: TipChangeType.UNAPPLIED, blockId: change["unadopted"] };
            } else {
                throw Error("Unexpected tip change");
            }
        }
    }
    async getEdges(vertex: TransactionOutputReference): Promise<TransactionOutputReference[]> {
        const response = await fetch(`${this.baseAddress}/graph/${vertex.transactionId?.value}/${vertex.index}/edges`);
        if (!response.ok) {
            throw new Error(`Failed to get edges for vertex: ${vertex}`);
        }
        const arr = await response.json();
        return arr.map(TransactionOutputReference.fromJSON);
    }
    async getInEdges(vertex: TransactionOutputReference): Promise<TransactionOutputReference[]> {
        const response = await fetch(`${this.baseAddress}/graph/${vertex.transactionId?.value}/${vertex.index}/in-edges`);
        if (!response.ok) {
            throw new Error(`Failed to get inEdges for vertex: ${vertex}`);
        }
        const arr = await response.json();
        return arr.map(TransactionOutputReference.fromJSON);
    }
    async getOutEdges(vertex: TransactionOutputReference): Promise<TransactionOutputReference[]> {
        const response = await fetch(`${this.baseAddress}/graph/${vertex.transactionId?.value}/${vertex.index}/out-edges`);
        if (!response.ok) {
            throw new Error(`Failed to get outEdges for vertex: ${vertex}`);
        }
        const arr = await response.json();
        return arr.map(TransactionOutputReference.fromJSON);
    }

    private baseAddress: String;
    constructor(baseAddress: String) {
        super();
        this.baseAddress = baseAddress;
    }

}

/// https://github.com/pamelafox/ndjson-readablestream/blob/main/index.mjs
async function* jsonLineStream(readableStream: ReadableStream<Uint8Array>) {
    const reader = readableStream.getReader();
    let runningText = '';
    let decoder = new TextDecoder('utf-8');
    while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        var text = decoder.decode(value, { stream: true });
        const objects = text.split('\n');
        for (const obj of objects) {
            try {
                runningText += obj;
                let result = JSON.parse(runningText);
                yield result;
                runningText = '';
            } catch (e) { }
        }
    }
}
