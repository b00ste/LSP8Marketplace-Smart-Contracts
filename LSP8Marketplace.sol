// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import {ILSP8IdentifiableDigitalAsset} from "https://github.com/lukso-network/lsp-smart-contracts/blob/develop/contracts/LSP8IdentifiableDigitalAsset/ILSP8IdentifiableDigitalAsset.sol";
import {LSP8MarketplacePrice} from "./LSP8MarketplacePrice.sol";
import {LSP8MarketplaceTrade} from "./LSP8MarketplaceTrade.sol";
import {LSP8MarketplaceOffer} from "./LSP8MarketplaceOffer.sol";

/**
 * @title LSP8Marketplace contract
 * @author Afteni Daniel (aka B00ste)
 */

contract LSP8Marketplace is LSP8MarketplacePrice, LSP8MarketplaceOffer, LSP8MarketplaceTrade {

    // --- User Functionality.

    // Put LSP8 on sale.
    function putLSP8OnSale (
        address LSP8Address,
        bytes32 tokenId,
        uint256 LYXAmount,
        address[] memory LSP7Address,
        uint256[] memory LSP7Amount
    )
        public
        ownsLSP8(LSP8Address, tokenId)
        LSP8NotOnSale(LSP8Address, tokenId)
    {
        _addLYXPrice(LSP8Address, tokenId, LYXAmount);
        _addLSP7Prices(LSP8Address, tokenId, LSP7Address, LSP7Amount);
        _addLSP8Sale(LSP8Address, tokenId);
    }

    // Remove LSP8 sale. Also removes all the prices for an LSP8.
    function removeLSP8FromSale (
        address LSP8Address,
        bytes32 tokenId
    )
        public
        ownsLSP8(LSP8Address, tokenId)
        LSP8OnSale(LSP8Address, tokenId)
    {
        _removeLSP8Offers(LSP8Address, tokenId);
        _removeLSP8Prices(LSP8Address, tokenId);
        _removeLSP8Sale(LSP8Address, tokenId);
    }

    //Change LYX price.
    function changeLYXPrice (
        address LSP8Address,
        bytes32 tokenId,
        uint256 LYXAmount
    )
        public
        ownsLSP8(LSP8Address, tokenId)
        LSP8OnSale(LSP8Address, tokenId)
    {
        _removeLYXPrice(LSP8Address, tokenId);
        _addLYXPrice(LSP8Address, tokenId, LYXAmount);
    }

    //Change LSP7 price.
    function changeLSP7Price (
        address LSP8Address,
        bytes32 tokenId,
        address LSP7Address,
        uint256 LSP7Amount
    )
        public
        ownsLSP8(LSP8Address, tokenId)
        LSP8OnSale(LSP8Address, tokenId)
        LSP7PriceDoesNotExist(LSP8Address, tokenId, LSP7Address)
    {
        _removeLSP8PriceByAddress(LSP8Address, tokenId, LSP7Address);
        _addLYXPrice(LSP8Address, tokenId, LSP7Amount);
    }

    //Add LSP7 price.
    function addLSP7Price (
        address LSP8Address,
        bytes32 tokenId,
        address LSP7Address,
        uint256 LSP7Amount
    )
        public
        ownsLSP8(LSP8Address, tokenId)
        LSP8OnSale(LSP8Address, tokenId)
        LSP7PriceDoesExist(LSP8Address, tokenId, LSP7Address)
    {
        _addLYXPrice(LSP8Address, tokenId, LSP7Amount);
    }

    // Buy LSP8 with LYX.
    function buyLSP8WithLYX (
        address LSP8Address,
        bytes32 tokenId
    )
        public
        payable
        sendEnoughLYX(LSP8Address, tokenId)
        LSP8OnSale(LSP8Address, tokenId)
    {
        address payable LSP8Owner = payable(ILSP8IdentifiableDigitalAsset(LSP8Address).tokenOwnerOf(tokenId));
        uint amount = _returnLYXPrice(LSP8Address, tokenId);
        
        _removeLSP8Offers(LSP8Address, tokenId);
        _removeLSP8Prices(LSP8Address, tokenId);
        _removeLSP8Sale(LSP8Address, tokenId);
        _transferLSP8(LSP8Address, LSP8Owner, msg.sender, tokenId, false, 1);
        LSP8Owner.transfer(amount);
    }

    // Buy LSP8 with LSP7.
    function buyLSP8WithLSP7 (
        address LSP8Address,
        bytes32 tokenId,
        address LSP7Address
    )
        public
        haveEnoughLSP7Balance(LSP8Address, tokenId, LSP7Address)
        sellerAcceptsToken(LSP8Address, tokenId, LSP7Address)
        LSP8OnSale(LSP8Address, tokenId)
    {
        address LSP8Owner = ILSP8IdentifiableDigitalAsset(LSP8Address).tokenOwnerOf(tokenId);
        uint256 amount = _returnLSP7PriceByAddress(LSP8Address, tokenId, LSP7Address);
 
        _removeLSP8Offers(LSP8Address, tokenId);
        _removeLSP8Prices(LSP8Address, tokenId);
        _removeLSP8Sale(LSP8Address, tokenId);
        _transferLSP7(LSP7Address, msg.sender, LSP8Owner, amount, false);
        _transferLSP8(LSP8Address, LSP8Owner, msg.sender, tokenId, false, 1);
    }

    // Offer an LSP8 for an LSP8.
    function offerLSP8ForLSP8 (
        address LSP8Address,
        bytes32 tokenId,
        address offerLSP8Address,
        bytes32 offerTokenId
    )
        public
        LSP8OnSale(LSP8Address, tokenId)
        ownsLSP8(offerLSP8Address, offerTokenId)
        offerDoesNotExist(offerLSP8Address, offerTokenId)
    {
        _makeLSP8Offer(LSP8Address, tokenId, offerLSP8Address, offerTokenId);
    }

    // Remove an LSP8 offer for LSP8.
    function removeLSP8OfferForLSP8 (
        address LSP8Address,
        bytes32 tokenId,
        address offerLSP8Address,
        bytes32 offerTokenId
    )
        public
        LSP8OnSale(LSP8Address, tokenId)
        ownsLSP8(offerLSP8Address, offerTokenId)
        offerExists(offerLSP8Address, offerTokenId)
    {
        _removeLSP8Offer(LSP8Address, tokenId, offerLSP8Address, offerTokenId);
    }

    // Accept an LSP8 offer for LSP8.
    function acceptLSP8OfferForLSP8 (
        address LSP8Address,
        bytes32 tokenId,
        address offerLSP8Address,
        bytes32 offerTokenId
    )
        public
        LSP8OnSale(LSP8Address, tokenId)
        ownsLSP8(LSP8Address, tokenId)
        offerExistsForThisLSP8(LSP8Address, tokenId, offerLSP8Address, offerTokenId)
    {
        address offerLSP8Owner = ILSP8IdentifiableDigitalAsset(offerLSP8Address).tokenOwnerOf(offerTokenId);

        _removeLSP8Offers(LSP8Address, tokenId);
        _removeLSP8Prices(LSP8Address, tokenId);
        _removeLSP8Sale(LSP8Address, tokenId);
        _transferLSP8(LSP8Address, msg.sender, offerLSP8Owner, tokenId, false, 1);
        _transferLSP8(offerLSP8Address, offerLSP8Owner, msg.sender, offerTokenId, false, 1);
    }
    
}