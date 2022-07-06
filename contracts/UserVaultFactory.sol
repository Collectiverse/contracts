// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./UserVault.sol";
import "./OperatorRole.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "hardhat/console.sol";

contract UserVaultFactory is OperatorRole {
    string public version = "1.0";
    address public collectiverseSettings;
    uint256 vaultCount = 0;
    mapping(uint256 => address) public vaults;
    event Mint(address vault, uint256 vaultId);

    constructor(address _collectiverseSettings) {
        collectiverseSettings = _collectiverseSettings;
        __OperatorRole_init();
    }

    function mint() external onlyOperator returns (uint256) {
        address userVault = address(
            new UserVault(msg.sender, collectiverseSettings)
        );
        vaultCount++;
        emit Mint(userVault, vaultCount);
        console.log("Vault Address", userVault);

        vaults[vaultCount] = userVault;
        return vaultCount;
    }
}
