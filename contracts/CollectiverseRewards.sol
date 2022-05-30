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
    uint public maxTries;
    uint public currentTry;
    uint public oneTimeWithdrawBalance;
    // modifier isWhitelisted(address checkAddress) {
    //     require(whitelistedForWithdraw[checkAddress] == true, "Address is not whitelisted");
    //     _;
    event Deposit(uint amount, address planetAddress);
    event OneTimeWithdraw(uint amount, address outAddress);
    event Withdraw(uint amount, address planetAddress, address outAddress);
    event AddWhitelistAccess(address newAddress);
    event RemoveWhitelistAccess(address removeAddress);
    function addWhitelistAccess(address _newAddress) onlyOwner public {
        require(whitelistedForWithdraw[_newAddress] == false, "Already whitelisted for withdraws");
        whitelistedForWithdraw[_newAddress] = true;
        emit AddWhitelistAccess(_newAddress);
    }
    function removeWhitelistAccess(address _removeAddress) onlyOwner public {
        require(whitelistedForWithdraw[_removeAddress] == true, "Not whitelisted for withdraws");
        whitelistedForWithdraw[_removeAddress] = false;
        emit RemoveWhitelistAccess(_removeAddress);
    }
    constructor(address _usdcToken, uint _maxTries) Ownable() {
        usdcToken = USDCToken(_usdcToken);
        maxTries = _maxTries;
        currentTry = 0;
        oneTimeWithdrawBalance = 150000;
    }

    function deposit(uint _amount, address _planetAddress) public {
        require(whitelistedForWithdraw[msg.sender] == true, "Address is not whitelisted");
        planetUSDC[_planetAddress] = planetUSDC[_planetAddress] + _amount;
        balanceToWithdraw = balanceToWithdraw + _amount;
        emit Deposit(_amount, _planetAddress);
    }
    function withdraw(uint _amount, address _planetAddress, address _outAddress) public payable {
        require(whitelistedForWithdraw[msg.sender] == true || owner() == _msgSender(), "Caller is not owner neither a whitelisted contract");
        require(planetUSDC[_planetAddress] >= _amount, "Not enough balance for this planet.");
        usdcToken.transfer(_outAddress, _amount);
        planetUSDC[_planetAddress] = planetUSDC[_planetAddress] - _amount;
        balanceToWithdraw - _amount;
        emit Withdraw(_amount, _planetAddress, _outAddress);
    }
    function oneTimeWithdraw(uint _amount, address _outAddress) public payable {
        require(currentTry <= maxTries, "You have exceeded the maximum amount of tries");
        require(whitelistedForWithdraw[msg.sender] == true || owner() == _msgSender(), "Caller is not owner neither a whitelisted contract");
        require(balanceToWithdraw >= _amount, "Not enough balance");
        require(_amount > oneTimeWithdrawBalance, "You have exceeded the max amount withdrawable");
        usdcToken.transfer(_outAddress, _amount);
        currentTry = currentTry + 1;
        oneTimeWithdrawBalance = oneTimeWithdrawBalance - _amount;
        emit OneTimeWithdraw(_amount, _outAddress);
    }
    function editMaxTries(uint _newMax) onlyOwner public {
        maxTries = _newMax;
    }

}
