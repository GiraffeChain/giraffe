import { AccountRegistration, BlockId, Edge, GraphEntry, Lock, LockAddress, StakingRegistration, Transaction, TransactionId, TransactionInput, TransactionOutput, TransactionOutputReference, Vertex, Asset } from "./models.js";
import bs58 from 'bs58'

import blake2b from 'blake2b';
import { requireDefined } from "./utils.js";

/**
 * Converts a BlockId to its corresponding string representation.
 * 
 * @param blockId - The BlockId to convert.
 * @returns The string representation of the BlockId.
 */
export function showBlockId(blockId: BlockId): string {
    return "b_" + blockId.value;
}

/**
 * Converts a TransactionId to a string representation.
 * 
 * @param transactionId - The TransactionId to convert.
 * @returns The string representation of the TransactionId.
 */
export function showTransactionId(transactionId: TransactionId): string {
    return "t_" + transactionId.value;
}

/**
 * Converts a LockAddress object to a string representation.
 * 
 * @param lockAddress - The LockAddress object to convert.
 * @returns The string representation of the LockAddress.
 */
export function showLockAddress(lockAddress: LockAddress): string {
    return "a_" + lockAddress.value;
}

/**
 * Displays a string representation of a transaction output reference.
 *
 * @param reference - The transaction output reference to display.
 * @returns The string representation of the transaction output reference.
 */
export function showTransactionOutputReference(reference: TransactionOutputReference): string {
    return showTransactionId(requireDefined(reference.transactionId)) + ":" + reference.index;
}

/**
 * Decodes a block ID from the given input string.
 *
 * @param input - The input string to decode.
 * @returns The decoded BlockId object.
 */
export function decodeBlockId(input: string): BlockId {
    const value = input.startsWith("b_") ? input.substring(2) : input;
    if (bs58.decodeUnsafe(value)?.length !== 32) throw Error("Invalid block ID");
    return { value };
}

/**
 * Decodes a transaction ID from the given input.
 * 
 * @param input - The input string representing the transaction ID.
 * @returns The decoded transaction ID.
 */
export function decodeTransactionId(input: string): TransactionId {
    const value = input.startsWith("t_") ? input.substring(2) : input;
    if (bs58.decodeUnsafe(value)?.length !== 32) throw Error("Invalid transaction ID");
    return { value };
}

/**
 * Decodes a lock address.
 *
 * @param input - The input string to decode.
 * @returns The decoded lock address.
 */
export function decodeLockAddress(input: string): LockAddress {
    const value = input.startsWith("a_") ? input.substring(2) : input;
    if (bs58.decodeUnsafe(value)?.length !== 32) throw Error("Invalid address");
    return { value };
}

/**
 * Calculates the signable bytes for a given transaction.
 *
 * @param transaction - The transaction object.
 * @returns The signable bytes as a Uint8Array.
 */
export function transactionSignableBytes(transaction: Transaction): Uint8Array {
    return mergeArrays([encodeList(encodeTransactionInput, transaction.inputs), encodeList(encodeTransactionOutput, transaction.outputs), optCodec(transaction.rewardParentBlockId, encodeBlockId)]);
}

/**
 * Generates a transaction ID for the given transaction.
 * If the transaction already has a transaction ID, it returns the existing ID.
 * Otherwise, it computes a new transaction ID.
 *
 * @param transaction - The transaction object.
 * @returns The transaction ID.
 */
export function transactionId(transaction: Transaction): TransactionId {
    if (transaction.transactionId !== undefined) return transaction.transactionId;
    return computeTransactionId(transaction);
}

/**
 * Embeds a transaction ID into the given transaction object.
 * 
 * @param transaction - The transaction object to embed the ID into.
 */
export function embedTransactionId(transaction: Transaction) {
    transaction.transactionId = computeTransactionId(transaction);
}

/**
 * Computes the transaction ID for a given transaction.
 * 
 * @param transaction - The transaction object.
 * @returns The transaction ID as a string.
 */
export function computeTransactionId(transaction: Transaction): TransactionId {
    return { value: bs58.encode(hash256(transactionSignableBytes(transaction))) };
}

function encodeInt32(value: number): Uint8Array {
    let bytes = new Uint8Array(4);
    var v = value;
    for (let i = 3; i >= 0; i--) {
        bytes[i] = (v & 0xff);
        v = v >> 8;
    }
    return bytes;
}

function encodeInt64(value: number): Uint8Array {
    let bytes = new Uint8Array(8);
    var v = value;
    for (let i = 7; i >= 0; i--) {
        bytes[i] = v & 0xff;
        v = v >> 8;
    }
    return bytes;
}

