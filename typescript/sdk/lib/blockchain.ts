import { GiraffeClient, RpcGiraffeClient } from "./client";
import { embedTransactionId, transactionSignableBytes } from "./codecs";
import { GiraffeGraph } from "./graph";
import { Transaction, TransactionInput, TransactionOutput, TransactionOutputReference } from "./proto/models/core";
import { defaultTransactionTip, requiredMinimumQuantity, requiredWitnessesOf, rewardOf } from "./utils";
import { GiraffeWallet, WitnessContext } from "./wallet";

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

        const blockchain = new Giraffe(client, wallet);
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
        for await (const s of changes) {
            const references = await this.client.getLockAddressState(this.wallet.address);
            const utxos: [TransactionOutputReference, TransactionOutput][] = await Promise.all(references.map(async r => [r, await this.client.getTransactionOutput(r)]));
            this.wallet.updateSpendableOutputs(utxos);
        }

        this.disposalSteps.push(() => changes.return({}).then(() => { }));
    }

    async attest(transaction: Transaction): Promise<Transaction> {
        const message = transactionSignableBytes(transaction);
        const headId = await this.client.getCanonicalHeadId();
        const head = await this.client.getHeader(headId);
        const ctx = new WitnessContext(head.height, message);
        const requiredWitnesses = await requiredWitnessesOf(this.client, transaction);
        for (const address of requiredWitnesses) {
            if (transaction.attestation.findIndex((v, _, __) => v.lockAddress === address) === -1) {
                const signer = this.wallet.signers.find(([a, _]) => a === address);
                if (signer !== undefined) {
                    const witness = signer[1](ctx);
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
        var currentReward = rewardOf(transaction);
        const remainingSpendableOutputs = [...this.wallet.spendableOutputs];
        var i = 0;
        while (currentReward.compare(defaultTransactionTip) != 0) {
            if (currentReward > defaultTransactionTip) {
                const output: TransactionOutput = {
                    lockAddress: this.wallet.address,
                    value: {
                        quantity: currentReward.sub(defaultTransactionTip),
                        graphEntry: undefined,
                        accountRegistration: undefined
                    },
                    account: undefined
                };
                transaction.outputs.push(output);
                currentReward = defaultTransactionTip;
            } else if (i >= remainingSpendableOutputs.length) {
                throw new Error("Insufficient funds");
            } else {
                const out = remainingSpendableOutputs[i];
                i++;
                const input: TransactionInput = {
                    reference: out[0],
                    value: out[1].value
                };
                transaction.inputs.push(input);
                currentReward = currentReward.add(out[1].value!.quantity);
            }
        }
        embedTransactionId(transaction);
        return transaction;
    }

    async broadcast(transaction: Transaction): Promise<void> {
        // TODO: Temporarily remove UTxOs from wallet?
        await this.client.broadcastTransaction(transaction);
    }

    async attestPayBroadcast(transaction: Transaction): Promise<void> {
        await this.broadcast(await this.pay(await this.attest(transaction)));
    }


}
