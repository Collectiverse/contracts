pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "https://github.com/0xcert/ethereum-erc721/src/contracts/tokens/nf-token-metadata.sol";

interface ICollectiverseSettings {
    function stakingForApyAddress() external view returns (address);
    function stakingForTerraformAddress() external view returns (address);
    function votingAddress() external view returns (address);
    function adminAddress() external view returns (address);
    function whitelistedForUserVault(address) external view returns (bool);
}



contract UserVault is ERC1155Holder, NFTokenMetadata, Ownable {
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
    event StakeForApyCreated(uint indexed txIndex);
    event StakeForTerraformCreated(uint indexed txIndex);
    event RenounceOwnerCreated(uint indexed txIndex);
    address public collectiverseSettingsAddress;
    address public owner;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired = 1;

    struct Transaction {
        bool typeTransaction; // Transaction will be False if it is an internal trnasaction that requires signs like a Shange in ownership. It will be True if it is an external transaction
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

        address admin = getAdminAddress();
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

    constructor(address _owner, address _collectiverseSettings) {
        owner = _owner;
        isOwner[_owner] = true;
        collectiverseSettingsAddress = _collectiverseSettings;
        nftName = "NONE";
        nftSymbol = "NONE";
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
    function mint(address _to, uint256 _tokenId, string calldata _uri) external onlyOwner {
        super._mint(_to, _tokenId);
        super._setTokenUri(_tokenId, _uri);
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
            // Check if the address is allowed to be called
            require(ICollectiverseSettings(collectiverseSettingsAddress).whitelistedForUserVault(transaction.to), "Not whitelisted");
            (bool success, ) = transaction.to.call{value: transaction.value}(
                transaction.data
            );
            require(success, "tx failed");
            transaction.executed = true;
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
    } //This function is there incase someone sends somethin wrong we'll be able to 

    function getstakeForApyAddress() private view  returns (address)  {
        return ICollectiverseSettings(collectiverseSettingsAddress).stakingForApyAddress();
    }

    function getstakeForTerraformAddress() private view returns (address)  {
        return ICollectiverseSettings(collectiverseSettingsAddress).stakingForTerraformAddress();
    }
    
    function getVotingAddress() private view returns (address)  {
        return ICollectiverseSettings(collectiverseSettingsAddress).votingAddress();
    }
    function getAdminAddress() private view returns (address)  {
        return ICollectiverseSettings(collectiverseSettingsAddress).adminAddress();
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
    emit SubmitTransaction(msg.sender, txIndex, 0x0000000000000000000000000000000000000000, 0, "_data");
    emit RenounceOwnerCreated(txIndex);
    }


    function withdrawERC1155(address _token, uint256 _tokenId, uint256 _amount) external onlyOwner {
        IERC1155(_token).safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "0");
        emit WithdrawERC1155(_token, _tokenId, _amount, msg.sender);
    }

}
