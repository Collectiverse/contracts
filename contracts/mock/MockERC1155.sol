// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MockERC1155 is ERC1155 {
    constructor(
        string memory _url,
        uint256[] memory _ids,
        uint256[] memory _supply
    ) ERC1155(_url) {
        for (uint256 i = 0; i < _ids.length; i++) {
            _mint(msg.sender, _ids[i], _supply[i], "");
        }
    }
}
