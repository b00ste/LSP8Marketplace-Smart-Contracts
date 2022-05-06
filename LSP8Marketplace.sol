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

    // Create a user.
    function createUser () public {
        _addUser(msg.sender);
    }

    // Put LSP8 on sale.
    function putLSP8OnSale (
        address LSP8Address,
        bytes32 tokenId,
        uint256 LYXAmount,
        address[] memory LSP7Address,
        uint256[] memory LSP7Amount
    ) public {
        _addLYXPrice(LSP8Address, tokenId, LYXAmount);
        _addLSP7Price(LSP8Address, tokenId, LSP7Address, LSP7Amount);
        _addLSP8Sale(LSP8Address, tokenId);
        ILSP8IdentifiableDigitalAsset(LSP8Address).authorizeOperator(address(this), tokenId);
    }

    // Remove LSP8 sale. Also removes all the prices for an LSP8.
    function removeLSP8FromSale (
        address LSP8Address,
        bytes32 tokenId
    ) public {
        _removeLSP8SaleAndPrice(LSP8Address, tokenId);
        ILSP8IdentifiableDigitalAsset(LSP8Address).revokeOperator(address(this), tokenId);
    }

    // Buy LSP8 with LYX.
    function buyLSP8WithLYX (
        address LSP8Address,
        bytes32 tokenId
    ) public payable
        sendEnoughLYX(LSP8Address, tokenId)
    {
        address LSP8Owner = ILSP8IdentifiableDigitalAsset(LSP8Address).tokenOwnerOf(tokenId);
        address payable from = payable(LSP8Owner);
        address to = msg.sender;
        bool force = false;
        bytes memory data = abi.encodeWithSignature(
            "universalReceiver(bytes32 typeId, bytes memory data)",
            keccak256("TOKEN_RECEIVE"),
            abi.encodePacked(from, msg.sender, "1")
        );
        uint price = _returnLYXPrice(LSP8Address, tokenId);
        _removeLSP8SaleAndPrice(LSP8Address, tokenId);

        ILSP8IdentifiableDigitalAsset(LSP8Address)
        .transfer(from, to, tokenId, force, data);

        from.transfer(price);
    }

    // Buy LSP8 with LSP7.
    function buyLSP8WithLSP7 (
        address LSP8Address,
        bytes32 tokenId,
        address LSP7Address
    )
        public
        payable
        haveEnoughLSP7Balance(LSP8Address, tokenId, LSP7Address)
        sellerAcceptsToken(LSP8Address, tokenId, LSP7Address)
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