function encodeList<T>(encodeT: (t: T) => Uint8Array, list: T[]): Uint8Array {
    const encodedList = list.map(encodeT);
    const totalLength = encodedList.reduce((acc, arr) => acc + arr.length, 0);
    const result = new Uint8Array(totalLength + 4);
    result.set(encodeInt32(list.length));
    let offset = 4;
    for (const arr of encodedList) {
        result.set(arr, offset);
        offset += arr.length;
    }
    return result;
}

function encodeBlockId(value: BlockId): Uint8Array {
    return bs58.decode(value.value);
}

function encodeTransactionId(value: TransactionId): Uint8Array {
    return bs58.decode(value.value);
}

function encodeTransactionInput(input: TransactionInput): Uint8Array {
    return mergeArrays([encodeTransactionOutputReference(requireDefined(input.reference))])
}

function encodeTransactionOutputReference(value: TransactionOutputReference): Uint8Array {
    return mergeArrays([optCodec(value.transactionId, encodeTransactionId), encodeInt32(requireDefined(value.index))]);
}

function encodeTransactionOutput(value: TransactionOutput): Uint8Array {
    return mergeArrays([
        encodeLockAddress(requireDefined(value.lockAddress)),
        encodeInt64(requireDefined(value.quantity)),
        optCodec(value.account, encodeTransactionOutputReference),
        optCodec(value.graphEntry, encodeGraphEntry),
        optCodec(value.accountRegistration, encodeAccountRegistration),
        optCodec(value.asset, encodeAsset)
    ]);
}

function encodeLockAddress(value: LockAddress): Uint8Array {
    return bs58.decode(value.value);
}

function encodeAccountRegistration(value: AccountRegistration): Uint8Array {
    return mergeArrays([encodeLockAddress(requireDefined(value.associationLock)), optCodec(value.stakingRegistration, encodeStakingRegistration)]);
}

function encodeGraphEntry(value: GraphEntry): Uint8Array {
    if (value.vertex !== undefined) {
        return encodeGraphVertex(value.vertex);
    } else if (value.edge !== undefined) {
        return encodeGraphEdge(value.edge);
    }
    throw Error("GraphEntry must have either vertex or edge");
}

function encodeGraphVertex(value: Vertex): Uint8Array {
    return mergeArrays([encodeUtf8(value.label), optCodec(value.data, encodeStruct)]);
}

function encodeGraphEdge(value: Edge): Uint8Array {
    return mergeArrays([encodeUtf8(value.label), optCodec(value.data, encodeStruct), encodeTransactionOutputReference(requireDefined(value.a)), encodeTransactionOutputReference(requireDefined(value.b))]);
}

function encodeAsset(value: Asset): Uint8Array {
    return mergeArrays([encodeTransactionOutputReference(requireDefined(value.origin)), encodeInt64(value.quantity)]);
}

function encodeStruct(value: { [key: string]: any }): Uint8Array {
    let sortedKeys = Object.keys(value).sort();
    let encodedPairs = sortedKeys.map(k => mergeArrays([encodeUtf8(k), encodeStructValue(value[k])]));
    return encodeList((t) => t, encodedPairs);
}

function encodeStakingRegistration(value: StakingRegistration): Uint8Array {
    return mergeArrays([bs58.decode(value.commitmentSignature), bs58.decode(value.vk)]);
}

function encodeLock(value: Lock): Uint8Array {
    if (value.ed25519 !== undefined) {
        return bs58.decode(value.ed25519.vk);
    }
    throw Error("Lock type undefined");
}

/**
 * Converts a Lock object to a LockAddress object.
 * @param value - The Lock object to be converted.
 * @returns The LockAddress object representing the lock's address.
 */
export function lockToAddress(value: Lock): LockAddress {
    return { value: bs58.encode(hash256(encodeLock(value))) };
}

function encodeStructValue(value: any): Uint8Array {
    if (typeof value === 'string') {
        return encodeUtf8(value);
    } else if (typeof value === 'number') {
        return encodeUtf8(value.toString());
    } else if (typeof value === 'boolean') {
        return new Uint8Array([value ? 1 : 0]);
    } else if (Array.isArray(value)) {
        return mergeArrays(value.map(encodeStructValue));
    } else {
        return encodeStruct(value);
    }
}

function encodeUtf8(value: string): Uint8Array {
    return new TextEncoder().encode(value);
}

function hash256(data: Uint8Array): Uint8Array {
    return requireDefined(blake2b(32)).update(data).digest();
}

function optCodec<T>(t: T | undefined, encode: (t: T) => Uint8Array): Uint8Array {
    if (t === undefined) return new Uint8Array([0]);
    else return mergeArrays([new Uint8Array([1]), encode(t)]);
}

function mergeArrays(arrays: Uint8Array[]): Uint8Array {
    const totalLength = arrays.reduce((acc, arr) => acc + arr.length, 0);
    const result = new Uint8Array(totalLength);
    let offset = 0;
    for (const arr of arrays) {
        result.set(arr, offset);
        offset += arr.length;
    }
    return result;
}
