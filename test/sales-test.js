const { expect } = require("chai");
const { ethers } = require("hardhat");

const collectiverseWallet = "0x1000000000000000000000000000000000000000";
const vaultAddress = "0x2000000000000000000000000000000000000000";

async function loadContracts() {
  // user1: state, user2: operator, user3: user
  const signer = await ethers.getSigner();

  // mock usdc erc20
  const USDC = await ethers.getContractFactory("MockERC20");
  const usdc = await USDC.deploy(5000000 * 1000000, 6);
  await usdc.deployed();

  // mock vault factory
  const Vaults = await ethers.getContractFactory("MockVaultFactory");
  const vaults = await Vaults.deploy();
  await vaults.deployed();

  // planet erc1155
  const Planet = await ethers.getContractFactory("MockERC1155");
  const planet = await Planet.deploy("http://localhost:3000", [0, 1], [1, 10000]);
  await planet.deployed();

  // sales contract
  const Sales = await ethers.getContractFactory("SalesContract");
  const sales = await Sales.deploy(collectiverseWallet, vaults.address, 1, usdc.address);
  await sales.deployed();

  return { signer, usdc, planet, sales, vaults };
}

describe("Sales Contract", function () {
  it("Contracts deploy correctly", async function () {
    let { usdc, planet, sales } = await loadContracts();
    expect(usdc, planet, sales)
  });

  it("Adding Tokens and setting prices", async function () {
    let { signer, planet, sales } = await loadContracts();

    await planet.safeTransferFrom(signer.address, sales.address, 1, 8000, 0);
    expect(await planet.balanceOf(sales.address, 1)).to.equal(8000);

    expect(await sales.planetPrices(planet.address)).to.equal(0);
    await sales.setPrice(planet.address, 15 * 1000000);
    expect(await sales.planetPrices(planet.address)).to.equal(15 * 1000000);
  });

  it("Interacting with settings", async function () {
    let { sales } = await loadContracts();

    expect(await sales.useWhitelist()).to.equal(false);
    expect(await sales.useMaxAmount()).to.equal(false);
    await sales.setSettings(true, true, 20)
    expect(await sales.useWhitelist()).to.equal(true);
    expect(await sales.useMaxAmount()).to.equal(true);
  });

  it("Whitelisting user", async function () {
    let { signer, sales } = await loadContracts();

    expect(await sales.whitelist(signer.address)).to.equal(0);
    await sales.whitelistAddresses([signer.address], 2);
    expect(await sales.whitelist(signer.address)).to.equal(2);
    await sales.whitelistAddresses([signer.address], 1);
    expect(await sales.whitelist(signer.address)).to.equal(1);
  });

  it("Whitelisted user buys", async function () {
    let { signer, sales, planet, usdc, vaults } = await loadContracts();

    // prepare sales contract
    await sales.setSettings(true, true, 20)
    await planet.safeTransferFrom(signer.address, sales.address, 1, 10000, 0);
    await sales.setPrices([planet.address], 15 * 1000000);
    await sales.whitelistAddresses([signer.address], 1);

    // purchase
    amount = 20
    start = await usdc.balanceOf(signer.address);
    await vaults.createVault(vaultAddress);
    await usdc.approve(sales.address, amount * 15 * 1000000);
    await sales.purchase(planet.address, amount);

    // check results
    expect(await usdc.balanceOf(signer.address)).to.equal(start - (amount * 15 * 1000000));
    expect(await usdc.balanceOf(collectiverseWallet)).to.equal(amount * 15 * 1000000);
    expect(await planet.balanceOf(vaultAddress, 1)).to.equal(amount);
    expect(await planet.balanceOf(sales.address, 1)).to.equal(10000 - amount);
  });

  it("Not whitelisted user attempts buy", async function () {
    let { signer, sales, planet, usdc, vaults } = await loadContracts();

    // prepare sales contract
    await sales.setSettings(true, true, 20)
    await planet.safeTransferFrom(signer.address, sales.address, 1, 10000, 0);
    await sales.setPrices([planet.address], 15 * 1000000);

    // purchase
    try {
      amount = 20
      await vaults.createVault(vaultAddress);
      await usdc.approve(sales.address, amount * 15 * 1000000);
      await sales.purchase(planet.address, amount);
      expect(false)
    } catch (e) { }
  });

  it("Whitelisted without vault attempts buy", async function () {
    let { signer, sales, planet, usdc } = await loadContracts();

    // prepare sales contract
    await sales.setSettings(true, true, 20)
    await planet.safeTransferFrom(signer.address, sales.address, 1, 10000, 0);
    await sales.setPrices([planet.address], 15 * 1000000);
    await sales.whitelistAddresses([signer.address], 1);

    // purchase
    try {
      amount = 20
      await usdc.approve(sales.address, amount * 15 * 1000000);
      await sales.purchase(planet.address, amount);
      expect(false)
    } catch (e) { }
  });

  it("Testing Whitelist tiers", async function () {
    let { signer, sales, planet, usdc, vaults } = await loadContracts();

    // prepare sales contract
    await sales.setSettings(true, true, 20)
    await planet.safeTransferFrom(signer.address, sales.address, 1, 10000, 0);
    await sales.setPrices([planet.address], 15 * 1000000);
    await sales.whitelistAddresses([signer.address], 2);

    // purchase
    amount = 40
    start = await usdc.balanceOf(signer.address);
    await vaults.createVault(vaultAddress);
    await usdc.approve(sales.address, amount * 15 * 1000000);
    await sales.purchase(planet.address, amount);

    // check results
    expect(await usdc.balanceOf(signer.address)).to.equal(start - (amount * 15 * 1000000));
    expect(await usdc.balanceOf(collectiverseWallet)).to.equal(amount * 15 * 1000000);
    expect(await planet.balanceOf(vaultAddress, 1)).to.equal(amount);
    expect(await planet.balanceOf(sales.address, 1)).to.equal(10000 - amount);
  });

  it("Whitelisted user buys too much", async function () {
    let { signer, sales, planet, usdc, vaults } = await loadContracts();

    // prepare sales contract
    await sales.setSettings(true, true, 20)
    await planet.safeTransferFrom(signer.address, sales.address, 1, 10000, 0);
    await sales.setPrices([planet.address], 15 * 1000000);
    await sales.whitelistAddresses([signer.address], 1);

    try {
      // purchase
      amount = 30
      await vaults.createVault(vaultAddress);
      await usdc.approve(sales.address, amount * 15 * 1000000);
      await sales.purchase(planet.address, amount);
      expect(false)
    } catch (e) { }
  });

  it("Attempting to buy non registered token", async function () {
    let { signer, sales, planet, usdc, vaults } = await loadContracts();

    // prepare sales contract
    await sales.setSettings(true, true, 20)
    await planet.safeTransferFrom(signer.address, sales.address, 1, 10000, 0);
    await sales.setPrices([planet.address], 15 * 1000000);
    await sales.whitelistAddresses([signer.address], 1);

    try {
      // purchase
      amount = 20
      await vaults.createVault(vaultAddress);
      await usdc.approve(sales.address, amount * 15 * 1000000);
      await sales.purchase(collectiverseWallet, amount);
      expect(false)
    } catch (e) { }
  });
})