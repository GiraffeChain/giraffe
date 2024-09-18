import { Giraffe, GiraffeWallet } from "../lib/index.js";

describe("Giraffe Tests", () => {
    test.skip("Close client", async () => {
        const giraffe = await Giraffe.init("https://testnet.giraffechain.com/api", GiraffeWallet.genesis());
        const headId = await giraffe.client.getCanonicalHeadId();
        console.log(headId);
        expect(headId.value).not.toBeNull();
        giraffe.close();
        await new Promise(resolve => setTimeout(resolve, 5000));
        expect(true).toBe(true);
    }, 15000)
});
