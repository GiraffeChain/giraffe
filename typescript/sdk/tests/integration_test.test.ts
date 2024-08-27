import { Blockchain } from "../lib/blockchain";
import { Wallet } from "../lib/wallet";

describe("Integration Test", () => {
    test("Test", async () => {

        const wallet = Wallet.genesis();
        const baseAddress = "http://localhost:2025/api";
        const blockchain = await Blockchain.init(baseAddress, wallet);

        const headId = await blockchain.client.getCanonicalHeadId();
        console.log(headId.value);
        await blockchain.dispose();
    });
});