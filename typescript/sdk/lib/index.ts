import { GiraffeClient, RpcGiraffeClient } from "./client.js";
import { embedTransactionId, transactionSignableBytes } from "./codecs.js";
import { GiraffeGraph } from "./graph.js";
import { Transaction, TransactionInput, TransactionOutput, TransactionOutputReference } from "./proto/models/core.js";
import { defaultTransactionTip, isPaymentToken, requiredMinimumQuantity, requiredWitnessesOf, rewardOf } from "./utils.js";
import { GiraffeWallet, WitnessContext } from "./wallet.js";

export * from "./models.js";
export * from "./codecs.js";
export * from "./client.js";
export * from "./wallet.js";
export * from "./graph.js";
export * from "./utils.js";

/**
 * Represents a Giraffe instance that combines wallet functionality with client functionality.
 */
export class Giraffe {
    client: GiraffeClient;
    wallet: GiraffeWallet;
    graph: GiraffeGraph
    disposalSteps: (() => Promise<void>)[] = [];

    /**
     * Constructs a new instance of the class.
     * @param client - The GiraffeClient instance.
     * @param wallet - The GiraffeWallet instance.
     */
    constructor(client: GiraffeClient, wallet: GiraffeWallet) {
        this.client = client;
        this.wallet = wallet;
        this.graph = new GiraffeGraph(wallet, client);
    }

    /**
     * Initializes a Giraffe instance.
     * 
     * @param baseAddress - The base address of the Giraffe network. For example, "http://localhost:2024/api".
     * @param wallet - The Giraffe wallet to use for transactions.
     * @returns A Promise that resolves to a Giraffe instance.
     * @throws An error if unable to contact the network.
     */
    static async init(baseAddress: string, wallet: GiraffeWallet): Promise<Giraffe> {
        const client = new RpcGiraffeClient(baseAddress);

        try {
            await client.getCanonicalHeadId();
        } catch (_) {
            throw new Error("Unable to contact network");
        }

        const blockchain = new Giraffe(client, wallet);
        await blockchain.updateWalletUtxos();
        blockchain.background();
        return blockchain;
    }

    /**
     * Asynchronously disposes the object.
     * 
     * @returns A promise that resolves when the disposal is complete.
     */
    async dispose(): Promise<void> {
        var step = this.disposalSteps.pop();
        while (step !== undefined) {
            await step();
            step = this.disposalSteps.pop();
        }
    }

    /**
     * Asynchronously runs a background process that listens for changes and updates the wallet UTXOs.
     * @returns A promise that resolves when the background process is complete.
     */
    async background(): Promise<void> {
        const changes = this.client.follow();
        this.disposalSteps.push(() => changes.return({}).then(() => { }));
        for await (const _ of changes) {
            await this.updateWalletUtxos();
        }
    }

    /**
     * Signs a transaction.
     * 
     * @param transaction - The transaction to sign.
     * @returns A promise that resolves to the signed transaction.
     */
    async sign(transaction: Transaction): Promise<Transaction> {
        const message = transactionSignableBytes(transaction);
        const headId = await this.client.getCanonicalHeadId();
        const head = await this.client.getHeader(headId);
        const ctx = new WitnessContext(head.height, message);
        const requiredWitnesses = await requiredWitnessesOf(this.client, transaction);
        for (const address of Array.from(requiredWitnesses)) {
            if (transaction.attestation.findIndex((v, _, __) => v.lockAddress?.value === address.value) === -1) {
                const signer = this.wallet.getSigner(address);
                // TODO: Error if undefined?
                if (signer !== undefined) {
                    const witness = signer(ctx);
                    transaction.attestation.push(witness);
                }
            }
        }
        return transaction;
    }

