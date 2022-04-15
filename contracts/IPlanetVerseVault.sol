pragma solidity ^0.8.0;

interface IPlanetVerseVault {
    
    function stakeApy(address fractionAddress, uint assetId) external;
    function stakeTerraform() external;
    function unstakeApy() external;
    function unstakeTerraform() external;
    function checkStakedBalance() external;
    function vote() external;
    function checkStakedBalanceOfSpecificAddress() external;
     

}