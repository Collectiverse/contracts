pragma solidity ^0.8.0;

interface IPlanetVerseVault {
    
    function stakeApy(address fractionAddress, uint assetId, uint amount) external;
    function stakeTerraform(address terraformContract, ) external;
    function unstakeApy() external;
    function unstakeTerraform(address landNft, ) external;
    function checkStakedBalance() external;
    function vote() external;
    function checkStakedBalanceOfSpecificAddress() external;
     

}