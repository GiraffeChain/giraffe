import { GiraffeWallet } from "./wallet";
import { GiraffeClient } from "./client";
import { TransactionOutput, TransactionOutputReference } from "./models";

export class GiraffeGraph {
    wallet: GiraffeWallet;
    client: GiraffeClient;
    constructor(wallet: GiraffeWallet, client: GiraffeClient) {
        this.wallet = wallet;
        this.client = client;
    }

    createVertexOutput(label: string, data: { [key: string]: any } | undefined): TransactionOutput {
        return TransactionOutput.fromJSON({
            lockAddress: this.wallet.address,
            value: {
                graphEntry: {
                    vertex: {
                        label: label,
                        data: data
                    }
                },
            },
        });
    }

    createEdgeOutput(label: string, a: TransactionOutputReference, b: TransactionOutputReference, data: { [key: string]: any } | undefined): TransactionOutput {
        return TransactionOutput.fromJSON({
            lockAddress: this.wallet.address,
            value: {
                graphEntry: {
                    edge: {
                        label: label,
                        data: data,
                        a: a,
                        b: b
                    }
                },
            },
        });
    }

    localVertices(): TransactionOutputReference[] {
        return this.wallet.spendableOutputs.filter(([_, output]) => output.value?.graphEntry?.vertex !== undefined).map(([ref, _]) => ref);
    }

    localEdges(): TransactionOutputReference[] {
        return this.wallet.spendableOutputs.filter(([_, output]) => output.value?.graphEntry?.edge !== undefined).map(([ref, _]) => ref);
    }
}
