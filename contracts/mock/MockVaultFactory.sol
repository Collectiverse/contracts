// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockVaultFactory {
    mapping(address => bool) public hasVault;
    mapping(address => address) public getVaultId;

    function createVault(address _vault) external {
        hasVault[msg.sender] = true;
        getVaultId[msg.sender] = _vault;
    }
}
