pragma solidity ^0.8.10;


contract collectiverseSettings {

    address public stakingForApyAddress;
    address public stakingForTerraformAddress;
    address public votingAddress;



    constructor(address _stakingForApyAddress, address _stakingForTerraformAddress, address _votingAddress) {
        stakingForApyAddress = _stakingForApyAddress;
        stakingForTerraformAddress = _stakingForTerraformAddress;
        votingAddress = _votingAddress;
    }

    function changeStakingForApyAddress(address _newAddress) public {
        stakingForApyAddress = _newAddress;
    }
    function changeStakingForTerraformAddress(address _newAddress) public {
        stakingForTerraformAddress = _newAddress;
    }
    function changeVotingAddress(address _newAddress) public {
        votingAddress = _newAddress;
    }

}
