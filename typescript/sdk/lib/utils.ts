import { GiraffeClient } from "./client";
import { Edge, GraphEntry, LockAddress, Transaction, TransactionId, TransactionOutput, TransactionOutputReference } from "./proto/models/core";

import Long from "long";

export function requireDefined<T>(t: T | undefined): T {
    if (t === undefined) throw ReferenceError("Element Not Defined");
    else return t;
}

export async function requiredWitnessesOf(client: GiraffeClient, transaction: Transaction): Promise<Set<LockAddress>> {

    const result: Set<LockAddress> = new Set();
    for (const input of transaction.inputs) {
        const out = await client.getTransactionOutput(input.reference!);
        result.add(out.lockAddress!);
    }
    for (const output of transaction.outputs) {
        if (output?.value?.graphEntry !== undefined && output.value.graphEntry.edge !== undefined) {
            async function handleEdge(ref: TransactionOutputReference) {
                let aTxO: TransactionOutput;
                if (ref.transactionId === undefined) {
                    aTxO = await client.getTransactionOutput(ref);
                } else {
                    aTxO = transaction.outputs[ref.index];
                }
                const aVertex = aTxO!.value?.graphEntry?.vertex;
                if (aVertex?.edgeLockAddress !== undefined) {
                    result.add(aVertex.edgeLockAddress);
                }
            }
            const edge = output.value.graphEntry.edge;
            await handleEdge(edge.a!);
            await handleEdge(edge.b!);
        }
        if (output.account !== undefined) {
            let accountTxO: TransactionOutput;
            if (output.account.transactionId === undefined) {
                accountTxO = await client.getTransactionOutput(output.account);
            } else {
                accountTxO = transaction.outputs[output.account.index];
            }
            result.add(accountTxO.lockAddress!);
        }
    }
    return result;
}

export function withoutSelfReference(output: TransactionOutputReference, selfTransactionId: TransactionId): TransactionOutputReference {
    if (output.transactionId === undefined) {
        return { transactionId: selfTransactionId, index: output.index };
    }
    return output;
}

export function requiredMinimumQuantity(output: TransactionOutput): Long {
    var result = Long.ZERO;
    result.add(100);
    if (output.account !== undefined) {
        result.add(100);
    }
    if (output.value?.accountRegistration !== undefined) {
        result.add(1000);
    }
    if (output.value?.graphEntry !== undefined) {
        result.add(graphEntryMinimumQuantity(output.value.graphEntry));
    }
    return result;
}

function graphEntryMinimumQuantity(entry: GraphEntry): Long {
    var result = Long.ZERO;
    if (entry.vertex !== undefined) {
        result.add(entry.vertex!.label.length * 10);
        if (entry.vertex!.data !== undefined) {
            result.add(protoStructMinimumQuantity(entry.vertex.data));
        }
    } else if (entry.edge !== undefined) {
        result.add(entry.vertex!.label.length * 10);
        result.add(100);
        if (entry.edge!.data !== undefined) {
            result.add(protoStructMinimumQuantity(entry.edge.data));
        }
    }
    return result;
}

function protoValueMinimumQuantity(value: any): Long {
    if (typeof (value) === "number") {
        return new Long(value.toString().length * 10);
    } else if (typeof (value) === "string") {
        return new Long(value.length * 10);
    } else if (typeof (value) === "boolean") {
        return new Long(10);
    } else if (Array.isArray(value)) {
        var result = Long.ZERO;
        for (const v of value) {
            result.add(protoValueMinimumQuantity(v));
        }
        return result;
    } else if (typeof (value) === "object") {
        return protoStructMinimumQuantity(value);
    }
    return new Long(10);
}

function protoStructMinimumQuantity(struct: { [key: string]: any }): Long {
    var result = Long.ZERO;
    for (const k in Object.keys(struct)) {
        result.add(k.length * 10)
        result.add(protoValueMinimumQuantity(struct[k]));
    }
    return result;
}

export function rewardOf(transaction: Transaction): Long {
    var result = Long.ZERO;
    for (const input of transaction.inputs) {
        result.add(input.value!.quantity);
    }
    for (const output of transaction.outputs) {
        result.sub(output.value!.quantity);
    }
    return result;
}

export const defaultTransactionTip = new Long(1000);