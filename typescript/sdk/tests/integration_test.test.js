"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const blockchain_1 = require("../lib/blockchain");
const wallet_1 = require("../lib/wallet");
describe("Integration Test", () => {
    test("Test", async () => {
        const wallet = wallet_1.Wallet.genesis();
        const baseAddress = "http://localhost:2025/api";
        const blockchain = await blockchain_1.Blockchain.init(baseAddress, wallet);
        const headId = await blockchain.client.getCanonicalHeadId();
        console.log(headId.value);
        await blockchain.dispose();
    });
});
