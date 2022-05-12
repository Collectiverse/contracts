// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IVault {
    function onTransfer(
        address,
        address,
        uint256
    ) external;
}

contract FERC1155 is ERC1155, Ownable {
    using Strings for uint256;

    string private baseURI;
    mapping(address => bool) public minters;
    mapping(uint256 => uint256) private _totalSupply;

    uint256 public count = 0;

    mapping(uint256 => address) public idToVault;

    constructor() ERC1155("") {}

    modifier onlyMinter() {
        require(minters[msg.sender]);
        _;
    }

    /// Owner Functions ///

    function addMinter(address minter) external onlyOwner {
        minters[minter] = true;
    }

    function removeMinter(address minter) external onlyOwner {
        minters[minter] = false;
    }

    function updateBaseUri(string calldata base) external onlyOwner {
        baseURI = base;
    }

    /// Minter Function ///

    function mint(address vault, uint256 amount)
        external
        onlyMinter
        returns (uint256)
    {
        count++;
        idToVault[count] = vault;
        _mint(msg.sender, count, amount, "0");
        _totalSupply[count] = amount;
        return count;
    }

    function mint(uint256 amount, uint256 id) external onlyMinter {
        require(id <= count, "doesn't exist");
        _mint(msg.sender, id, amount, "0");
        _totalSupply[count] += amount;
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _burn(account, id, value);
        _totalSupply[id] -= value;
    }

    /// Public Functions ///

    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    function uri(uint256 id) public view override returns (string memory) {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, id.toString()))
                : baseURI;
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
