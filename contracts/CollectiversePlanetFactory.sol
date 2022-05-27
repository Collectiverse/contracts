// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PlanetVault.sol";
import "./CollectiversePlanet.sol";
import "./mock/Ship.sol";

contract CollectiversePlanetFactory is Ownable {
    string public version = "2.0";
    uint256 public planetCount = 0;
    address public settings;
    address immutable planetBeacon;


    mapping(uint256 => address) public planets;

    event Mint(address planet, uint256 planetId);

    constructor(address _blueprint, address _settings, address upgrader) {
        settings = _settings;
        UpgradeableBeacon _planetBeacon = new UpgradeableBeacon(_blueprint);
        _planetBeacon.transferOwnership(upgrader);
        planetBeacon = address(_planetBeacon);
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
        
        BeaconProxy proxy = new BeaconProxy(
            planetBeacon,
            abi.encodeWithSelector(
                CollectiversePlanet.initialize.selector,
                _metaDataUri,
                _name,
                _symbol,
                _amount,
                settings
            )
        );

        address planetVault = address(
            new PlanetVault(address(proxy), msg.sender, settings)
        );

        CollectiversePlanet(address(proxy)).mintPlanet(planetVault, "");
        CollectiversePlanet(address(proxy)).mintFractions(planetVault);

        emit Mint(address(proxy), planetCount);

        planetCount++;
        planets[planetCount] = address(proxy);

        return planetCount;
    }
}
