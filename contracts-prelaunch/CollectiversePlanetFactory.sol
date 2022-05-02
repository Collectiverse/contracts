// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CollectiversePlanet.sol";
import "./PlanetVault.sol";
import "./OperatorRole.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract CollectiversePlanetFactory is OperatorRole {
    string public version = "2.0";

    uint256 planetCount = 0;
    mapping(uint256 => address) public planets;

    event Mint(address planet, uint256 planetId);

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
    ) external onlyOperator returns (uint256) {
        /*
        uint256 count = FERC1155(fnft).count() + 1;
        address vault = address(new Vault(fnft, count, _token, _id, msg.sender));
        uint256 fractionId = FERC1155(fnft).mint(vault, _amount);
        require(count == fractionId, "mismatch");

        emit Mint(_token, _id, fractionId, vault, vaultCount);
        IERC721(_token).safeTransferFrom(msg.sender, vault, _id);
        FERC1155(fnft).safeTransferFrom(
        address(this),
        msg.sender,
        fractionId,
        _amount,
        bytes("0")
        );

        vaults[vaultCount] = vault;
        vaultCount++;

        return vaultCount - 1;
        */

        address planet = address(new CollectiversePlanet());
        address planetVault = address(new PlanetVault(planet, msg.sender));

        CollectiversePlanet(planet).transferOwnership(msg.sender);
        CollectiversePlanet(planet).initialize(
            _metaDataUri,
            _name,
            _symbol,
            _amount
        );

        CollectiversePlanet(planet)._mintPlanet(msg.sender, "");
        CollectiversePlanet(planet)._mintFractions(planetVault);

        emit Mint(planet, planetCount);

        planetCount++;
        planets[planetCount] = planet;

        return planetCount;
    }
}
