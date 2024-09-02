import { Lock, LockAddress, TransactionOutput, TransactionOutputReference, Witness } from "./models";

import Long from 'long';
import { isPaymentToken, requireDefined } from "./utils";
import { lockToAddress } from "./codecs";
import bs58 from 'bs58'
import { ed25519 } from '@noble/curves/ed25519';
import * as bip39 from '@scure/bip39';
import { wordlist } from '@scure/bip39/wordlists/english';

/**
 * Represents a GiraffeWallet.
 * A GiraffeWallet is a class that holds information about a wallet in the Giraffe SDK.
 * It contains spendable outputs, pending outputs, address, locks, signers, and an onUpdated event handler.
 * The GiraffeWallet class provides methods for creating wallets, retrieving outputs, locks, and signers,
 * updating spendable outputs, and retrieving payment tokens.
 */
export class GiraffeWallet {
    spendableOutputs: ReferencedOutput[];
    pendingOutputs: ReferencedOutput[];
    address: LockAddress;
    locks: [LockAddress, Lock][];
    signers: [LockAddress, Signer][];
    onUpdated: () => void = () => { };

    /**
     * Constructs a new Wallet instance.
     * 
     * @param address - The address of the wallet.
     * @param locks - An array of lock addresses and corresponding locks.
     * @param signers - An array of lock addresses and corresponding signers.
     */
    constructor(address: LockAddress, locks: [LockAddress, Lock][], signers: [LockAddress, Signer][]) {
        this.spendableOutputs = [];
        this.address = address;
        this.locks = locks;
        this.signers = signers;
    }

    /**
     * Creates a GiraffeWallet instance from a given secret key.
     * 
     * @param sk - The secret key as a Uint8Array. Should be 32 bytes long.
     * @returns A new GiraffeWallet instance.
     */
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

    /**
     * Generates a GiraffeWallet instance representing the genesis wallet. The genesis wallet is the "public" or "test" wallet. In private local testnets, it is funded with a large amount of tokens.
     * 
     * @returns {GiraffeWallet} The GiraffeWallet instance representing the genesis wallet.
     */
    static genesis(): GiraffeWallet {
        const sk = new Uint8Array(32);
        return GiraffeWallet.fromSk(sk);
    }

    /**
     * Generates a cryptographic key from a mnemonic and password.
     * 
     * @param mnemonic - The mnemonic phrase.
     * @param password - The password that is combined with the mnemonic (to make your key unique to _you_). Can be empty.
     * @returns A Promise that resolves to a Uint8Array representing the generated key.
     */
    static async keyFromMnemonic(mnemonic: string, password: string): Promise<Uint8Array> {
        const seed = await bip39.mnemonicToSeed(mnemonic, password);
        return seed.slice(0, 32);
    }

    /**
     * Generates a mnemonic string, which is a list of space-separated words that deterministically generate a secret key.
     *
     * @returns The generated mnemonic string.
     */
    static generateMnemonic(): string {
        return bip39.generateMnemonic(wordlist);
    }

    /**
     * Adds a listener function to be called when the wallet is updated.
     * 
     * @param listener - The listener function to be called.
     */
    addListener(listener: () => void) {
        let p = this.onUpdated;
        this.onUpdated = () => {
            p();
            listener();
        }
    }

    /**
     * Retrieves the spendable output from this wallet based on the provided transaction output reference.
     * 
     * @param reference - The transaction output reference to search for.
     * @returns The spendable output matching the provided reference, or undefined if not found.
     */
    getSpendableOutput(reference: TransactionOutputReference): TransactionOutput | undefined {
        return this.spendableOutputs.find(([r, _]) => r.transactionId === reference.transactionId && r.index === reference.index)?.[1];
    }

    /**
     * Retrieves the lock associated with the given address.
     * 
     * @param address - The address of the lock to retrieve.
     * @returns The lock associated with the given address, or undefined if not found.
     */
    getLock(address: LockAddress): Lock | undefined {
        return this.locks.find(([a, _]) => a.value === address.value)?.[1];
    }

    /**
     * Retrieves the signer associated with the specified address.
     * 
     * @param address - The address of the signer.
     * @returns The signer associated with the address, or undefined if not found.
     */
    getSigner(address: LockAddress): Signer | undefined {
        return this.signers.find(([a, _]) => a.value === address.value)?.[1];
    }

    /**
     * Updates the spendable outputs of the wallet.
     * 
     * @param spendableOutputs - An array of referenced outputs.
     */
    updateSpendableOutputs(spendableOutputs: ReferencedOutput[]) {
        this.spendableOutputs = spendableOutputs;
        this.onUpdated();
    }

    /**
     * Retrieves the payment tokens from the spendable outputs.
     * 
     * @returns An array of ReferencedOutput objects representing the payment tokens.
     */
    paymentTokens(): ReferencedOutput[] {
        return this.spendableOutputs.filter(([_, o]) => isPaymentToken(o));
    }
}

/**
 * Represents a function that takes a `WitnessContext` and returns a `Witness`.
 */
export type Signer = (ctx: WitnessContext) => Witness;

/**
 * Represents a tuple of a transaction output reference and the corresponding output.
 * 
 * @typedef {Array<TransactionOutputReference, TransactionOutput>} ReferencedOutput
 */
export type ReferencedOutput = [TransactionOutputReference, TransactionOutput];

/**
 * Provides contextual information when validating a witness.
 */
export class WitnessContext {
    height: Long;
    messageToSign: Uint8Array;

    /**
     * Constructs a new instance of the WitnessContext class.
     * @param height - The upcoming height of the chain.
     * @param messageToSign - The message to sign.
     */
    constructor(height: Long, messageToSign: Uint8Array) {
        this.height = height;
        this.messageToSign = messageToSign;
    }

    /**
     * Validates a witness object.
     * 
     * @param witness - The witness object to validate.
     * @returns An array of error messages if the witness is invalid, otherwise an empty array.
     */
    async validate(witness: Witness): Promise<string[]> {
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