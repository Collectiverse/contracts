const { expect } = require("chai");
const { ethers } = require("hardhat");
describe("Vault Testing", function () {
  it("Verify Settings address is correct", async function() {
    const userVaultGenerator = await ethers.getContractFactory("UserVault");
    const [us, settings] = await ethers.getSigners();
    const userVault = await userVaultGenerator.deploy(us.address, settings.address);
    await userVault.deployed();
    expect(await userVault.collectiverseSettingsAddress()).to.equal(settings.address);
  })
  it("Verify Ownerchange works", async function() {
    const userVaultGenerator = await ethers.getContractFactory("UserVault");
    const [us, settings, newOwner] = await ethers.getSigners();
    const userVault = await userVaultGenerator.deploy(us.address, settings.address);
    await userVault.deployed();
    old_count = await userVault.getTransactionCount();
    await userVault.renounceOwner(newOwner.address);
    expect(await userVault.getTransactionCount()).to.not.equal(old_count);
    trans = await userVault.getTransaction(0);
    expect(trans["numConfirmations"]).to.equal(0);
    await userVault.confirmTransaction(0);
    trans = await userVault.getTransaction(0)
    expect(trans["numConfirmations"]).to.equal(1);
    trans = await userVault.executeTransaction(0);
    expect(await userVault.owner()).to.equal(newOwner.address);
})
});