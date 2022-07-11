// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
//import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./InitializedProxy.sol";
import "./PlanetVault.sol";
import "./CollectiversePlanet.sol";
import "./Interfaces/ICollectiverseSettings.sol";
import "hardhat/console.sol";

contract CollectiversePlanetFactory is Ownable {
    string public version = "2.0";
    uint256 public planetCount = 0;
    address public settings;
    //address immutable planetBeacon;
    address public immutable logic;

    mapping(uint256 => address) public planets;

    event Vault(address vault);
    event Mint(address planet, uint256 planetId);

    constructor(
        address _settings
    ) {
        settings = _settings;
        logic = address(new CollectiversePlanet());
        //_planetBeacon.transferOwnership(upgrader);
        //planetBeacon = address(_planetBeacon);
    }

    /// @notice the function to mint a new vault
    /// @param _name the name of the planet
    /// @param _symbol the ticker of the planet
    /// @param _amount the amount of fractions
    /// @return the ID of the vault
    function mint(
        string memory _metaDataUri,
        string memory _name,
        string memory _symbol,
        uint256 _amount
    ) external onlyOwner returns (uint256) {

        bytes memory _initializationCalldata =
           abi.encodeWithSignature(
            "initialize(string,string,string,uint256,address)",
                _metaDataUri,
                _name,
                _symbol,
                _amount,
                settings
            );

        address planet = address(
            new InitializedProxy(logic, _initializationCalldata)
        );

        ICollectiversePlanet(planet).mintPlanet(msg.sender, "");

        PlanetVault vault = new PlanetVault(planet, msg.sender, settings);
        ICollectiversePlanet(planet).mintFractions(address(vault));

        emit Vault(address(vault));

        console.log("Planet Address", planet);

        emit Mint(planet, 1);

        planetCount++;
        planets[planetCount] = planet;

        return planetCount;
    }
}
