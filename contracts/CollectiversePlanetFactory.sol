// SPDX-License-Identifier: GOG
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./OperatorRole.sol";


contract CollectiversePlanetFactory is ERC1155Upgradeable, OperatorRole {

    string name_;
    string symbol_;

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;

    event NewPlanetMinted(uint newItemId, address _owner);
    event TokenUriUpdated(uint tokenId, string uri);

    function initialize(string memory _metaDataUri, string memory _planetName, string memory _ticker) public initializer {

        name_ = _planetName;
        symbol_ = _ticker;

        landNftMax_ = x;

        __OperatorRole_init();

        __ERC1155_init(_metaDataUri);
    }

    function authorizeAndMintMainArtwork(address _owner, uint256 _amount ) public onlyOperator {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();

        emit NewPlanetMinted(newItemId, _owner);
    }

    function updateTokenUri(uint _tokenId, string memory uri) public onlyOperator {
        _setTokenURI(_tokenId, uri);

        emit TokenUriUpdated(_tokenId, uri);
    }

}