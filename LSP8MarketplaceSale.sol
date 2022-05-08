// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import { ILSP8IdentifiableDigitalAsset } from "https://github.com/lukso-network/lsp-smart-contracts/blob/develop/contracts/LSP8IdentifiableDigitalAsset/ILSP8IdentifiableDigitalAsset.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title LSP8MarketplaceSale contract
 * @author Afteni Daniel (aka B00ste)
 */
 
contract LSP8MarketplaceSale {

    using EnumerableSet for EnumerableSet.Bytes32Set;

    // --- Storage.

    mapping (address => EnumerableSet.Bytes32Set) private _sale;

    // --- Modifiers.

    modifier ownsLSP8 (
        address LSP8Address,
        bytes32 tokenId
    ) {
        require(
            ILSP8IdentifiableDigitalAsset(LSP8Address).tokenOwnerOf(tokenId) == msg.sender,
            "Sender doesn't own this LSP8."
        );
        _;
    }

    modifier LSP8OnSale (
        address LSP8Address,
        bytes32 tokenId
    ) {
        require(
            _sale[LSP8Address].contains(tokenId),
            "LSP8 is not on sale."
        );
        _;
    }

    modifier LSP8NotOnSale (
        address LSP8Address,
        bytes32 tokenId
    ) {
        require(
            !_sale[LSP8Address].contains(tokenId),
            "LSP8 is on sale."
        );
        _;
    }

    // -- Sale functionality.

    // Create sale.
    function _addLSP8Sale (
        address LSP8Address,
        bytes32 tokenId
    )
        internal
    {
        _sale[LSP8Address].add(tokenId);
        ILSP8IdentifiableDigitalAsset(LSP8Address).authorizeOperator(address(this), tokenId);
    }

    // Remove sale.
    function _removeLSP8Sale (
        address LSP8Address,
        bytes32 tokenId
    )
        internal
    {
        _sale[LSP8Address].remove(tokenId);
        ILSP8IdentifiableDigitalAsset(LSP8Address).revokeOperator(address(this), tokenId);
    }

}