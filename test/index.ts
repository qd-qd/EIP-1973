import { expect } from "chai";
import { ethers } from "hardhat";

describe("ERC20ScalableReward", function () {
  it("correctly sets constructor values", async function () {
    const Factory = await ethers.getContractFactory("FakeContract");
    const contract = await Factory.deploy("Test COIN", "TC", 8, 50);
    await contract.deployed();

    expect(await contract.getTokensPerBlock()).to.equal(8);
    expect(await contract.getBlockFreezeInterval()).to.equal(50);
  });
});
