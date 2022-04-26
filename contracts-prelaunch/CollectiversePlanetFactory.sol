// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CollectiversePlanet.sol";
import "./OperatorRole.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract CollectiversePlanetFactory is OperatorRole {
    string public version = "2.0";

    mapping(uint256 => address) public planets;
    uint256 public planetCount;

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
        //uint256 count = FERC1155(fnft).count() + 1;

        address planet = address(new CollectiversePlanet());
        CollectiversePlanet(planet).transferOwnership(msg.sender);
        CollectiversePlanet(planet).initialize(
            _metaDataUri,
            _name,
            _symbol,
            _amount,
            msg.sender
        );

        emit Mint(planet, planetCount);
        /* CollectiversePlanet(planet).safeTransferFrom(
            address(this),
            msg.sender,
            _fractionsId,
            _amount,
            bytes("0")
        ); */

        planets[planetCount] = planet;
        planetCount++;

        return planetCount - 1;
    }
}
