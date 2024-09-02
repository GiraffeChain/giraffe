import { GiraffeClient, RpcGiraffeClient } from "./client";
import { embedTransactionId, transactionSignableBytes } from "./codecs";
import { GiraffeGraph } from "./graph";
import { Transaction, TransactionInput, TransactionOutput, TransactionOutputReference } from "./proto/models/core";
import { defaultTransactionTip, isPaymentToken, requiredMinimumQuantity, requiredWitnessesOf, rewardOf } from "./utils";
import { GiraffeWallet, WitnessContext } from "./wallet";

import Long from "long";

export * from "./models";
export * from "./codecs";
export * from "./client";
export * from "./wallet";
export * from "./graph";
export * from "./utils";

export class Giraffe {
    client: GiraffeClient;
    wallet: GiraffeWallet;
    graph: GiraffeGraph
    disposalSteps: (() => Promise<void>)[] = [];

    constructor(client: GiraffeClient, wallet: GiraffeWallet) {
        this.client = client;
        this.wallet = wallet;
        this.graph = new GiraffeGraph(wallet, client);
    }

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

    async dispose(): Promise<void> {
        var step = this.disposalSteps.pop();
        while (step !== undefined) {
            await step();
            step = this.disposalSteps.pop();
        }
    }

    async background(): Promise<void> {
        const changes = this.client.follow();
        for await (const _ of changes) {
            await this.updateWalletUtxos();
        }

        this.disposalSteps.push(() => changes.return({}).then(() => { }));
    }

    async sign(transaction: Transaction): Promise<Transaction> {
        const message = transactionSignableBytes(transaction);
        const headId = await this.client.getCanonicalHeadId();
        const head = await this.client.getHeader(headId);
        const ctx = new WitnessContext(head.height, message);
        const requiredWitnesses = await requiredWitnessesOf(this.client, transaction);
        for (const address of requiredWitnesses) {
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

    async pay(transaction: Transaction): Promise<Transaction> {
        for (const output of transaction.outputs) {
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
        while (!currentReward.eq(defaultTransactionTip)) {
            if (currentReward > defaultTransactionTip) {
                const output: TransactionOutput = TransactionOutput.fromJSON({
                    lockAddress: this.wallet.address,
                    value: {
                        quantity: currentReward.sub(defaultTransactionTip),
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
                currentReward = currentReward.add(output.value!.quantity);
            }
        }
        embedTransactionId(transaction);
        return transaction;
    }

    async broadcast(transaction: Transaction): Promise<void> {
        // TODO: Temporarily remove UTxOs from wallet?
        await this.client.broadcastTransaction(transaction);
    }

    async paySignBroadcast(transaction: Transaction): Promise<Transaction> {
        const tx = await this.sign(await this.pay(transaction))
        await this.broadcast(tx);
        return tx;
    }

    async updateWalletUtxos(): Promise<void> {
        const references = await this.client.getLockAddressState(this.wallet.address);
        const utxos: [TransactionOutputReference, TransactionOutput][] = await Promise.all(references.map(async r => [r, await this.client.getTransactionOutput(r)]));
        this.wallet.updateSpendableOutputs(utxos);
    }

    async transferFromGenesisWallet(quantity: Long): Promise<void> {
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

}
