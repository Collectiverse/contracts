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
    mapping(uint => mapping(address => bool)) public isConfirmed;
    address public signingAddress;
    uint public balanceToWithdraw;
    uint public maxTries;
    uint public currentTry;
    uint public oneTimeWithdrawBalance;
    uint public numConfirmationsRequired = 1;
    struct Withdraw {
        address planetAddress;
        address outAddress;
        uint value;
        bool executed;
        uint numConfirmations;
    }
    Withdraw[] public withdraws;
    // modifier isWhitelisted(address checkAddress) {
    //     require(whitelistedForWithdraw[checkAddress] == true, "Address is not whitelisted");
    //     _;
     modifier txExists(uint _txIndex) {
        require(_txIndex < withdraws.length, "tx does not exist");
        _;
    }

    
    modifier notExecuted(uint _txIndex) {
        require(!withdraws[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }
    modifier onlySigner() {
        require(msg.sender == signingAddress, "Caller is not signer");
        _;
    }
    event Deposit(uint amount, address planetAddress);
    event OneTimeWithdraw(uint amount, address outAddress);
    event WithdrawExecuted(uint amount, address planetAddress, address outAddress);
    event AddWhitelistAccess(address newAddress);
    event RemoveWhitelistAccess(address removeAddress);
    event ConfirmWithdraw(address indexed requester, uint indexed txIndex);
    event SubmitWithdraw(
        address indexed requester,
        uint indexed txIndex,
        address indexed to,
        uint value,
        address planetAddress);
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
    constructor(address _usdcToken, uint _maxTries, address _signingAddress) Ownable() {
        usdcToken = USDCToken(_usdcToken);
        maxTries = _maxTries;
        currentTry = 0;
        oneTimeWithdrawBalance = 150000;
        signingAddress = _signingAddress;
    }

    function deposit(uint _amount, address _planetAddress) public {
        require(whitelistedForWithdraw[msg.sender] == true, "Address is not whitelisted");
        planetUSDC[_planetAddress] = planetUSDC[_planetAddress] + _amount;
        balanceToWithdraw = balanceToWithdraw + _amount;
        emit Deposit(_amount, _planetAddress);
    }
    function requestWithdraw(uint _amount, address _planetAddress, address _outAddress) public payable {
        require(whitelistedForWithdraw[msg.sender] == true || owner() == _msgSender(), "Caller is not owner neither a whitelisted contract");
        require(planetUSDC[_planetAddress] >= _amount, "Not enough balance for this planet.");
        uint txIndex = withdraws.length;
        withdraws.push(
            Withdraw({
                planetAddress: _planetAddress,
                outAddress: _outAddress,
                value: _amount,
                executed: false,
                numConfirmations: 0
            })
        );
        emit SubmitWithdraw(msg.sender, txIndex, _outAddress, _amount, _planetAddress);
    }
    function confirmWithdraw(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Withdraw storage withdraw = withdraws[_txIndex];
        withdraw.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;
        emit ConfirmWithdraw(msg.sender, _txIndex);
    }
    
    function withdrawExecute(uint _txIndex) internal {
        Withdraw storage withdraw = withdraws[_txIndex];
        require(planetUSDC[withdraw.planetAddress] >= withdraw.value, "Not enough balance for this planet.");
        usdcToken.transfer(withdraw.outAddress, withdraw.value);
        planetUSDC[withdraw.planetAddress] = planetUSDC[withdraw.planetAddress] - withdraw.value;
        balanceToWithdraw - withdraw.value;
        withdraw.executed = true;
        emit WithdrawExecuted(withdraw.value, withdraw.planetAddress, withdraw.outAddress);
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
    function changeSigningAddress(address _newAddress) onlyOwner public {
        signingAddress = _newAddress;
    }
}
