// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces/ICollectiverseSettings.sol";
import "./Interfaces/ICollectiversePlanet.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;

    function approve(address, uint256) external returns (bool);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function balanceOf(address) external view returns (uint256);
}

contract PlanetVault is ERC721Holder, ERC1155Holder {
    using EnumerableSet for EnumerableSet.UintSet;
    string public version = "1.0";

    /// @notice weth address
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// -------------------------------------
    /// -------- AUCTION INFORMATION --------
    /// -------------------------------------

    /// @notice the unix timestamp end time of the token auction
    uint256 public auctionEnd;
    /// @notice the length of auctions
    uint256 public constant LENGTH = 2 days;
    /// @notice the current price of the token during an auction
    uint256 public livePrice;
    /// @notice the current user winning the token auction
    address public winning;

    enum State {
        inactive,
        live,
        ended,
        redeemed
    }
    State public auctionState;

    

    /// -----------------------------------
    /// -------- VAULT INFORMATION --------
    /// -----------------------------------

    bool initialized = false;
    /// @notice the governance contract which gets paid in ETH
    address public immutable settings;
    address public immutable curator;
    address public immutable planet;
    uint256 public constant FRACTIONS_ID = 0;
    uint256 public constant PLANET_ID = 1;

    // set of prices with over 1% voting for it
    EnumerableSet.UintSet prices;
    // all prices and the number voting for them
    mapping(uint256 => uint256) public priceToCount;
    // each users price
    mapping(address => uint256) public userPrices;

    /// ------------------------
    /// -------- EVENTS --------
    /// ------------------------

    event Redeem(address indexed redeemer);
    event Bid(address indexed buyer, uint256 price);
    event Won(address indexed buyer, uint256 price);
    event Start(address indexed buyer, uint256 price);
    event Cash(address indexed owner, uint256 shares);
    event PriceUpdate(address indexed user, uint256 price);
    event WithdrawETH(address indexed to);
    event WithdrawERC20(address indexed token, address indexed to);
    event WithdrawERC721(
        address indexed token,
        uint256 tokenId,
        address indexed to
    );
    event WithdrawERC1155(
        address indexed token,
        uint256 tokenId,
        uint256 amount,
        address indexed to
    );

    constructor(
        address _planet,
        address _curator,
        address _settings
    ) {
        settings = _settings;
        planet = _planet;
        curator = _curator;
    }

    function token() external view returns (address) {
        return planet;
    }

    function isLivePrice(uint256 _price) external view returns (bool) {
        return prices.contains(_price);
    }

    function updateUserPrice(uint256 _new) external {
        uint256 balance = ICollectiversePlanet(planet).balanceOf(
            msg.sender,
            FRACTIONS_ID
        );

        _addToPrice(balance, _new);
        _removeFromPrice(balance, userPrices[msg.sender]);

        userPrices[msg.sender] = _new;

        emit PriceUpdate(msg.sender, _new);
    }

    function onTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external {
        require(msg.sender == planet, "not allowed");

        // we are burning
        if (_to == address(0)) {
            _removeFromPrice(_amount, userPrices[_from]);
            // we are minting
        } else if (_from == address(0)) {
            _addToPrice(_amount, userPrices[_to]);
        } else {
            _removeFromPrice(_amount, userPrices[_from]);
            _addToPrice(_amount, userPrices[_to]);
        }
    }

    // add to a price count
    // add price to reserve calc if 1% are voting for it
    function _addToPrice(uint256 _amount, uint256 _price) internal {
        priceToCount[_price] += _amount;
        if (
            priceToCount[_price] * 100 >=
            ICollectiversePlanet(planet).totalSupply(FRACTIONS_ID) &&
            !prices.contains(_price)
        ) {
            prices.add(_price);
        }
    }

    // remove a price count
    // remove price from reserve calc if less than 1% are voting for it
    function _removeFromPrice(uint256 _amount, uint256 _price) internal {
        priceToCount[_price] -= _amount;
        if (
            priceToCount[_price] * 100 <
            ICollectiversePlanet(planet).totalSupply(FRACTIONS_ID) &&
            prices.contains(_price)
        ) {
            prices.remove(_price);
        }
    }

    function swap(
        uint256[] memory array,
        uint256 i,
        uint256 j
    ) internal pure {
        (array[i], array[j]) = (array[j], array[i]);
    }

    function sort(
        uint256[] memory array,
        uint256 begin,
        uint256 last
    ) internal pure {
        if (begin < last) {
            uint256 j = begin;
            uint256 pivot = array[j];
            for (uint256 i = begin + 1; i < last; ++i) {
                if (array[i] < pivot) {
                    swap(array, i, ++j);
                }
            }
            swap(array, begin, j);
            sort(array, begin, j);
            sort(array, j + 1, last);
        }
    }

    function reservePrice()
        public
        view
        returns (uint256 voting, uint256 reserve)
    {
        uint256[] memory tempPrices = prices.values();
        sort(tempPrices, 0, tempPrices.length);
        voting = 0;
        for (uint256 x = 0; x < tempPrices.length; x++) {
            if (tempPrices[x] != 0) {
                voting += priceToCount[tempPrices[x]];
            }
        }

        uint256 count = 0;
        for (uint256 y = 0; y < tempPrices.length; y++) {
            if (tempPrices[y] != 0) {
                count += priceToCount[tempPrices[y]];
            }
            if (count * 2 >= voting) {
                reserve = tempPrices[y];
                break;
            }
        }
    }

    /// @notice kick off an auction. Must send reservePrice in ETH
    function start() external payable {
        require(auctionState == State.inactive, "start:no auction starts");
        (uint256 voting, uint256 reserve) = reservePrice();
        require(msg.value >= reserve, "start:too low bid");
        require(
            voting * 2 >= ICollectiversePlanet(planet).totalSupply(FRACTIONS_ID),
            "start:not enough voters"
        );

        auctionEnd = block.timestamp + LENGTH;
        auctionState = State.live;
        livePrice = msg.value;
        winning = msg.sender;
        emit Start(msg.sender, msg.value);
    }

    /// @notice an external function to bid on purchasing the vaults NFT. The msg.value is the bid amount
    function bid() external payable {
        require(auctionState == State.live, "bid:auction is not live");
        require(msg.value * 100 >= livePrice * 105, "bid:too low bid");
        require(block.timestamp < auctionEnd, "bid:auction ended");

        if (auctionEnd - block.timestamp <= 15 minutes) {
            auctionEnd += 15 minutes;
        }
        _sendETHOrWETH(winning, livePrice);
        livePrice = msg.value;
        winning = msg.sender;
        emit Bid(msg.sender, msg.value);
    }

    /// @notice an external function to end an auction after the timer has run out
    function end() external {
        require(auctionState == State.live, "end:vault has already closed");
        require(block.timestamp >= auctionEnd, "end:auction live");

        ICollectiversePlanet(planet).safeTransferFrom(address(this), winning, PLANET_ID, 1, "0x0");
        auctionState = State.ended;

        if (ICollectiverseSettings(settings).feeReceiver() != address(0)) {
            _sendETHOrWETH(ICollectiverseSettings(settings).feeReceiver(), livePrice / 40);
        }

        emit Won(winning, livePrice);
    }

    /// @notice an external function to burn all ERC20 tokens to receive the ERC721 token
    function redeem() external {
        require(auctionState == State.inactive, "redeem:no redeeming");

        ICollectiversePlanet(planet).burn(
            msg.sender,
            FRACTIONS_ID,
            ICollectiversePlanet(planet).totalSupply(FRACTIONS_ID)
        );
        ICollectiversePlanet(planet).safeTransferFrom(
            address(this),
            msg.sender,
            PLANET_ID,
            1,
            "0x0"
        );

        auctionState = State.redeemed;
        winning = msg.sender;
        emit Redeem(msg.sender);
    }

    /// @notice an external function to burn ERC20 tokens to receive ETH from ERC721 token purchase
    function cash() external {
        require(auctionState == State.ended, "cash:vault not closed yet");
        uint256 bal = ICollectiversePlanet(planet).balanceOf(msg.sender, FRACTIONS_ID);
        require(bal > 0, "cash:no tokens to cash out");
        uint256 share = (bal * address(this).balance) /
            ICollectiversePlanet(planet).totalSupply(FRACTIONS_ID);

        ICollectiversePlanet(planet).burn(msg.sender, FRACTIONS_ID, bal);
        _sendETHOrWETH(msg.sender, share);
        emit Cash(msg.sender, share);
    }

    function _sendETHOrWETH(address to, uint256 value) internal {
        if (!_attemptETHTransfer(to, value)) {
            IWETH(weth).deposit{value: value}();
            IWETH(weth).transfer(to, value);
        }
    }

    function _attemptETHTransfer(address to, uint256 value)
        internal
        returns (bool)
    {
        (bool success, ) = to.call{value: value, gas: 30000}("");
        return success;
    }

    function withdrawPlanet(
        address _token,
        uint256 _tokenId,
        uint256 _amount
    ) external {
        require(
            auctionState == State.ended || auctionState == State.redeemed,
            "vault not closed yet"
        );
        require(msg.sender == winning, "withdraw:not allowed");
        ICollectiversePlanet(_token).safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId,
            _amount,
            "0"
        );
        emit WithdrawERC1155(_token, _tokenId, _amount, msg.sender);
    }

    function withdrawETH() external {
        require(auctionState == State.redeemed, "vault not closed yet");
        require(msg.sender == winning, "withdraw:not allowed");
        payable(msg.sender).transfer(address(this).balance);
        emit WithdrawETH(msg.sender);
    }

    function withdrawERC20(address _token) external {
        require(
            auctionState == State.ended || auctionState == State.redeemed,
            "vault not closed yet"
        );
        require(msg.sender == winning, "withdraw:not allowed");
        IERC20(_token).transfer(
            msg.sender,
            IERC20(_token).balanceOf(address(this))
        );
        emit WithdrawERC20(_token, msg.sender);
    }

    receive() external payable {}
}
