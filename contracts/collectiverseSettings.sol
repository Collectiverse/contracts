pragma solidity ^0.8.10;
import "@openzeppelin/contracts/utils/Address.sol";

contract collectiverseSettings {

    address public stakingForApyAddress;
    address public stakingForTerraformAddress;
    address public votingAddress;
    address public adminAddress;
    address public owner;
    mapping(address => bool) public isOwner;
    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }
    constructor(address _owner, address _stakingForApyAddress, address _stakingForTerraformAddress, address _votingAddress, address _adminAddress) {

        require(
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
        );
        stakingForApyAddress = _stakingForApyAddress;
        stakingForTerraformAddress = _stakingForTerraformAddress;
        votingAddress = _votingAddress;
        adminAddress = _adminAddress;
        owner = _owner;
        isOwner[_owner] = true;
    }
    function changeStakingForApyAddress(address _newAddress) public onlyOwner {
        require(
            Address.isContract(_newAddress) ||
                _newAddress == address(0),
            "ou can only set 0x0 or a contract address as a new implementation"
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

}
