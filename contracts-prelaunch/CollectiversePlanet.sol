// SPDX-License-Identifier: GOG
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./OperatorRole.sol";

contract CollectiversePlanet is ERC1155Upgradeable, OperatorRole {
    string public name;
    string public symbol;

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;

    event NewPlanetMinted(uint256 newItemId, address _owner);
    event UpdatedURI(string uri);

    function initialize(
        string memory _metaDataUri,
        string memory _name,
        string memory _symbol,
        uint256 _amount,
        address _owner
    ) public initializer {
        name = _name;
        symbol = _symbol;

        __OperatorRole_init();
        __ERC1155_init(_metaDataUri);

        _mint(_owner, 0, 1, ""); // planet nft @0
        _mint(_owner, 1, _amount, ""); // fractions @1
    }

    // is this necessary?
    function authorizeAndMintMainArtwork(address _owner, uint256 _amount)
        public
        onlyOperator
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();

        emit NewPlanetMinted(newItemId, _owner);
    }

    function updateURI(string memory newURI) public onlyOperator {
        _setURI(newURI);

        emit UpdatedURI(newURI);
    }
}
