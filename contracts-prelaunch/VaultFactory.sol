// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Vault.sol";
import "./FERC1155.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract VaultFactory is Ownable, ERC1155Holder {
    string public version = "2.0";
    /// @notice the number of ERC721 vaults
    uint256 public vaultCount;

    /// @notice the mapping of vault number to vault contract
    mapping(uint256 => address) public vaults;

    /// @notice a settings contract controlled by governance
    address public feeReceiver;
    /// @notice the fractional ERC1155 NFT contract
    address public immutable fnft;

    event Mint(
        address indexed token,
        uint256 id,
        uint256 fractionId,
        address vault,
        uint256 vaultId
    );

    constructor(address _fnft) {
        fnft = _fnft;
    }

    /// @notice the function to mint a new vault
    /// @param _token the ERC721 token address fo the NFT
    /// @param _id the uint256 ID of the token
    /// @param _amount the amount of tokens to
    /// @return the ID of the vault
    function mint(
        address _token,
        uint256 _id,
        uint256 _amount
    ) external returns (uint256) {
        uint256 count = FERC1155(fnft).count() + 1;
        address vault = address(
            new Vault(fnft, count, _token, _id, msg.sender)
        );
        uint256 fractionId = FERC1155(fnft).mint(vault, _amount);
        require(count == fractionId, "mismatch");

        emit Mint(_token, _id, fractionId, vault, vaultCount);
        IERC721(_token).safeTransferFrom(msg.sender, vault, _id);
        FERC1155(fnft).safeTransferFrom(
            address(this),
            msg.sender,
            fractionId,
            _amount,
            bytes("0")
        );

        vaults[vaultCount] = vault;
        vaultCount++;

        return vaultCount - 1;
    }

    function setFees(address _fees) external onlyOwner {
        feeReceiver = _fees;
    }
}
