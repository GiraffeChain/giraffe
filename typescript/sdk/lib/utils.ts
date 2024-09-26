import { GiraffeClient } from "./client.js";
import { GraphEntry, LockAddress, Transaction, TransactionId, TransactionOutput, TransactionOutputReference } from "./models.js";

import bs58 from 'bs58'

export function requireDefined<T>(t: T | undefined): T {
    if (t === undefined) throw ReferenceError("Element Not Defined");
    else return t;
}

/**
 * Retrieves the set of lock addresses that must be satisfied in the given transaction's attestation.
 * 
 * @param client - The GiraffeClient instance used to interact with the Giraffe network.
 * @param transaction - The transaction for which to retrieve the required witnesses.
 * @returns A Promise that resolves to a Set of LockAddress objects representing the required witnesses.
 */
export async function requiredWitnessesOf(client: GiraffeClient, transaction: Transaction): Promise<Set<LockAddress>> {
    async function handleEdge(ref: TransactionOutputReference) {
        let aTxO: TransactionOutput;
        if (ref.transactionId === undefined) {
            aTxO = await client.getTransactionOutput(ref);
        } else {
            aTxO = transaction.outputs[ref.index];
        }
        const aVertex = aTxO!.graphEntry?.vertex;
        if (aVertex?.edgeLockAddress !== undefined) {
            result.add(aVertex.edgeLockAddress);
        }
    }

    const result: Set<LockAddress> = new Set();
    for (const input of transaction.inputs) {
        const out = await client.getTransactionOutput(input.reference!);
        result.add(out.lockAddress!);
    }
    for (const output of transaction.outputs) {
        if (output?.graphEntry !== undefined && output.graphEntry.edge !== undefined) {
            const edge = output.graphEntry.edge;
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

/**
 * Removes the self reference from a transaction output reference.
 * If the transaction output reference has a transactionId, it is returned as is.
 * If the transaction output reference does not have a transactionId, a new reference is created with the provided selfTransactionId.
 * @param output - The transaction output reference to remove self reference from.
 * @param selfTransactionId - The transactionId to use when creating a new reference without self reference.
 * @returns The transaction output reference without self reference.
 */
export function withoutSelfReference(output: TransactionOutputReference, selfTransactionId: TransactionId): TransactionOutputReference {
    if (output.transactionId === undefined) {
        return { transactionId: selfTransactionId, index: output.index };
    }
    return output;
}

/**
 * Calculates the required minimum quantity for a given transaction output. Registrations, account associations, and graph entries require extra quantities to be encumbered.
 * 
 * @param output - The transaction output.
 * @returns The required minimum quantity.
 */
export function requiredMinimumQuantity(output: TransactionOutput): number {
    var result = 0;
    result += 100;
    if (output.account !== undefined) {
        ;
        result += 100;
    }
    if (output.accountRegistration !== undefined) {
        result += 1000;
    }
    if (output.graphEntry !== undefined) {
        result += graphEntryMinimumQuantity(output.graphEntry);
    }
    return result;
}

function graphEntryMinimumQuantity(entry: GraphEntry): number {
    var result = 0;
    if (entry.vertex !== undefined) {
        result += entry.vertex!.label.length * 10;
        if (entry.vertex!.data !== undefined) {
            result += protoStructMinimumQuantity(entry.vertex.data);
        }
    } else if (entry.edge !== undefined) {
        result += entry.vertex!.label.length * 10;
        result += 100;
        if (entry.edge!.data !== undefined) {
            result += protoStructMinimumQuantity(entry.edge.data);
        }
    }
    return result;
}

function protoValueMinimumQuantity(value: any): number {
    if (typeof (value) === "number") {
        return value.toString().length * 10;
    } else if (typeof (value) === "string") {
        return value.length * 10;
    } else if (typeof (value) === "boolean") {
        return 10;
    } else if (Array.isArray(value)) {
        var result = 0;
        for (const v of value) {
            result += protoValueMinimumQuantity(v);
        }
        return result;
    } else if (typeof (value) === "object") {
        return protoStructMinimumQuantity(value);
    }
    return 10;
}

function protoStructMinimumQuantity(struct: { [key: string]: any }): number {
    var result = 0;
    for (const k in Object.keys(struct)) {
        result += (k.length * 10)
        result += protoValueMinimumQuantity(struct[k]);
    }
    return result;
}

/**
 * The default quantity to be provided as a tip/reward to the block producer.
 */
export const defaultTransactionTip = 1000;

/**
 * Checks if a transaction output is a liquid token, meaning it is not used for staking, is not an account registration, and contains no graph data.
 * 
 * @param transactionOutput - The transaction output to check.
 * @returns `true` if the transaction output is a liquid token, `false` otherwise.
 */
export function isPaymentToken(transactionOutput: TransactionOutput): boolean {
    return transactionOutput.account === undefined && transactionOutput.accountRegistration === undefined && transactionOutput.graphEntry === undefined;
}

/**
 * Constructs a URL which can be sent to another user to open in their own wallet to pay for a transaction.
 * 
 * @param transaction - A base transaction to be sent to the user to be paid, signed, and broadcasted.
 * @param walletBaseAddress - The base URL of the wallet. (i.e. https://testnet.giraffechain.com/#)
 * @returns The URL for the wallet transfer page.
 */
export function getWalletTransferUrl(transaction: Transaction, walletBaseAddress: string): string {
    const bytes = Transaction.encode(transaction).finish();
    const encoded = bs58.encode(bytes);
    return `${walletBaseAddress}/transfer/${encoded}`;
}
