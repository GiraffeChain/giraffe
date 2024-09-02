import { GiraffeWallet } from "./wallet";
import { GiraffeClient } from "./client";
import { TransactionOutput, TransactionOutputReference } from "./models";

/**
 * Provides functionality for interacting with the Giraffe graph using the local wallet.
 */
export class GiraffeGraph {
    wallet: GiraffeWallet;
    client: GiraffeClient;
    /**
     * Constructs a new instance of the `Graph` class.
     * 
     * @param wallet - The GiraffeWallet instance.
     * @param client - The GiraffeClient instance.
     */
    constructor(wallet: GiraffeWallet, client: GiraffeClient) {
        this.wallet = wallet;
        this.client = client;
    }

    /**
     * Creates a vertex output for a transaction.
     * 
     * @param label - The label of the vertex.
     * @param data - The data associated with the vertex.
     * @returns The transaction output containing the vertex.
     */
    createVertexOutput(label: string, data: { [key: string]: any } | undefined): TransactionOutput {
        return TransactionOutput.fromJSON({
            lockAddress: this.wallet.address,
            value: {
                graphEntry: {
                    vertex: {
                        label: label,
                        data: data
                    }
                },
            },
        });
    }

    /**
     * Creates a transaction output representing an edge in a graph.
     * 
     * @param label - The label of the edge.
     * @param a - The reference "source" vertex.
     * @param b - The reference "destination" vertex.
     * @param data - Additional data associated with the edge.
     * @returns The created transaction output.
     */
    createEdgeOutput(label: string, a: TransactionOutputReference, b: TransactionOutputReference, data: { [key: string]: any } | undefined): TransactionOutput {
        return TransactionOutput.fromJSON({
            lockAddress: this.wallet.address,
            value: {
                graphEntry: {
                    edge: {
                        label: label,
                        data: data,
                        a: a,
                        b: b
                    }
                },
            },
        });
    }

    /**
     * Retrieves the local vertices from the wallet's spendable outputs.
     * 
     * @returns An array of TransactionOutputReference representing the local vertices.
     */
    localVertices(): TransactionOutputReference[] {
        return this.wallet.spendableOutputs.filter(([_, output]) => output.value?.graphEntry?.vertex !== undefined).map(([ref, _]) => ref);
    }

    /**
     * Retrieves the local edges from the wallet's spendable outputs.
     * 
     * @returns An array of TransactionOutputReference objects representing the local edges.
     */
    localEdges(): TransactionOutputReference[] {
        return this.wallet.spendableOutputs.filter(([_, output]) => output.value?.graphEntry?.edge !== undefined).map(([ref, _]) => ref);
    }
}
