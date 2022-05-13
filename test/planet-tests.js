const { expect } = require("chai");
const { ethers } = require("hardhat");

const fakeAddress = "0x2000000000000000000000000000000000000000";

describe("Planet Vault", function () {

    let SettingsContract;
    let settings;
    let owner;
    let addr1;
    let addr2;
    let addrs;

    beforeEach(async function () {
        // Get the ContractFactory and Signers here.
        SettingsContract = await ethers.getContractFactory("CollectiverseSettings");
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    
        // To deploy our contract, we just have to call Token.deploy() and await
        // for it to be deployed(), which happens once its transaction has been
        // mined.
        settings = await SettingsContract.deploy(owner.address, fakeAddress, fakeAddress, fakeAddress, owner.address);
        await settings.deployed();

      });
    
      it("Can Create a Planet", async function() {
        const Planet = await ethers.getContractFactory('CollectiversePlanet');
        const planet = await upgrades.deployProxy(Planet, ['https://blas', 'Mars', 'mars', '10000', settings.address]);

        await planet.mintPlanet(owner.address, []);
        const balance = await planet.balanceOf(owner.address, 0);

        expect(balance).to.equal(1);
    });

    it("Can Create a Planet Vault", async function() {
        const PlanetVaultFactory = await ethers.getContractFactory('CollectiversePlanetFactory');
        const vaultFactory = await PlanetVaultFactory.deploy(settings.address, owner.address); 
        await vaultFactory.deployed();

        

        expect(vaultFactory.address);
    });
});