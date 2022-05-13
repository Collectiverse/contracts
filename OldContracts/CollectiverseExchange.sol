// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./OperatorRole.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CollectiverseExchange is OperatorRole, PausableUpgradeable {

    using ECDSAUpgradeable for bytes32;

    struct Offer {

        uint offerEnd;

        address buyer;

        //Artwork being Auctioned
        uint artwork;

        //Beneficiary
        address payable beneficiary;

        //offer amount
        uint amount;

        IERC721 ERC721;

        IERC20 ERC20;

        address ERC721ContractAddress;

        address ERC20ContractAddress;

        string status;
                
    }

    struct Sale {

        uint saleEnd;

        //Artwork being Selled
        uint artwork;

        //Beneficiary
        address payable beneficiary;

        //offer amount
        uint salePrice;

        IERC721 ERC721;

        IERC20 ERC20;

        address ERC721ContractAddress;

        address ERC20ContractAddress;

        string status;
                
    }

    mapping (string => Offer) Offers;
    mapping (string => Sale) Sales;

    mapping(address => uint) pendingOffersReturnsEth;
    mapping(address => uint) pendingOffersReturnsErc20;

    address payable public collectiverseWallet;

    struct Royalty {
        uint256 artistPercentage;
        uint256 galleryPercentage;
    }

    mapping(address => Royalty) Royalties;
    mapping(string => address) Artists;

    // Events that will be fired on changes.
    event HighestBidIncreased(string auction, address bidder, uint amount);
    event SaleMade(address seller, address buyer, uint artwork);
    event OfferAccepted(address seller, address buyer, uint artwork);
    event BuyNow(address buyer, uint amount);
    event NewSaleCreated(string saleId, uint artwork);
    event NewOfferCreated(string saleId, uint artwork);
    event NotTheContractOwner(address owner, address sender);
    event ContractIsPaused(bool paused);
    event ContractIsResumed(bool paused);

    /// Create a simple auction with `_biddingTime`
    /// seconds bidding time on behalf of the
    /// beneficiary address `_wallet`.
    function initialize (
        address _wallet
    ) public initializer
    {   
        __OperatorRole_init();
        __Pausable_init();

        collectiverseWallet = payable(_wallet);
    }

    /**
     * @dev Triggers smart contract to stopped state
     */
    function pause()
        public
        onlyOperator
    {
        _pause();
        emit ContractIsPaused(true);
    }

    /**
     * @dev Returns smart contract to normal state
     */
    function unpause()
        public
        onlyOperator
    {
        _unpause();
        emit ContractIsResumed(false);
    }

    function createOffer(string memory _id, uint _artwork, uint _amount, address _erc721ContractAddress, address _erc20ContractAddress, address _artist, uint256 _offerEnd, bool _isEth) public whenNotPaused payable {

        IERC721 ERC721 = IERC721(_erc721ContractAddress);
        address _owner = ERC721.ownerOf(_artwork);

        if (_isEth) {

            Offer memory offer = Offer({
                offerEnd: _offerEnd,
                buyer: msg.sender,
                artwork: _artwork,
                beneficiary: payable(_owner),
                amount: _amount,
                ERC721: ERC721,
                ERC20: IERC20(address(0x0)),
                ERC721ContractAddress: _erc721ContractAddress,
                ERC20ContractAddress: address(0x0),
                status: "active"
            });

            pendingOffersReturnsEth[msg.sender] += msg.value;

            Offers[_id] = offer;

        } else {
            
            Offer memory offer = Offer({
                offerEnd: _offerEnd,
                buyer: msg.sender,
                artwork: _artwork,
                beneficiary: payable(_owner),
                amount: _amount,
                ERC721: ERC721,
                ERC20: IERC20(_erc20ContractAddress),
                ERC721ContractAddress: _erc721ContractAddress,
                ERC20ContractAddress: _erc20ContractAddress,
                status: "active"
            });

            pendingOffersReturnsErc20[msg.sender] += msg.value;

            Offers[_id] = offer;

        }

        Artists[_id] = _artist;


        emit NewOfferCreated(_id, _artwork);

    }

    function createSale(string memory _id, uint _artwork, uint _price, address _erc721ContractAddress, address _erc20ContractAddress, address _artist, uint256 _saleEnd, bool _isEth) public whenNotPaused onlyOperator {

        IERC721 ERC721 = IERC721(_erc721ContractAddress);
        address _owner = ERC721.ownerOf(_artwork);
        
        if (_isEth) {
            Sale memory sale = Sale({
                saleEnd: _saleEnd,
                artwork: _artwork,
                beneficiary: payable(_owner),
                salePrice: _price,
                ERC721: ERC721,
                ERC20: IERC20(address(0x0)),
                ERC721ContractAddress: _erc721ContractAddress,
                ERC20ContractAddress: address(0x0),
                status: "active"
            });

            Sales[_id] = sale;
        } else {
            Sale memory sale = Sale({
                saleEnd: _saleEnd,
                artwork: _artwork,
                beneficiary: payable(_owner),
                salePrice: _price,
                ERC721: ERC721,
                ERC20: IERC20(_erc20ContractAddress),
                ERC721ContractAddress: _erc721ContractAddress,
                ERC20ContractAddress: _erc20ContractAddress,
                status: "active"
            });

            Sales[_id] = sale;
        }

        Artists[_id] = _artist;

        emit NewSaleCreated(_id, _artwork);

    }

    /*
    * Royalty[0x232323] - Artist % and Gallery %
    * Royalty[0x345345] - Artist % and Gallery %
    */
    function setRoyalty(address _artist, uint256 _artistPercentage, uint256 _galleryPercentage) public onlyOperator {
        Royalties[_artist] = Royalty({
            artistPercentage: _artistPercentage,
            galleryPercentage: _galleryPercentage
        });
    }

    function acceptOffer(string memory _offerId, uint _amount) public payable {

        Offer storage offer = Offers[_offerId];

        require(block.timestamp <= offer.offerEnd, "This offer has ended");

        //Require that the value sent is the buyNowPrice Set by the Owner/Benneficary
        require(_amount >= offer.amount, "The ammount is not corrrect");

        address payable _artist = payable(Artists[_offerId]);

        if (offer.ERC20ContractAddress != address(0)) {

            require(offer.ERC20.balanceOf(msg.sender) >= _amount, "Not enough funds");

            uint256 allowance = offer.ERC20.allowance(msg.sender, address(this));
            require(allowance == _amount, "Check the Token allowance");

            _finishAsErc20(offer.buyer, msg.sender, msg.value, offer.artwork, offer.ERC20, offer.ERC721, _artist);

        } else {

            require(_amount == msg.value, 'Impossible Action');
            _finishAsEth(offer.buyer, payable(msg.sender), msg.value, offer.artwork, offer.ERC721, _artist);
            
        }

        offer.status = "sold";
        Offers[_offerId] = offer;
        
        emit OfferAccepted(msg.sender, offer.buyer, offer.artwork);
    }

    function makeSale(string memory _saleId, uint _amount) public payable {

        Sale storage sale = Sales[_saleId];

        require(block.timestamp <= sale.saleEnd, "This offer has ended");

        //Require that the value sent is the buyNowPrice Set by the Owner/Benneficary
        require(_amount >= sale.salePrice, "The ammount is not corrrect");

        address payable _artist = payable(Artists[_saleId]);

        if (sale.ERC20ContractAddress != address(0)) {

            require(sale.ERC20.balanceOf(msg.sender) >= _amount, "Not enough funds");

            uint256 allowance = sale.ERC20.allowance(msg.sender, address(this));
            require(allowance == _amount, "Check the Token allowance");

            _finishAsErc20(msg.sender, sale.beneficiary, msg.value, sale.artwork, sale.ERC20, sale.ERC721, _artist);

        } else {

            require(_amount == msg.value, 'Impossible Action');
            _finishAsEth(msg.sender, sale.beneficiary, msg.value, sale.artwork, sale.ERC721, _artist);
            
            
        }

        sale.status = "sold";
        Sales[_saleId] = sale;
        
        emit SaleMade(sale.beneficiary, msg.sender, sale.artwork);
    }

    function _finishAsErc20(address _buyer, address _seller, uint _amount, uint _artwork, IERC20 _ERC20, IERC721 _ERC721, address _artist) internal {

        Royalty memory royalty = Royalties[_artist];

        (uint256 artistFee, uint256 galleryFee, uint256 total) = _calculateFees(_amount, royalty.artistPercentage, royalty.galleryPercentage);
        
        require(_ERC20.transferFrom(address(this), _seller, total), "The transaction was not approved");
        require(_ERC20.transferFrom(address(this), _artist, artistFee), "The transaction was not approved");
        require(_ERC20.transferFrom(address(this), collectiverseWallet, galleryFee), "The transaction was not approved");
        
        _ERC721.safeTransferFrom(_seller, _buyer, _artwork);

    }


    function _finishAsEth(address _buyer, address payable _seller, uint _amount, uint _artwork, IERC721 _ERC721, address payable _artist) internal {

        Royalty memory royalty = Royalties[_artist];

        (uint256 artistFee, uint256 galleryFee, uint256 total) = _calculateFees(_amount, royalty.artistPercentage, royalty.galleryPercentage);
        
        _seller.transfer(total);
        _artist.transfer(artistFee);
        collectiverseWallet.transfer(galleryFee);

        _ERC721.safeTransferFrom(_seller, _buyer, _artwork);

    }

     /// Withdraw a bid that was overbid.
    function withdraw(string memory _offer, bool _isEth) public whenNotPaused {
        
        Offer memory offer = Offers[_offer];

        require(_compareStrings(offer.status, 'canceled'), "The offer is still active or was done");

        uint amount = offer.amount;
        require(amount > 0, "The address has nothing left to withdraw");
        uint256 remainingReturns = 0;

        if (_isEth) {

            remainingReturns = pendingOffersReturnsEth[msg.sender] - amount;

            pendingOffersReturnsEth[msg.sender] = 0;
            address payable _sender = payable(msg.sender);
            _sender.transfer(amount);

            pendingOffersReturnsEth[msg.sender] = remainingReturns;


        } else {

            remainingReturns = pendingOffersReturnsErc20[msg.sender] - amount;

            pendingOffersReturnsErc20[msg.sender] = 0;
            offer.ERC20.transfer(msg.sender, amount);

            pendingOffersReturnsErc20[msg.sender] = remainingReturns;

        }
        
        
    }


    function _calculateFees(uint256 _highestBid, uint256 _artistPercentage, uint256 _galleryPercentage) internal pure returns (uint256, uint256, uint256) {
        uint256 artistFee = calculateFee(_highestBid, _artistPercentage);
        uint256 galleryFee = calculateFee(_highestBid, _galleryPercentage);
        uint256 totalFee = artistFee + galleryFee;
        uint256 beneficiaryTotal = _highestBid - totalFee;

        return (artistFee, galleryFee, beneficiaryTotal);

    }

    function getOfferInfo(string memory _offerId) public view returns (uint amount, address beneficiary, uint artwork) {

        Offer storage offer = Offers[_offerId];

        amount = offer.amount;
        beneficiary = offer.beneficiary;
        artwork = offer.artwork;
    }

    function getSaleInfo(string memory _saleId) public view returns (uint salePrice, address beneficiary, uint artwork) {

        Sale storage sale = Sales[_saleId];

        salePrice = sale.salePrice;
        beneficiary = sale.beneficiary;
        artwork = sale.artwork;
    }

    function calculateFee (uint256 _price, uint256 _fee) internal pure returns(uint) {
        return (_price * _fee)/100;
    }

    function canOperate() public view returns(bool) {
        return operators[_msgSender()];
    }

    function _compareStrings(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}