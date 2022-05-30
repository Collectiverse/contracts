// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface USDCToken {
    function transfer(address to, uint amount) external returns (bool);
}

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract CollectiverseRewards is Ownable {
    USDCToken public usdcToken;
    mapping (address => uint) planetUSDC; //First uint is the planet ID And the second mapping uint 0 = USDC amount and uint 1 = 
    mapping (address => bool) whitelistedForWithdraw;
    mapping (uint => address) whitelistedForWithdrawIdentifier;
    uint public balanceToWithdraw;
    bool public hasUsedOneTimeWithdraw;
    // modifier isWhitelisted(address checkAddress) {
    //     require(whitelistedForWithdraw[checkAddress] == true, "Address is not whitelisted");
    //     _;

    function addWhitelistAccess(address _newAddress) onlyOwner public {
        require(whitelistedForWithdraw[_newAddress] == false, "Already whitelisted for withdraws");
        whitelistedForWithdraw[_newAddress] = true;
    }
    function removeWhitelistAccess(address _newAddress) onlyOwner public {
        require(whitelistedForWithdraw[_newAddress] == true, "Not whitelisted for withdraws");
        whitelistedForWithdraw[_newAddress] = false;
    }
    constructor(address _usdcToken) Ownable() {
        usdcToken = USDCToken(_usdcToken);
        hasUsedOneTimeWithdraw = false;
    }

    function deposit(uint _amount, address _planetAddress) public {
        require(whitelistedForWithdraw[msg.sender] == true, "Address is not whitelisted");
        planetUSDC[_planetAddress] = planetUSDC[_planetAddress] + _amount;
        balanceToWithdraw = balanceToWithdraw + _amount;
    }
    function withdraw(uint _amount, address _planetAddress, address _outAddress) public payable {
        require(whitelistedForWithdraw[msg.sender] == true || owner() == _msgSender(), "Caller is not owner neither a whitelisted contract");
        require(planetUSDC[_planetAddress] >= _amount, "Not enough balance for this planet.");
        usdcToken.transfer(_outAddress, _amount);
        planetUSDC[_planetAddress] = planetUSDC[_planetAddress] - _amount;
        balanceToWithdraw - _amount;
    }
    function oneTimeWithdraw(uint _amount, address _outAddress) public payable {
        require(hasUsedOneTimeWithdraw == false, "You have already used the 1 time withdraw");
        require(whitelistedForWithdraw[msg.sender] == true || owner() == _msgSender(), "Caller is not owner neither a whitelisted contract");
        require(balanceToWithdraw >= _amount, "Not enough balance");
        usdcToken.transfer(_outAddress, _amount);
        hasUsedOneTimeWithdraw = true;
        //Yet to add what planet we took it from.
    }
}
