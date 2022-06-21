// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CollectiverseTreasury is Ownable, ERC1155Holder {
    using SafeERC20 for IERC20;

    IERC20 public usdcToken;

    uint256 public teamPercentage = 80;
    address public teamWallet;
    uint256 public operationsMarketingPercentage = 20;
    address public operationsMarketingWallet;
    uint256 public totalBalance;
    event Deposit(uint256 amount);
    event Withdraw(uint256 amount);
    event WithdrawERC1155(
        address indexed token,
        uint256 tokenId,
        uint256 amount,
        address indexed from
    );

    constructor(
        address _usdcToken,
        address _teamWallet,
        address _operationsMarketingWallet
    ) Ownable() {
        usdcToken = IERC20(_usdcToken);
        teamWallet = _teamWallet;
        operationsMarketingWallet = _operationsMarketingWallet;
    }

    function deposit(uint256 _amount) public {
        totalBalance = totalBalance + _amount;
        emit Deposit(_amount);
    }

    function withdraw(uint256 _amount) public payable {
        require(totalBalance >= _amount, "Not enough balance");
        uint256 amountTeam = (_amount / 100) * teamPercentage;
        usdcToken.safeTransfer(teamWallet, amountTeam);
        usdcToken.safeTransfer(operationsMarketingWallet, _amount - amountTeam);
        emit Withdraw(_amount);
    }

    function withdrawERC1155(
        address _token,
        uint256 _tokenId,
        uint256 _amount
    ) external onlyOwner {
        IERC1155(_token).safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId,
            _amount,
            "0"
        );
        emit WithdrawERC1155(_token, _tokenId, _amount, msg.sender);
    }
}
