// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CollectiverseRewards is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public usdcToken;
    mapping(address => uint256) public planetUSDC; //First uint is the planet ID And the second mapping uint 0 = USDC amount and uint 1 =
    mapping(address => bool) public whitelistedForWithdraw;
    mapping(uint256 => mapping(address => bool)) public isConfirmed;
    address public signingAddress;
    uint256 public balanceToWithdraw;
    uint256 public maxTries;
    uint256 public currentTry;
    uint256 public oneTimeWithdrawBalance;
    uint256 public numConfirmationsRequired = 1;
    struct Withdraw {
        address planetAddress;
        address outAddress;
        uint256 value;
        bool executed;
        uint256 numConfirmations;
    }
    Withdraw[] public withdraws;
    // modifier isWhitelisted(address checkAddress) {
    //     require(whitelistedForWithdraw[checkAddress] == true, "Address is not whitelisted");
    //     _;
    modifier txExists(uint256 _txIndex) {
        require(_txIndex < withdraws.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!withdraws[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }
    modifier onlySigner() {
        require(msg.sender == signingAddress, "Caller is not signer");
        _;
    }
    event Deposit(uint256 amount, address planetAddress);
    event OneTimeWithdraw(uint256 amount, address outAddress);
    event WithdrawExecuted(
        uint256 amount,
        address planetAddress,
        address outAddress
    );
    event AddWhitelistAccess(address newAddress);
    event RemoveWhitelistAccess(address removeAddress);
    event ConfirmWithdraw(address indexed requester, uint256 indexed txIndex);
    event SubmitWithdraw(
        address indexed requester,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        address planetAddress
    );

    function addWhitelistAccess(address _newAddress) public onlyOwner {
        require(
            whitelistedForWithdraw[_newAddress] == false,
            "Already whitelisted for withdraws"
        );
        whitelistedForWithdraw[_newAddress] = true;
        emit AddWhitelistAccess(_newAddress);
    }

    function removeWhitelistAccess(address _removeAddress) public onlyOwner {
        require(
            whitelistedForWithdraw[_removeAddress] == true,
            "Not whitelisted for withdraws"
        );
        whitelistedForWithdraw[_removeAddress] = false;
        emit RemoveWhitelistAccess(_removeAddress);
    }

    constructor(
        address _usdcToken,
        uint256 _maxTries,
        address _signingAddress
    ) Ownable() {
        usdcToken = IERC20(_usdcToken);
        maxTries = _maxTries;
        currentTry = 0;
        oneTimeWithdrawBalance = 150000;
        signingAddress = _signingAddress;
    }

    function deposit(uint256 _amount, address _planetAddress) public {
        require(
            whitelistedForWithdraw[msg.sender] == true,
            "Address is not whitelisted"
        );
        planetUSDC[_planetAddress] = planetUSDC[_planetAddress] + _amount;
        balanceToWithdraw = balanceToWithdraw + _amount;
        emit Deposit(_amount, _planetAddress);
    }

    function requestWithdraw(
        uint256 _amount,
        address _planetAddress,
        address _outAddress
    ) public payable {
        require(
            whitelistedForWithdraw[msg.sender] == true ||
                owner() == _msgSender(),
            "Caller is not owner neither a whitelisted contract"
        );
        require(
            planetUSDC[_planetAddress] >= _amount,
            "Not enough balance for this planet."
        );
        uint256 txIndex = withdraws.length;
        withdraws.push(
            Withdraw({
                planetAddress: _planetAddress,
                outAddress: _outAddress,
                value: _amount,
                executed: false,
                numConfirmations: 0
            })
        );
        emit SubmitWithdraw(
            msg.sender,
            txIndex,
            _outAddress,
            _amount,
            _planetAddress
        );
    }

    function confirmWithdraw(uint256 _txIndex)
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

    function withdrawExecute(uint256 _txIndex) internal {
        Withdraw storage withdraw = withdraws[_txIndex];
        require(
            planetUSDC[withdraw.planetAddress] >= withdraw.value,
            "Not enough balance for this planet."
        );
        usdcToken.safeTransfer(withdraw.outAddress, withdraw.value);
        planetUSDC[withdraw.planetAddress] =
            planetUSDC[withdraw.planetAddress] -
            withdraw.value;
        balanceToWithdraw - withdraw.value;
        withdraw.executed = true;
        emit WithdrawExecuted(
            withdraw.value,
            withdraw.planetAddress,
            withdraw.outAddress
        );
    }

    function oneTimeWithdraw(uint256 _amount, address _outAddress)
        public
        payable
    {
        require(
            currentTry <= maxTries,
            "You have exceeded the maximum amount of tries"
        );
        require(
            whitelistedForWithdraw[msg.sender] == true ||
                owner() == _msgSender(),
            "Caller is not owner neither a whitelisted contract"
        );
        require(balanceToWithdraw >= _amount, "Not enough balance");
        require(
            _amount > oneTimeWithdrawBalance,
            "You have exceeded the max amount withdrawable"
        );
        usdcToken.safeTransfer(_outAddress, _amount);
        currentTry = currentTry + 1;
        oneTimeWithdrawBalance = oneTimeWithdrawBalance - _amount;
        emit OneTimeWithdraw(_amount, _outAddress);
    }

    function editMaxTries(uint256 _newMax) public onlyOwner {
        maxTries = _newMax;
    }

    function changeSigningAddress(address _newAddress) public onlyOwner {
        signingAddress = _newAddress;
    }
}
