// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
contract MultiSigWallet is ERC1155Holder {
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);
    event DepositERC1155(address indexed token, uint256 tokenId, uint256 amount, address indexed from);
    event DepositERC1155Bulk(address indexed token, uint256[] tokenId, uint256[] amount, address indexed from);
    event WithdrawERC1155(address indexed token, uint256 tokenId, uint256 amount, address indexed from);
    event stakeForApyCreated(uint indexed txIndex);
    event stakeForTerraformCreated(uint indexed txIndex);
    event renounceOwnerCreated(uint indexed txIndex);
    address public apyAddress;
    address public terraformAddress;
    address public votingAddress;
    address public owner;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;

    struct Transaction {
        bool typeTransaction; // Transaction will be False if it is an internal trnasaction that requires sigs like a Shange in ownership. It will be True if it is an external transaction
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }


    modifier onlyAdmin() {
        //fetch admin from the settings contract
        address admin = 0x0000dead;
        require(msg.sender == admin, "not admin");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    constructor(address _owner, uint[] memory _numConfirmationsRequired, address[] memory _stakingAddresses) {
        require(_numConfirmationsRequired.length == 0, "Invalid amount of confirmation parameters"); // HAVE TO DECIDE THIS AFTER
        for (uint i = 0; i < _numConfirmationsRequired.length; i++) {
            require(
                        _numConfirmationsRequired[i] > 0 &&
                            _numConfirmationsRequired[i] <= (1 + _numConfirmationsRequired.length),
                        "invalid number of required confirmations"
                    );
        }
        
        require(_stakingAddresses.length == 3, "Staking addresses and voting address required");
        apyAddress = _stakingAddresses[0];
        terraformAddress = _stakingAddresses[1];
        votingAddress = _stakingAddresses[2];
        owner = _owner;
        // Have to add all the different functions here. will give error untill we know all the possible functions
        numConfirmationsRequired = _numConfirmationsRequired;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
    
    function onERC1155Received(address, address from, uint256 id, uint256 amount, bytes memory) public virtual override returns (bytes4) {
        emit DepositERC1155(msg.sender, id, amount, from);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address from, uint256[] memory ids, uint256[] memory amounts, bytes memory) public virtual override returns (bytes4) {
        emit DepositERC1155Bulk(msg.sender, ids, amounts, from);
        return this.onERC1155BatchReceived.selector;
    }
    function submitTransaction(
        address _to,
        uint _value,
        bytes memory _data
    ) public onlyOwner {
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                typeTransaction: true,
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );
        if (transaction.typeTransaction == false) {
            owner = transaction.to; // If typeTransaction is false it means it was sent from the renounceOwnership function.
        } 
        else {
            transaction.executed = true;

            (bool success, ) = transaction.to.call{value: transaction.value}(
                transaction.data
            );
            require(success, "tx failed");

            emit ExecuteTransaction(msg.sender, _txIndex);
            }
        
    }

    function revokeConfirmation(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }


    function getBalance() public view onlyOwner returns (uint) {
        return address(this).balance;
    }
    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex)
        public
        view
        returns (
            address to,
            uint value,
            bytes memory data,
            bool executed,
            uint numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }
    
    function tranferERC20(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyAdmin {
        IERC20(_token).transfer(_to, _amount);
    }

    function stakeForTerraform() public onlyOwner {
        //Populate data bellow with info from the terraform contract
        uint txIndex = transactions.length;
        transactions.push(
            Transaction({
                typeTransaction: true,
                to: terraformAddress,
                value: "_value",
                data: "_data",
                executed: false,
                numConfirmations: 0
            })
        );
        emit SubmitTransaction(msg.sender, txIndex, terraformAddress, "_value", "_data");
        emit stakeForTerraformCreated(txIndex);
    }
    function stakeForApy() public onlyOwner {
        //Populate data bellow with info from the APY contract
        uint txIndex = transactions.length;
        transactions.push(
            Transaction({
                typeTransaction: true,
                to: apyAddress,
                value: "_value",
                data: "_data",
                executed: false,
                numConfirmations: 0
            })
        );
        emit SubmitTransaction(msg.sender, txIndex, apyAddress, "_value", "_data");
        emit stakeForApyCreated(txIndex);
    }
    function renounceOwner(address _newOwner) public onlyOwner {
        uint txIndex = transactions.length;
        transactions.push(
            Transaction({
            typeTransaction: false,
            to: address(_newOwner),
            value: 0,
            data: "0x",
            executed: false,
            numConfirmations: 0
        })
    );
    emit SubmitTransaction(msg.sender, txIndex, apyAddress, 0, "0x");
    emit renounceOwnerCreated(txIndex);
    
    }


    function withdrawERC1155(address _token, uint256 _tokenId, uint256 _amount) external onlyAdmin {
        IERC1155(_token).safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "0");
        emit WithdrawERC1155(_token, _tokenId, _amount, msg.sender);
    }

}
