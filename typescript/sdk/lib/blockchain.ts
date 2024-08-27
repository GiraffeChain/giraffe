import { BlockchainClient, RpcBlockchainClient } from "./client";
import { transactionSignableBytes } from "./codecs";
import { Transaction, TransactionOutput, TransactionOutputReference } from "./proto/models/core";
import { Wallet, WitnessContext } from "./wallet";

export class Blockchain {
    client: BlockchainClient;
    wallet: Wallet;
    disposalSteps: (() => Promise<void>)[] = [];

    constructor(client: BlockchainClient, wallet: Wallet) {
        this.client = client;
        this.wallet = wallet;
    }

    static async init(baseAddress: string, wallet: Wallet): Promise<Blockchain> {
        const client = new RpcBlockchainClient(baseAddress);

        const blockchain = new Blockchain(client, wallet);
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
        const headId = await this.client.getCanonicalHeadId();
        const head = await this.client.getHeader(headId);
        const context = new WitnessContext(head.height.add(1), transactionSignableBytes(transaction));
        const witness = this.wallet.signer(context);
        transaction.attestation.push(witness)
        return transaction;
    }

    async attestAndBroadcast(transaction: Transaction): Promise<void> {
        const tx = await this.attest(transaction);
        await this.client.broadcastTransaction(tx);
    }
}
