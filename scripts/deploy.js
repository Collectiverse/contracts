const { ethers, upgrades } = require("hardhat");

const static = {
  "zero": "0x0000000000000000000000000000000000000000",
  "usdc": "0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E",
}

async function main() {
  const deployer = await ethers.getSigner();

  const Settings = await ethers.getContractFactory("CollectiverseSettings");
  const settings = await Settings.deploy(deployer.address, static.zero, static.zero, static.zero, deployer.address);

  const Rewards = await ethers.getContractFactory("CollectiverseRewards");
  const rewards = await Rewards.deploy(static.usdc, 10, deployer.address);

  const Treasury = await ethers.getContractFactory("CollectiverseTreasury");
  const treasury = await Treasury.deploy(static.usdc, static.zero, static.zero);

  // Running out of gas
  const PlanetFactory = await ethers.getContractFactory("CollectiversePlanetFactory");
  const planetFactory = await PlanetFactory.deploy(settings.address);

  const planet = await planetFactory.mint("https://example.com", "Mars", "MARS", 10000)

  const UserVaultFactory = await ethers.getContractFactory("UserVaultFactory");
  const userVaultFactory = await UserVaultFactory.deploy(settings.address);

  // Testing UserVault
  await userVaultFactory.addOperator(deployer.address);
  await userVaultFactory.mint();

  const SalesContract = await ethers.getContractFactory("SalesContract");
  const salesContract = await SalesContract.deploy(deployer.address, userVaultFactory.address, 1, static.usdc);


  console.log("DEPLOYMENT SUCCESSFUL");
  console.log("Settings:", settings.address);
  console.log("Rewards :", rewards.address);
  console.log("Treasury:", treasury.address);
  console.log("PlanetFactory:", planetFactory.address);
  console.log("Planet Mars  :", await planetFactory.planets(1));
  console.log("UserVaultFactory:", userVaultFactory.address);
  console.log("UserVault       :", await userVaultFactory.vaults(1));
  console.log("SalesContract:", salesContract.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
