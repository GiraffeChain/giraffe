import { Giraffe } from "../lib/index";
import { GiraffeWallet } from "../lib/wallet";

describe("Integration Test", () => {
    test("Test", async () => {

        const wallet = GiraffeWallet.genesis();
        const baseAddress = "http://localhost:2024/api";
        const blockchain = await Giraffe.init(baseAddress, wallet);

        const headId = await blockchain.client.getCanonicalHeadId();
        console.log(headId.value);
        await blockchain.dispose();
    });
});