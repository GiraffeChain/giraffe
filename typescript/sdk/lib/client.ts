import { BlockBody, BlockHeader, BlockId, FullBlock, LockAddress, Transaction, TransactionId, TransactionOutput, TransactionOutputReference } from "./models";
import Long from "long";

import { requireDefined } from "./utils";
import { showTransactionId } from "./codecs";

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
        const response = await fetch(`${this.baseAddress}/graph/${showTransactionId(edge.transactionId as TransactionId)}/${edge.index}/in-vertex`);
        if (!response.ok) {
            throw new Error(`Failed to get inVertex for edge: ${edge}`);
        }
        const references = await response.json();
        return references;
    }
    async getOutVertex(edge: TransactionOutputReference): Promise<TransactionOutputReference> {
        const response = await fetch(`${this.baseAddress}/graph/${showTransactionId(edge.transactionId as TransactionId)}/${edge.index}/out-vertex`);
        if (!response.ok) {
            throw new Error(`Failed to get inVertex for edge: ${edge}`);
        }
        const references = await response.json();
        return references;
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
        return response.json();
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
        return response.json();
    }
    async getHeaderOpt(id: BlockId): Promise<BlockHeader | undefined> {
        try {
            const response = await fetch(`${this.baseAddress}/block-headers/${id}`);
            if (!response.ok) {
                if (response.status === 404) {
                    return undefined;
                } else {
                    throw new Error(`Failed to get block header for id: ${id}`);
                }
            }
            const blockHeader = await response.json();
            return blockHeader;
        } catch (error) {
            console.error(`Error getting block header for id: ${id}`, error);
            return undefined;
        }
    }
    async getBodyOpt(id: BlockId): Promise<BlockBody | undefined> {
        try {
            const response = await fetch(`${this.baseAddress}/block-bodies/${id}`);
            if (!response.ok) {
                if (response.status === 404) {
                    return undefined;
                } else {
                    throw new Error(`Failed to get block body for id: ${id}`);
                }
            }
            const blockBody = await response.json();
            return blockBody;
        } catch (error) {
            console.error(`Error getting block body for id: ${id}`, error);
            return undefined;
        }
    }

    async getBlockOpt(id: BlockId): Promise<FullBlock | undefined> {
        try {
            const response = await fetch(`${this.baseAddress}/blocks/${id.value}`);
            if (!response.ok) {
                if (response.status === 404) {
                    return undefined;
                } else {
                    throw new Error(`Failed to get block for id: ${id.value}`);
                }
            }
            const fullBlock = await response.json();
            return fullBlock;
        } catch (error) {
            console.error(`Error getting block for id: ${id.value}`, error);
            return undefined;
        }
    }
    async getTransactionOpt(id: TransactionId): Promise<Transaction | undefined> {
        try {
            const response = await fetch(`${this.baseAddress}/transactions/${id.value}`);
            if (!response.ok) {
                if (response.status === 404) {
                    return undefined;
                } else {
                    throw new Error(`Failed to get transaction for id: ${id.value}`);
                }
            }
            const transaction = await response.json();
            return transaction;
        } catch (error) {
            console.error(`Error getting transaction for id: ${id.value}`, error);
            return undefined;
        }
    }

    async getTransactionOutputOpt(reference: TransactionOutputReference): Promise<TransactionOutput | undefined> {
        try {
            const response = await fetch(`${this.baseAddress}/transaction-outputs/${reference.transactionId?.value}/${reference.index}`);
            if (!response.ok) {
                if (response.status === 404) {
                    return undefined;
                } else {
                    throw new Error(`Failed to get transaction output for reference: ${reference}`);
                }
            }
            const transactionOutput = await response.json();
            return transactionOutput;
        } catch (error) {
            console.error(`Error getting transaction output for reference: ${reference}`, error);
            return undefined;
        }
    }

    async getBlockIdAtHeightOpt(height: Long): Promise<BlockId | undefined> {
        try {
            const response = await fetch(`${this.baseAddress}/block-ids/${height}`);
            if (!response.ok) {
                if (response.status === 404) {
                    return undefined;
                } else {
                    throw new Error(`Failed to get block id for height: ${height}`);
                }
            }
            return { value: (await response.json())["blockId"] as string };
        } catch (error) {
            console.error(`Error getting block id for height: ${height}`, error);
            return undefined;
        }
    }

    async getLockAddressState(address: LockAddress): Promise<TransactionOutputReference[]> {
        try {
            const response = await fetch(`${this.baseAddress}/address-states/${address.value}`);
            if (!response.ok) {
                throw new Error(`Failed to get lock address state for address: ${address.value}`);
            }
            const state = await response.json();
            return state;
        } catch (error) {
            console.error(`Error getting lock address state for address: ${address}`, error);
            return [];
        }
    }

    async broadcastTransaction(transaction: Transaction): Promise<void> {
        try {
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
        } catch (error) {
            console.error(`Error broadcasting transaction: ${transaction}`, error);
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
            if (change["applied"] !== undefined) {
                yield { type: TipChangeType.APPLIED, blockId: change["applied"] };
            } else if (change["unapplied"] !== undefined) {
                yield { type: TipChangeType.UNAPPLIED, blockId: change["unapplied"] };
            }
        }
    }
    async getEdges(vertex: TransactionOutputReference): Promise<TransactionOutputReference[]> {
        try {
            const response = await fetch(`${this.baseAddress}/graph/${vertex.transactionId?.value}/${vertex.index}/edges`);
            if (!response.ok) {
                throw new Error(`Failed to get edges for vertex: ${vertex}`);
            }
            const references = await response.json();
            return references;
        } catch (error) {
            console.error(`Error getting edges for vertex: ${vertex}`, error);
            return [];
        }
    }
    async getInEdges(vertex: TransactionOutputReference): Promise<TransactionOutputReference[]> {
        try {
            const response = await fetch(`${this.baseAddress}/graph/${vertex.transactionId?.value}/${vertex.index}/in-edges`);
            if (!response.ok) {
                throw new Error(`Failed to get inEdges for vertex: ${vertex}`);
            }
            const references = await response.json();
            return references;
        } catch (error) {
            console.error(`Error getting inEdges for vertex: ${vertex}`, error);
            return [];
        }
    }
    async getOutEdges(vertex: TransactionOutputReference): Promise<TransactionOutputReference[]> {
        try {
            const response = await fetch(`${this.baseAddress}/graph/${vertex.transactionId?.value}/${vertex.index}/out-edges`);
            if (!response.ok) {
                throw new Error(`Failed to get outEdges for vertex: ${vertex}`);
            }
            const references = await response.json();
            return references;
        } catch (error) {
            console.error(`Error getting outEdges for vertex: ${vertex}`, error);
            return [];
        }
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
