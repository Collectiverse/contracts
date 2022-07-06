const { ethers, upgrades } = require("hardhat");

const static = {
  "zero": "0x0000000000000000000000000000000000000000",
  "usdc": "0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E",
}

async function main() {
  const deployer = await ethers.getSigner();

  const settings = await ethers.getContractAt("CollectiverseSettings", "0xAbC2EAFC19671c5704d5b0eCE78934a962E0366F");
  const rewards = await ethers.getContractAt("CollectiverseRewards", "0x2b721B6748c84AD9B58BAb5F8CbE7CcAD4e9F246");
  const treasury = await ethers.getContractAt("CollectiverseTreasury", "0xcCB7DF3f5120Eed7081225Fb60731f9887D373ce");
  const planetFactory = await ethers.getContractAt("CollectiversePlanetFactory", "0x2674F116d2d2b73AEbc625ed368F378e831A3BA8");
  const planet = await ethers.getContractAt("CollectiversePlanet", "0xc4fdf2725CfdAD93db24464263a1e056d1F4e359");
  const userVaultFactory = await ethers.getContractAt("UserVaultFactory", "0x388A5b3a6220E7e88A3021cfC50c05C6C5Ea90bB");
  const salesContract = await ethers.getContractAt("SalesContract", "0xc931fb1EF7F02eaE2B8e83E9580711d20Ed5Bbd7");

  console.log("FUJI LIVE");
  console.log("Settings:", settings.address);
  console.log("Rewards :", rewards.address);
  console.log("Treasury:", treasury.address);
  console.log("PlanetFactory:", planetFactory.address);
  console.log("Planet Mars  :", planet.address);
  console.log("UserVaultFactory:", userVaultFactory.address);
  console.log("SalesContract:", salesContract.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});