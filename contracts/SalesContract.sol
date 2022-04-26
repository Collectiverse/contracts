// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SalesContract is Ownable {
    using SafeERC20 for IERC20;

    // wallet where the profits go to
    address public wallet;

    // sold erc1155
    address public erc1155;
    uint256 public erc1155Id;

    // payment erc20
    address public erc20;
    uint256 public price;

    constructor(
        address _wallet,
        address _erc1155,
        uint256 _erc1155Id,
        address _erc20,
        uint256 _price
    ) {
        wallet = _wallet;
        erc1155 = _erc1155;
        erc1155Id = _erc1155Id;
        erc20 = _erc20;
        price = _price;
    }

    function buy() public {
        require(true); // check if person has a multisig
    }

    // withdraw if funds are stuck in the contract
    /*
    function withdraw(uint256 _amount) external onlyOwner {
        require(_amount <= address(this).balance);
        payable(msg.sender).transfer(_amount);
    }

    function withdrawERC20(address _asset, uint256 _amount) external onlyOwner {
        IERC20(_asset).safeTransfer(msg.sender, _amount);
    }

    function withdrawERC1155(
        address _asset,
        uint256 _id,
        uint256 _amount
    ) external onlyOwner {
        IERC1155(_asset).safeTransferFrom(
            address(this),
            msg.sender,
            _id,
            _amount,
            "0"
        );
    }
    */
}
