import { Lock, LockAddress, TransactionOutput, TransactionOutputReference, Witness } from "./proto/models/core";

import Long from 'long';
import { requireDefined } from "./utils";
import { lockToAddress } from "./codecs";
import bs58 from 'bs58'
import { ed25519 } from '@noble/curves/ed25519';
import * as bip39 from '@scure/bip39';
import { wordlist } from '@scure/bip39/wordlists/english';

export class Wallet {
    spendableOutputs: ReferencedOutput[];
    address: LockAddress;
    lock: Lock;
    signer: Signer;
    onUpdated: () => void = () => { };

    constructor(address: LockAddress, lock: Lock, signer: Signer) {
        this.spendableOutputs = [];
        this.address = address;
        this.lock = lock;
        this.signer = signer;
    }

    static fromSk(sk: Uint8Array): Wallet {
        const vk = ed25519.getPublicKey(sk);
        const lock: Lock = { ed25519: { vk: bs58.encode(vk) } };
        const lockAddress = lockToAddress(lock);
        const signer: Signer = (ctx: WitnessContext) => {
            const signature = ed25519.sign(sk, ctx.messageToSign);
            return { lock, key: { ed25519: { signature: bs58.encode(signature) } }, lockAddress };
        };
        return new Wallet(lockAddress, lock, signer);
    }

    static genesis(): Wallet {
        const sk = new Uint8Array(32);
        return Wallet.fromSk(sk);
    }

    static async fromMnemonic(mnemonic: string, password: string): Promise<Wallet> {
        const seed = await bip39.mnemonicToSeed(mnemonic, password);
        return Wallet.fromSk(seed.slice(0, 32));
    }

    static generateMnemonic(): string {
        return bip39.generateMnemonic(wordlist);
    }

    addListener(listener: () => void) {
        let p = this.onUpdated;
        this.onUpdated = () => {
            p();
            listener();
        }
    }

    updateSpendableOutputs(spendableOutputs: ReferencedOutput[]) {
        this.spendableOutputs = spendableOutputs;
        this.onUpdated();
    }

    paymentTokens(): ReferencedOutput[] {
        return this.spendableOutputs.filter(([_, o]) => o.account === undefined && o.value?.accountRegistration === undefined && o.value?.graphEntry === undefined);
    }
}

export type Signer = (ctx: WitnessContext) => Witness;

export type ReferencedOutput = [TransactionOutputReference, TransactionOutput];

export class WitnessContext {
    height: Long;
    messageToSign: Uint8Array;

    constructor(height: Long, messageToSign: Uint8Array) {
        this.height = height;
        this.messageToSign = messageToSign;
    }

    async validate(witness: Witness) {
        const lock = requireDefined(witness.lock);
        const expectedAddress = lockToAddress(lock);
        if (witness.lockAddress != expectedAddress) return ["Invalid LockAddress"];

        if (lock.ed25519 !== undefined && witness.key?.ed25519 !== undefined) {
            const isValid = ed25519.verify(
                bs58.decode(witness.key.ed25519.signature),
                this.messageToSign,
                bs58.decode(lock.ed25519.vk),
            );
            if (isValid)
                return [];
            else
                return ["Signature mismatch"];
        }
        return ["Invalid Lock/Key type"];
    }
}