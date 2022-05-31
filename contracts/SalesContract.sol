// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CollectiverseRewards.sol";

interface VaultInfo {
    function vaults(uint256) external view returns (address);

    function hasVault(address) external view returns (bool);

    function getVaultId(address) external view returns (address);
}

contract SalesContract is Ownable, ERC1155Holder {
    using SafeERC20 for IERC20;

    // wallet where the profits go to
    address public wallet;
    address public royaltyWallet;
    // vault information
    address public vaults;
    // whitelist
    mapping(address => uint256) public whitelist;

    // royalty information (in basis points)
    uint256 public royalty;

    bool public useWhitelist;
    bool public useMaxAmount;
    bool public useDepositCall;

    // purchase limits
    mapping(address => uint256) public amounts;
    uint256 public maxAmount;

    // auctioned erc1155
    mapping(address => uint256) public planetPrices;
    uint256 public erc1155Id;

    // payment erc20
    address public erc20;

    constructor(
        address _wallet,
        address _vaults,
        uint256 _erc1155Id,
        address _erc20
    ) {
        wallet = _wallet;
        vaults = _vaults;
        erc1155Id = _erc1155Id; // 1 for fractions in our case
        erc20 = _erc20;
    }

    // main purchase function - potential for additional logic like whitelist
    function purchase(address _planet, uint256 _amount) external {
        address vault = VaultInfo(vaults).getVaultId(msg.sender);
        require(
            VaultInfo(vaults).hasVault(msg.sender),
            "You don't have a vault"
        );

        // check if address is whitelisted
        if (useWhitelist) {
            require(
                whitelist[msg.sender] > 0,
                "Address has not been whitelisted"
            );
        }

        uint256 totalPrice = planetPrices[_planet] * _amount;
        uint256 userBalance = IERC20(erc20).balanceOf(msg.sender);
        uint256 stock = IERC1155(_planet).balanceOf(address(this), erc1155Id);

        require(planetPrices[_planet] > 0, "Planet is unavailable");
        require(userBalance >= totalPrice, "Not enough funds");
        require(stock >= _amount, "Not enough fractions available");

        // check if user purchases below their purchase limit - disabled on maxAmount = 0
        if (useMaxAmount) {
            require(
                (amounts[msg.sender] + _amount) <=
                    (maxAmount * whitelist[msg.sender]),
                "You hit the purchase limit"
            );
        }

        // calls rewards contract to signal purchase
        if (useDepositCall) {
            CollectiverseRewards(wallet).deposit(totalPrice, wallet);
        }

        // price is in basis points
        uint256 normalPrice = (totalPrice * 10000) / (10000 - royalty);
        uint256 royaltyPrice = totalPrice - normalPrice;

        // transfers need further testing
        IERC20(erc20).safeTransferFrom(msg.sender, wallet, normalPrice);
        IERC20(erc20).safeTransferFrom(msg.sender, royaltyWallet, royaltyPrice);
        IERC1155(_planet).safeTransferFrom(
            address(this),
            vault,
            erc1155Id,
            _amount,
            ""
        );
    }

    // settings
    function setPrice(address _planet, uint256 _price) external onlyOwner {
        planetPrices[_planet] = _price;
    }

    function setPrices(address[] memory _planets, uint256 _price)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _planets.length; i++) {
            planetPrices[_planets[i]] = _price;
        }
    }

    function setRoyalty(
        address _royaltyWallet,
        uint256 _royalty,
        bool _useDepositCall
    ) external onlyOwner {
        royaltyWallet = _royaltyWallet;
        royalty = _royalty;
        useDepositCall = _useDepositCall;
    }

    function setSettings(
        bool _useWhitelist,
        bool _useMaxAmount,
        uint256 _maxAmount
    ) external onlyOwner {
        useWhitelist = _useWhitelist;
        useMaxAmount = _useMaxAmount;
        maxAmount = _maxAmount;
    }

    // optional - to be used if planet doesn't sell or for migrations
    function withdrawERC1155(
        address _planet,
        uint256 _id,
        uint256 _amount
    ) external onlyOwner {
        IERC1155(_planet).safeTransferFrom(
            address(this),
            msg.sender,
            _id,
            _amount,
            ""
        );
    }

    function withdrawERC20(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransferFrom(address(this), msg.sender, _amount);
    }

    // whitelist addresses
    function _whitelistAddress(address _address, uint256 _rank)
        private
        returns (bool)
    {
        require(_address != address(0x0), "Zero Address: Not Allowed");
        whitelist[_address] = _rank;
        return true;
    }

    function whitelistAddresses(address[] memory _addresses, uint256 _rank)
        external
        onlyOwner
        returns (bool)
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            require(_whitelistAddress(_addresses[i], _rank));
        }
        return true;
    }
}
