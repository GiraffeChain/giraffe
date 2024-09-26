
import * as g from "@giraffechain/giraffe-sdk";
import assert from "assert";
import bs58 from 'bs58';
import { Octokit } from "octokit";

const skB58 = process.env.GIRAFFE_WALLET_SK!;
assert(skB58.length > 0, "Secret key is required");
const sk = bs58.decode(skB58);
assert(sk.length === 32, "Invalid secret key length");
const wallet = g.GiraffeWallet.fromSk(sk);
console.log("Address", g.showLockAddress(wallet.address));

const quantityPerUser = process.env.FAUCET_QUANTITY_PER_USER!;
const apiAddress = process.env.GIRAFFE_API_ADDRESS!;
const githubToken = process.env.GITHUB_TOKEN!;
const octokit = new Octokit({ auth: githubToken });

const githubOrg = "GiraffeChain";
const githubRepo = "giraffe";

main();

async function main() {

    const giraffe = await g.Giraffe.init(apiAddress, wallet);

    assert(giraffe.wallet.liquidTokens().length > 0, "Wallet has no liquid tokens");

    try {

        const recipients = Object.entries(await getRecipients(octokit));

        if (recipients.length == 0) {
            console.log("No recipients found");
            return;
        }

        const outputs: g.TransactionOutput[] = [];

        for (const [username, address] of recipients) {
            console.log("Adding faucet recipient", username, g.showLockAddress(address), quantityPerUser);
            outputs.push(
                g.TransactionOutput.fromJSON({
                    lockAddress: address,
                    quantity: quantityPerUser
                })
            )
        }

        if (outputs.length == 0) {
            console.log("No outputs found");
            return;
        }

        const tx = await giraffe.paySignBroadcast(g.Transaction.fromJSON({ outputs }));
        const txId = g.transactionId(tx);
        console.log("Sending faucet transaction", g.showTransactionId(txId));
        await giraffe.client.confirmTransaction(txId);
        console.log("Faucet transaction confirmed");
    } finally {
        giraffe.close();
    }
}

type Recipients = { [key: string]: g.LockAddress };

async function getRecipients(octokit): Promise<Recipients> {

    const stargazersIterator = octokit.paginate.iterator(octokit.rest.activity.listStargazersForRepo, {
        owner: githubOrg,
        repo: githubRepo,
    });

    const recipients: Recipients = {};

    for await (const { data } of stargazersIterator) {
        for (const gazer of data) {
            if (gazer.type !== 'User') {
                continue;
            }
            const username = gazer.login;
            const address = await addressForUser(username, octokit);
            if (address) {
                recipients[username] = address;
            }
        }
    }
    return recipients;
}

async function addressForUser(username: string, octokit): Promise<g.LockAddress | undefined> {
    const iterator = octokit.paginate.iterator(octokit.rest.gists.listForUser, { username });
    for await (const { data } of iterator) {
        for (const gist of data) {
            const filenames = Object.keys(gist.files);
            // console.log("Checking gists for user", username, filenames);
            const filename = filenames.find((filename) => filename.startsWith("a_") && filename.endsWith(".giraffe_faucet"));
            if (filename) {
                const addressStr = filename.substring(0, filename.length - ".giraffe_faucet".length);
                try {
                    const address = g.decodeLockAddress(addressStr);
                    console.log("Found valid recipient", username, addressStr);
                    return address;
                } catch (e) {
                    // console.log("Skipping invalid entry", username, addressStr);
                }
            }
        }
    }
    // console.debug("User does not have a properly configured faucet gist", username);
}
