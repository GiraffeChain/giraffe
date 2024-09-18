
import * as g from "@giraffechain/giraffe-sdk";
import assert from "assert";
import bs58 from 'bs58';
import { Octokit } from "@octokit/core";

const skB58 = process.env.GIRAFFE_WALLET_SK!;
assert(skB58.length > 0, "Secret key is required");
const sk = bs58.decode(skB58);
assert(sk.length === 32, "Invalid secret key length");
const wallet = g.GiraffeWallet.fromSk(sk);

const quantityPerUser = process.env.FAUCET_QUANTITY_PER_USER!;
const apiAddress = process.env.GIRAFFE_API_ADDRESS!;
const githubToken = process.env.GITHUB_TOKEN!;
const octokit = new Octokit({ auth: githubToken });

const githubOrg = "giraffechain";
const githubRepo = "giraffe";

main();

async function main() {

    const giraffe = await g.Giraffe.init(apiAddress, wallet);

    assert(giraffe.wallet.liquidTokens.length > 0, "Wallet has no liquid tokens");

    try {

        const recipients = await getRecipients(octokit);

        if (recipients.isEmpty) {
            console.log("No recipients found");
            return;
        }

        const outputs: g.TransactionOutput[] = [];

        for (const [username, address] of Object.entries(recipients)) {
            console.log("Adding faucet recipient", username, g.showLockAddress(address));
            outputs.push(
                g.TransactionOutput.fromJSON({
                    lockAddress: address,
                    value: { quantity: quantityPerUser }
                })
            )
        }
        const tx = await giraffe.paySignBroadcast(g.Transaction.fromJSON({ outputs }));
        const txId = g.transactionId(tx);
        console.log("Faucet transaction", txId);
        await giraffe.client.confirmTransaction(txId);
        console.log("Faucet transaction confirmed");
    } finally {
        await giraffe.dispose();
    }
}

type Recipients = { [key: string]: g.LockAddress };

async function getRecipients(octokit): Promise<Recipients> {

    const stargazersIterator = octokit.paginate.iterator(octokit.rest.activity.listStargazersForRepo({
        GITHUB_ORG: githubOrg,
        GITHUB_REPO: githubRepo,
    }));

    const recipients: Recipients = {};

    for await (const { data: gazers } of stargazersIterator) {
        for (const gazer of gazers) {
            if (gazer.type !== 'User') {
                continue;
            }
            const username = gazer.login;

            const gistsIterator = octokit.paginate.iterator(octokit.rest.gists.listForUser({ username }));
            for await (const { data: gists } of gistsIterator) {
                for (const gist of gists) {
                    const filenames = Object.keys(gist.files);
                    const filename = filenames.find((filename) => filename.startsWith("a_") && filename.endsWith(".giraffe_faucet"));
                    if (filename) {
                        const addressStr = filename.substring(0, filename.length - ".giraffe_faucet".length);
                        try {
                            const address = g.decodeLockAddress(addressStr);
                            recipients[username] = address;
                        } catch (e) { }
                        break;
                    }
                }
            }
        }
    }
    return recipients;
}
