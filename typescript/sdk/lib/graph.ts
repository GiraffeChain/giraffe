import { GiraffeWallet } from "./wallet.js";
import { GiraffeClient } from "./client.js";
import { Edge, TransactionId, TransactionOutput, TransactionOutputReference, Vertex } from "./models.js";

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

    /**
     * Retrieves all Edges connected to the given vertex
     * @param vertexReference - The vertex from which all edges should be retrieved.
     * @returns An async generator of all edges connected to the given vertex.
     */
    async *allE(vertexReference: TransactionOutputReference): AsyncGenerator<Edge, any, void> {
        const edgeRefs = await this.client.getEdges(vertexReference);
        for (const edgeRef of edgeRefs) {
            const output = await this.client.getTransactionOutput(edgeRef);
            const edge = output.value?.graphEntry?.edge!;
            yield this.backfillTransactionId(edge, vertexReference.transactionId!);
        }
    }

    /**
     * Retrieves all incoming edges connected to the given vertex.
     * 
     * @param vertexReference - The vertex from which all incoming edges should be retrieved.
     * @returns An async generator of all incoming edges connected to the given vertex.
     */
    async *inE(vertexReference: TransactionOutputReference): AsyncGenerator<Edge, any, void> {
        const edgeRefs = await this.client.getInEdges(vertexReference);
        for (const edgeRef of edgeRefs) {
            const output = await this.client.getTransactionOutput(edgeRef);
            yield output.value?.graphEntry?.edge!;
        }
    }

    /**
     * Retrieves all outgoing edges connected to the given vertex.
     * 
     * @param vertexReference - The vertex from which all outgoing edges should be retrieved.
     * @returns An async generator of all outgoing edges connected to the given vertex.
     */
    async *outE(vertexReference: TransactionOutputReference): AsyncGenerator<Edge, any, void> {
        const edgeRefs = await this.client.getOutEdges(vertexReference);
        for (const edgeRef of edgeRefs) {
            const output = await this.client.getTransactionOutput(edgeRef);
            yield output.value?.graphEntry?.edge!;
        }
    }

    /**
     * Retrieves the "a" vertex of the given edge.
     * 
     * @param edge - The edge from which the "a" vertex should be retrieved.
     * @returns The "a" vertex of the given edge.
     */
    async inV(edge: Edge): Promise<Vertex> {
        const output = await this.client.getTransactionOutput(edge.a!);
        return output.value?.graphEntry?.vertex!;
    }

    /**
     * Retrieves the "b" vertex of the given edge.
     * 
     * @param edge - The edge from which the "b" vertex should be retrieved.
     * @returns The "b" vertex of the given edge.
     */
    async outV(edge: Edge): Promise<Vertex> {
        const output = await this.client.getTransactionOutput(edge.b!);
        return output.value?.graphEntry?.vertex!;
    }

    /**
     * Queries the graph for edges matching the provided criteria, and returns the edges
     * @param label a required edge label
     * @param a an optional source vertex reference
     * @param b an optional destination vertex reference
     * @param where a list of conditions to filter the edge data
     * @returns an async generator of edges matching the provided criteria
     */
    async *queryE(label: String, a: TransactionOutputReference | undefined, b: TransactionOutputReference | undefined, where: [string, string, any][]): AsyncGenerator<Edge, any, void> {
        const edgeRefs = await this.client.queryEdges(label, a, b, where);
        for (const edgeRef of edgeRefs) {
            const output = await this.client.getTransactionOutput(edgeRef);
            const edge = output.value?.graphEntry?.edge!;
            yield this.backfillTransactionId(edge, edgeRef.transactionId!);
        }
    }

    /**
     * Queries the graph for vertices matching the provided criteria, and returns the vertices
     * @param label a required vertex label
     * @param where a list of conditions to filter the vertex data
     * @returns an async generator of vertices matching the provided criteria
     */
    async *queryV(label: String, where: [string, string, any][]): AsyncGenerator<ReferencedVertex, any, void> {
        const vertexRefs = await this.client.queryVertices(label, where);
        for (const vertexRef of vertexRefs) {
            const output = await this.client.getTransactionOutput(vertexRef);
            yield {
                ref: vertexRef,
                vertex: output.value?.graphEntry?.vertex!
            };
        }
    }

    private backfillTransactionId(edge: Edge, transactionId: TransactionId): Edge {
        const a: TransactionOutputReference = {
            transactionId: edge.a!.transactionId ?? transactionId,
            index: edge.a!.index
        };
        const b: TransactionOutputReference = {
            transactionId: edge.b!.transactionId ?? transactionId,
            index: edge.b!.index
        };
        return {
            ...edge,
            a: a,
            b: b
        };

    }

}

/**
 * A graph vertex and its ID/reference
 */
export interface ReferencedVertex {
    ref: TransactionOutputReference;
    vertex: Vertex;
}
