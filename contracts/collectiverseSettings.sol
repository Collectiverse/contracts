// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";

contract CollectiverseSettings {

    address public stakingForApyAddress;
    address public stakingForTerraformAddress;
    address public votingAddress;
    address public adminAddress;
    address public owner;
    bool public transferEnabled;
    /// @notice the address who receives auction fees
    address payable public feeReceiverAddress;
    
    /// @notice Max PlanetVerse Minting Hard Cap
    uint256 public mintHardCap = 25000;
    mapping(address => bool) public whitelistedForUserVault;
    mapping(address => bool) public isOwner;
    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }
    modifier onlyWhitelistedForUserVault() {
        require(whitelistedForUserVault[msg.sender], "not owner");
        _;
    }
    event UpdateMintHardCap(uint256 _old, uint256 _new);

    constructor(address _owner, address _stakingForApyAddress, address _stakingForTerraformAddress, address _votingAddress, address _adminAddress) {

        /* require(
            Address.isContract(_stakingForApyAddress) ||
                _stakingForApyAddress == address(0),
            "ou can only set 0x0 or a contract address as a new implementation"
        );
        require(
            Address.isContract(_stakingForTerraformAddress) ||
                _stakingForTerraformAddress == address(0),
            "ou can only set 0x0 or a contract address as a new implementation"
        );
        require(
            Address.isContract(_votingAddress) ||
                _votingAddress == address(0),
            "ou can only set 0x0 or a contract address as a new implementation"
        ); */
        feeReceiverAddress = payable(msg.sender);
        stakingForApyAddress = _stakingForApyAddress;
        stakingForTerraformAddress = _stakingForTerraformAddress;
        votingAddress = _votingAddress;
        adminAddress = _adminAddress;
        owner = _owner;
        isOwner[_owner] = true;
        transferEnabled = false;
    }

    function changeStakingForApyAddress(address _newAddress) public onlyOwner {
        require(
            Address.isContract(_newAddress) ||
                _newAddress == address(0),
            "You can only set 0x0 or a contract address as a new implementation"
        );
        stakingForApyAddress = _newAddress;
    }
    function changeStakingForTerraformAddress(address _newAddress) public onlyOwner {
        require(
            Address.isContract(_newAddress) ||
                _newAddress == address(0),
            "You can only set 0x0 or a contract address as a new implementation"
        );
        stakingForTerraformAddress = _newAddress;
    }
    function changeVotingAddress(address _newAddress) public onlyOwner {
        require(
            Address.isContract(_newAddress) ||
                _newAddress == address(0),
            "You can only set 0x0 or a contract address as a new implementation"
        );
        votingAddress = _newAddress;
    }
    function changeAdminAddress(address _newAddress) public onlyOwner {
        
        adminAddress = _newAddress;
    }

    function setMintHardCap(uint256 _new) external onlyOwner {
        require(_new < mintHardCap, "The new value cannot be lowe than the current Minting Cap");

        emit UpdateMintHardCap(mintHardCap, _new);

        mintHardCap = _new;
    }

    function getMintingHardCap() external view returns (uint256) {
        return mintHardCap;
    }

    function feeReceiver() external view returns (address) {
        return feeReceiverAddress;
    }
    function enableTransfers() external onlyOwner {
        transferEnabled = true;
    }
    function addwhitelistedForUserVault(address _newAddress) public onlyOwner {
        whitelistedForUserVault[_newAddress] = true;
    }
}
