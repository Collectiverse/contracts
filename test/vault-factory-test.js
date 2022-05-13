const { expect } = require("chai");
const { ethers } = require("hardhat");
describe("Vault Factory Testing", function () {
    it("Should create a vault", async function () {
      const [us, settings] = await ethers.getSigners();
      const Factory = await ethers.getContractFactory("UserVaultFactory");
      const factory = await Factory.deploy(settings.address); 
      await factory.deployed() 
      await factory.addOperator(us.address)
      console.log("lel");
      const userVault = await factory.mint();
      expect(await factory.vaults(1)).to.not.equal(0x0000000000000000000000000000000000000000);
    });
  });