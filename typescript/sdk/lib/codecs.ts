import { AccountRegistration, BlockId, Edge, GraphEntry, Lock, LockAddress, StakingRegistration, Transaction, TransactionId, TransactionInput, TransactionOutput, TransactionOutputReference, Value, Vertex } from "./proto/models/core";
import bs58 from 'bs58'
import Long from "long";

import blake2b from 'blake2b';
import { requireDefined } from "./utils";

export function showBlockId(blockId: BlockId): string {
    return "b_" + blockId.value;
}

export function showTransactionId(transactionId: TransactionId): string {
    return "t_" + transactionId.value;
}

export function showLockAddress(lockAddress: LockAddress): string {
    return "a_" + lockAddress.value;
}

export function decodeBlockId(input: string): BlockId {
    if (input.startsWith("b_")) return { value: input.substring(2) };
    else return { value: input };
}

export function decodeTransactionId(input: string): TransactionId {
    if (input.startsWith("t_")) return { value: input.substring(2) };
    else return { value: input };
}

export function decodeLockAddress(input: string): LockAddress {
    if (input.startsWith("a_")) return { value: input.substring(2) };
    else return { value: input };
}

export function transactionSignableBytes(transaction: Transaction): Uint8Array {
    return mergeArrays([encodeList(encodeTransactionInput, transaction.inputs), encodeList(encodeTransactionOutput, transaction.outputs), optCodec(transaction.rewardParentBlockId, encodeBlockId)]);
}

export function transactionId(transaction: Transaction): TransactionId {
    if (transaction.transactionId !== undefined) return transaction.transactionId;
    return computeTransactionId(transaction);
}

export function embedTransactionId(transaction: Transaction) {
    transaction.transactionId = computeTransactionId(transaction);
}

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

function encodeInt64(value: Long): Uint8Array {
    return new Uint8Array(value.toBytesBE());
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
    return mergeArrays([encodeTransactionOutputReference(requireDefined(input.reference)), encodeValue(requireDefined(input.value))])
}

function encodeTransactionOutputReference(value: TransactionOutputReference): Uint8Array {
    return mergeArrays([optCodec(value.transactionId, encodeTransactionId), encodeInt32(requireDefined(value.index))]);
}

function encodeTransactionOutput(value: TransactionOutput): Uint8Array {
    return mergeArrays([encodeLockAddress(requireDefined(value.lockAddress)), encodeValue(requireDefined(value.value)), optCodec(value.account, encodeTransactionOutputReference)]);
}

function encodeLockAddress(value: LockAddress): Uint8Array {
    return bs58.decode(value.value);
}

function encodeValue(value: Value): Uint8Array {
    return mergeArrays([encodeInt64(requireDefined(value.quantity)), optCodec(value.accountRegistration, encodeAccountRegistration), optCodec(value.graphEntry, encodeGraphEntry)]);
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
