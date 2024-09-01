import { Lock, LockAddress, TransactionOutput, TransactionOutputReference, Witness } from "./models";

import Long from 'long';
import { isPaymentToken, requireDefined } from "./utils";
import { lockToAddress } from "./codecs";
import bs58 from 'bs58'
import { ed25519 } from '@noble/curves/ed25519';
import * as bip39 from '@scure/bip39';
import { wordlist } from '@scure/bip39/wordlists/english';

export class GiraffeWallet {
    spendableOutputs: ReferencedOutput[];
    pendingOutputs: ReferencedOutput[];
    address: LockAddress;
    locks: [LockAddress, Lock][];
    signers: [LockAddress, Signer][];
    onUpdated: () => void = () => { };

    constructor(address: LockAddress, locks: [LockAddress, Lock][], signers: [LockAddress, Signer][]) {
        this.spendableOutputs = [];
        this.address = address;
        this.locks = locks;
        this.signers = signers;
    }

    static fromSk(sk: Uint8Array): GiraffeWallet {
        const vk = ed25519.getPublicKey(sk);
        const lock: Lock = { ed25519: { vk: bs58.encode(vk) } };
        const lockAddress = lockToAddress(lock);
        const signer: Signer = (ctx: WitnessContext) => {
            const signature = ed25519.sign(ctx.messageToSign, sk);
            return { lock, key: { ed25519: { signature: bs58.encode(signature) } }, lockAddress };
        };
        return new GiraffeWallet(lockAddress, [[lockAddress, lock]], [[lockAddress, signer]]);
    }

    static genesis(): GiraffeWallet {
        const sk = new Uint8Array(32);
        return GiraffeWallet.fromSk(sk);
    }

    static async keyFromMnemonic(mnemonic: string, password: string): Promise<Uint8Array> {
        const seed = await bip39.mnemonicToSeed(mnemonic, password);
        return seed.slice(0, 32);
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

    getSpendableOutput(reference: TransactionOutputReference): TransactionOutput | undefined {
        return this.spendableOutputs.find(([r, _]) => r.transactionId === reference.transactionId && r.index === reference.index)?.[1];
    }

    getLock(address: LockAddress): Lock | undefined {
        return this.locks.find(([a, _]) => a.value === address.value)?.[1];
    }

    getSigner(address: LockAddress): Signer | undefined {
        return this.signers.find(([a, _]) => a.value === address.value)?.[1];
    }

    updateSpendableOutputs(spendableOutputs: ReferencedOutput[]) {
        this.spendableOutputs = spendableOutputs;
        this.onUpdated();
    }

    paymentTokens(): ReferencedOutput[] {
        return this.spendableOutputs.filter(([_, o]) => isPaymentToken(o));
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