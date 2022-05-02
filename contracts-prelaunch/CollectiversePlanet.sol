// SPDX-License-Identifier: GOG
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./OperatorRole.sol";

interface IVault {
    function onTransfer(
        address,
        address,
        uint256
    ) external;
}

contract CollectiversePlanet is ERC1155Upgradeable, OperatorRole {
    using StringsUpgradeable for uint256;

    string public name;
    string public symbol;
    string private baseURI;

    mapping(uint256 => address) public idToVault;
    uint256 public count = 0;
    uint256 private _totalSupply;


    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;

    event NewPlanetMinted(uint256 newItemId, address _owner);
    event UpdatedURI(string uri);

    function initialize(
        string memory _metaDataUri,
        string memory _name,
        string memory _symbol,
        uint256 _startingSupply
    ) public initializer {
        name = _name;
        symbol = _symbol;
         _totalSupply = _startingSupply;

        __OperatorRole_init();
        __ERC1155_init(_metaDataUri);

    }

    function _mintPlanet(address _owner, string memory data)
        external
        onlyOperator
    {
        
        _mint(_owner, 0, 1, "0");
        emit NewPlanetMinted(0, _owner);
    }

    function _mintFractions(address vault, uint256 amount)
        external
        onlyOperator
        returns (uint256)
    {
        count++;
        idToVault[count] = vault;
        _mint(msg.sender, count, amount, "0");
        _totalSupply = amount;
        return count;
    }

    function updateBaseUri(string calldata base) external onlyOperator {
        baseURI = base;

        emit UpdatedURI(baseURI);
    }

    function uri(uint256 id) public view override returns (string memory) {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, id.toString()))
                : baseURI;
    }

    function burnFractions(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _burn(account, id, value);
        _totalSupply -= value;
    }

    function totalFractionsSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        require(ids.length == 1, "too long");
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        IVault(idToVault[ids[0]]).onTransfer(from, to, amounts[0]);
    }
}
