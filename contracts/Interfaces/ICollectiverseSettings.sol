//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICollectiverseSettings {

    function getMintingHardCap() external view returns (uint256);
    function feeReceiver() external view returns (address);

}