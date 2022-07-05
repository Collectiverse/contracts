//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface ICollectiversePlanet is IERC1155 {

    function mintPlanet(address _owner, bytes memory data) external;
    function mintFractions(address vault) external;
    function burn(
        address,
        uint256,
        uint256
    ) external;

    function totalSupply(uint256) external view returns (uint256);

}