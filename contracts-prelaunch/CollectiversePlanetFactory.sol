// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CollectiversePlanet.sol";
import "./OperatorRole.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract VaultFactory is Ownable, ERC1155Holder, OperatorRole {
    string public version = "2.0";
    /// @notice the number of ERC721 vaults
    uint256 public vaultCount;

    /// @notice the mapping of vault number to vault contract
    mapping(uint256 => address) public vaults;

    uint256 public _nftId = 1;
    uint256 public _fractionsId = 2;

    event Mint(
        address vault,
        uint256 vaultId
    );

    /// @notice the function to mint a new vault
    /// @param _amount the amount of tokens to
    /// @return the ID of the vault
    function mint(
        string memory _planetName,
        string memory _ticker,
        uint256 _amount
    ) external onlyOperator returns (uint256) {
        //uint256 count = FERC1155(fnft).count() + 1;
        address planet = address(
            new CollectiversePlanet()
        );

        CollectiversePlanet(planet).initialize(_planetName, _ticker, _nftId, _fractionsId, _amount, msg.sender);

        emit Mint(vault, vaultCount);
        /* CollectiversePlanet(planet).safeTransferFrom(
            address(this),
            msg.sender,
            _fractionsId,
            _amount,
            bytes("0")
        ); */

        vaults[vaultCount] = planet;
        vaultCount++;

        return vaultCount - 1;
    }

}