    /**
     * Pays for a transaction by adjusting the output values and adding necessary inputs.
     * 
     * @param transaction - The transaction to be paid for.
     * @returns A promise that resolves to the paid transaction.
     * @throws {Error} If there are no spendable funds or insufficient funds.
     */
    async pay(transaction: Transaction): Promise<Transaction> {
        for (const output of transaction.outputs) {
            if (!output.lockAddress) {
                output.lockAddress = this.wallet.address;
            }
            const minQuantity = requiredMinimumQuantity(output);
            if (output.value!.quantity < minQuantity) {
                output.value!.quantity = minQuantity;
            }
        }
        const remainingSpendableOutputs = [...this.wallet.spendableOutputs.filter(([_, out]) => isPaymentToken(out))];
        if (remainingSpendableOutputs.length === 0) {
            throw new Error("No spendable funds");
        }
        var currentReward = rewardOf(transaction);
        var i = 0;
        while (currentReward != defaultTransactionTip) {
            if (currentReward > defaultTransactionTip) {
                const output: TransactionOutput = TransactionOutput.fromJSON({
                    lockAddress: this.wallet.address,
                    value: {
                        quantity: currentReward - defaultTransactionTip,
                    },
                });
                transaction.outputs.push(output);
                currentReward = defaultTransactionTip;
            } else if (i >= remainingSpendableOutputs.length) {
                throw new Error("Insufficient funds");
            } else {
                const [ref, output] = remainingSpendableOutputs[i];
                i++;
                const input: TransactionInput = TransactionInput.fromJSON({
                    reference: ref,
                    value: output.value!
                });
                transaction.inputs.push(input);
                currentReward = currentReward + output.value!.quantity;
            }
        }
        embedTransactionId(transaction);
        return transaction;
    }

    /**
     * Broadcasts a transaction to the network. Note: The transaction is not immediately included in the chain.
     *
     * @param transaction - The transaction to be broadcasted.
     * @returns A promise that resolves when the transaction is accepted into the node's mempool.
     */
    async broadcast(transaction: Transaction): Promise<void> {
        // TODO: Temporarily remove UTxOs from wallet?
        await this.client.broadcastTransaction(transaction);
    }

    /**
     * Pays, signs, and broadcasts a transaction.
     * 
     * @param transaction - The transaction to be paid, signed, and broadcasted.
     * @returns The paid, signed, and broadcasted transaction.
     */
    async paySignBroadcast(transaction: Transaction): Promise<Transaction> {
        const tx = await this.sign(await this.pay(transaction))
        await this.broadcast(tx);
        return tx;
    }

    /**
     * Updates the wallet's UTXOs (Unspent Transaction Outputs).
     * Retrieves the lock address state for the wallet's address and fetches the corresponding transaction outputs.
     * Updates the wallet's spendable outputs with the fetched UTXOs.
     * 
     * @returns A Promise that resolves to void.
     */
    async updateWalletUtxos(): Promise<void> {
        const references = await this.client.getLockAddressState(this.wallet.address);
        const utxos: [TransactionOutputReference, TransactionOutput][] = await Promise.all(references.map(async r => [r, await this.client.getTransactionOutput(r)]));
        this.wallet.updateSpendableOutputs(utxos);
    }

    /**
     * Transfers a specified quantity of tokens from the Genesis wallet to the current wallet.
     * 
     * @param quantity - The quantity of tokens to transfer.
     * @returns A promise that resolves when the transfer is broadcasted.
     */
    async transferFromGenesisWallet(quantity: number): Promise<void> {
        const giraffeGenesis = new Giraffe(this.client, GiraffeWallet.genesis());
        await giraffeGenesis.updateWalletUtxos();
        await giraffeGenesis.paySignBroadcast(Transaction.fromJSON({
            outputs: [
                {
                    lockAddress: this.wallet.address,
                    value: {
                        quantity: quantity,
                    },
                }
            ]
        }));
        await giraffeGenesis.dispose();
    }

    /**
     * Retrieves the given UTxOs from the local wallet (of any type, including registration, delegation, or graph entry), and converts their value back into the local
     * wallet as a liquid token.
     * @param outputs UTxOs from the local wallet that should be consumed and converted into liquid funds
     */
    async liquidate(outputs: TransactionOutputReference[]): Promise<void> {
        const inputs: TransactionInput[] = [];
        for (const ref of outputs) {
            const output = await this.client.getTransactionOutput(ref);
            inputs.push(TransactionInput.fromJSON({ reference: ref, value: output.value! }));
        }
        await this.paySignBroadcast(Transaction.fromJSON({ inputs: inputs }));
    }

}
