import { BlockBody, BlockHeader, BlockId, FullBlock, LockAddress, Transaction, TransactionId, TransactionOutput, TransactionOutputReference } from "./models";
import Long from "long";

import { requireDefined } from "./utils";
import { decodeBlockId, showBlockId, showLockAddress, showTransactionId, showTransactionOutputReference } from "./codecs";

export abstract class GiraffeClient {
    abstract getHeaderOpt(id: BlockId): Promise<BlockHeader | undefined>;
    abstract getBodyOpt(id: BlockId): Promise<BlockBody | undefined>;
    abstract getBlockOpt(id: BlockId): Promise<FullBlock | undefined>;
    abstract getTransactionOpt(id: TransactionId): Promise<Transaction | undefined>;
    abstract getTransactionOutputOpt(reference: TransactionOutputReference): Promise<TransactionOutput | undefined>;
    abstract getBlockIdAtHeightOpt(height: Long): Promise<BlockId | undefined>;
    abstract getLockAddressState(address: LockAddress): Promise<TransactionOutputReference[]>;
    abstract broadcastTransaction(transaction: Transaction): Promise<void>;
    abstract follow(): AsyncGenerator<TipChange, any, void>;
    abstract getEdges(vertex: TransactionOutputReference): Promise<TransactionOutputReference[]>;
    abstract getInEdges(vertex: TransactionOutputReference): Promise<TransactionOutputReference[]>;
    abstract getOutEdges(vertex: TransactionOutputReference): Promise<TransactionOutputReference[]>;
    abstract getInVertex(edge: TransactionOutputReference): Promise<TransactionOutputReference>;
    abstract getOutVertex(edge: TransactionOutputReference): Promise<TransactionOutputReference>;
    abstract queryVertices(label: String, where: [string, string, any][]): Promise<TransactionOutputReference[]>;
    abstract queryEdges(label: String, a: TransactionOutputReference | undefined, b: TransactionOutputReference | undefined, where: [string, string, any][]): Promise<TransactionOutputReference[]>;

    getHeader(id: BlockId): Promise<BlockHeader> {
        return this.getHeaderOpt(id).then(requireDefined);
    }
    getBody(id: BlockId): Promise<BlockBody> {
        return this.getBodyOpt(id).then(requireDefined);
    }
    getBlock(id: BlockId): Promise<FullBlock> {
        return this.getBlockOpt(id).then(requireDefined)
    }
    getTransaction(id: TransactionId): Promise<Transaction> {
        return this.getTransactionOpt(id).then(requireDefined)
    }
    getTransactionOutput(reference: TransactionOutputReference): Promise<TransactionOutput> {
        return this.getTransactionOutputOpt(reference).then(requireDefined)
    }
    getBlockIdAtHeight(height: Long): Promise<BlockId> {
        return this.getBlockIdAtHeightOpt(height).then(requireDefined);
    }
    getCanonicalHeadId(): Promise<BlockId> {
        return this.getBlockIdAtHeight(Long.ZERO);
    }
    getGenesisId(): Promise<BlockId> {
        return this.getBlockIdAtHeight(Long.ONE);
    }
}

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
