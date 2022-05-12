// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    uint8 private _decimals;

    constructor(uint256 _supply, uint8 __decimals) ERC20("Token", "TKN") {
        _decimals = __decimals;
        _mint(msg.sender, _supply);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}
