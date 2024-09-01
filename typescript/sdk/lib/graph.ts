import { GiraffeWallet } from "./wallet";
import { GiraffeClient } from "./client";
import { TransactionOutput, TransactionOutputReference } from "./models";

import Long from 'long';


export class GiraffeGraph {
    wallet: GiraffeWallet;
    client: GiraffeClient;
    constructor(wallet: GiraffeWallet, client: GiraffeClient) {
        this.wallet = wallet;
        this.client = client;
    }

    createVertexOutput(label: string, data: { [key: string]: any } | undefined): TransactionOutput {
        return {
            lockAddress: this.wallet.address,
            value: {
                quantity: Long.ZERO,
                graphEntry: {
                    vertex: {
                        edgeLockAddress: undefined,
                        label: label,
                        data: data
                    }
                },
                accountRegistration: undefined
            },
            account: undefined
        };
    }

    createEdgeOutput(label: string, a: TransactionOutputReference, b: TransactionOutputReference, data: { [key: string]: any } | undefined): TransactionOutput {
        return {
            lockAddress: this.wallet.address,
            value: {
                quantity: Long.ZERO,
                graphEntry: {
                    edge: {
                        label: label,
                        data: data,
                        a: a,
                        b: b
                    }
                },
                accountRegistration: undefined
            },
            account: undefined
        };
    }

    localVertices(): TransactionOutputReference[] {
        return this.wallet.spendableOutputs.filter(([_, output]) => output.value?.graphEntry?.vertex !== undefined).map(([ref, _]) => ref);
    }

    localEdges(): TransactionOutputReference[] {
        return this.wallet.spendableOutputs.filter(([_, output]) => output.value?.graphEntry?.edge !== undefined).map(([ref, _]) => ref);
    }
}
