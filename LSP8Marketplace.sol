// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import {ILSP8IdentifiableDigitalAsset} from "https://github.com/lukso-network/lsp-smart-contracts/blob/develop/contracts/LSP8IdentifiableDigitalAsset/ILSP8IdentifiableDigitalAsset.sol";
import {LSP8MarketplaceStorage} from "./LSP8MarketplaceStorage.sol";
import {ILSP7DigitalAsset} from "https://github.com/lukso-network/lsp-smart-contracts/blob/develop/contracts/LSP7DigitalAsset/ILSP7DigitalAsset.sol";

/**
 * @title FamilyClothingLSP8Marketplace contract
 * @author Afteni Daniel (aka B00ste)
 */

contract LSP8Marketplace is LSP8MarketplaceStorage {

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
        senderOwnsLSP8(LSP8Address, tokenId)
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
        senderOwnsLSP8(LSP8Address, tokenId)
        LSP8OnSale(LSP8Address, tokenId)
    {
        _removeLSP8SaleAndPrice(LSP8Address, tokenId);
    }

    //Change LYX price.
    function changeLYXPrice (
        address LSP8Address,
        bytes32 tokenId,
        uint256 LYXAmount
    )
        public
        senderOwnsLSP8(LSP8Address, tokenId)
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
        senderOwnsLSP8(LSP8Address, tokenId)
        LSP8OnSale(LSP8Address, tokenId)
        LSP7PriceDoesNotExist(LSP8Address, tokenId, LSP7Address)
    {
        _removeLSP8PriceByAddress(LSP8Address, tokenId, LSP7Address);
        _addLYXPrice(LSP8Address, tokenId, LYXAmount);
    }

    //Add LSP7 price.
    function addLSP7Price (
        address LSP8Address,
        bytes32 tokenId,
        address LSP7Address,
        uint256 LSP7Amount
    )
        public
        senderOwnsLSP8(LSP8Address, tokenId)
        LSP8OnSale(LSP8Address, tokenId)
        LSP7PriceDoesExist(LSP8Address, tokenId, LSP7Address)
    {
        _addLYXPrice(LSP8Address, tokenId, LYXAmount);
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
        uint price = _returnLYXPrice(LSP8Address, tokenId);
        
        {        
            _removeLSP8SaleAndPrice(LSP8Address, tokenId);
        }

        {
            ILSP8IdentifiableDigitalAsset(LSP8Address)
            .transfer(
                LSP8Owner,
                msg.sender,
                tokenId,
                false,
                _returnLSPTransferData(LSP8Owner, msg.sender, 1)
            );
        }

        {
            LSP8Owner.transfer(price);
        }
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
        uint256 price = _returnLSP7PriceByAddress(LSP8Address, tokenId, LSP7Address);

        {
            _removeLSP8SaleAndPrice(LSP8Address, tokenId);
        }
        
        {
            ILSP7DigitalAsset(LSP7Address).authorizeOperator(address(this), price);
            ILSP7DigitalAsset(LSP7Address)
            .transfer(
                msg.sender,
                LSP8Owner,
                price,
                false,
                _returnLSPTransferData(LSP8Owner, msg.sender, 1)
            );
        }

        {
            ILSP8IdentifiableDigitalAsset(LSP8Address)
            .transfer(
                LSP8Owner,
                msg.sender,
                tokenId,
                false,
                _returnLSPTransferData(LSP8Owner, msg.sender, 1)
            );
        }
    }
    
}