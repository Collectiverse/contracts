// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface USDCToken {
    function transfer(address to, uint amount) external returns (bool);
}

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract CollectiverseTreasury is Ownable, ERC1155Holder {
    USDCToken public usdcToken;

    uint public teamPercentage = 80;
    address public teamWallet;
    uint public operationsMarketingPercentage = 20;
    address public operationsMarketingWallet;
    uint public totalBalance;
    event Deposit(uint amount);
    event Withdraw(uint amount);
    event WithdrawERC1155(address indexed token, uint256 tokenId, uint256 amount, address indexed from);
    constructor(address _usdcToken, address _teamWallet, address _operationsMarketingWallet) Ownable() {
        usdcToken = USDCToken(_usdcToken);
        teamWallet = _teamWallet;
        operationsMarketingWallet = _operationsMarketingWallet;
    }

    function deposit(uint _amount) public {
        totalBalance = totalBalance + _amount;
        emit Deposit(_amount);
    }

    function withdraw(uint _amount) public payable {
        require(totalBalance >= _amount, "Not enough balance");
        uint amountTeam = _amount / 100 * teamPercentage;
        usdcToken.transfer(teamWallet, amountTeam);
        usdcToken.transfer(operationsMarketingWallet, _amount - amountTeam);
        emit Withdraw(_amount);
    }
    function withdrawERC1155(address _token, uint256 _tokenId, uint256 _amount) external onlyOwner {
        IERC1155(_token).safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "0");
        emit WithdrawERC1155(_token, _tokenId, _amount, msg.sender);
    }
}
