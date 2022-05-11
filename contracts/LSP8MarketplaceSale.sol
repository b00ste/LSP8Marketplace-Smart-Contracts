// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import { ILSP8IdentifiableDigitalAsset } from "/home/b00ste/Projects/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/ILSP8IdentifiableDigitalAsset.sol";
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

    /**
     * Modifier checks if the sender owns the LSP8 that is to be put on sale.
     * 
     * @param LSP8Address The address of the LSP8.
     * @param tokenId Token id of the `LSP8Address` LSP8 that is about to be checked.
     *
     * @notice Once called the smart contract calls the `LSP8Address` smart contract's method `tokenOwnerOf` which returns the owner of the `tokenId`.
     */
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

    /**
     * Modifier checks if the LSP8 that is on sale.
     * 
     * @param LSP8Address The address of the LSP8.
     * @param tokenId Token id of the `LSP8Address` LSP8 that is about to be checked.
     *
     * @notice Once called the modifier checks if there is an `LSP8Address` that points to a `tokenId` in the storage.
     */
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

    /**
     * Modifier checks if the LSP8 that is not on sale.
     * 
     * @param LSP8Address The address of the LSP8.
     * @param tokenId Token id of the `LSP8Address` LSP8 that is about to be checked.
     *
     * @notice Once called the modifier checks if an `LSP8Address` that points to a `tokenId` doesn't exist in the storage.
     */
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

    // --- Sale functionality.

    /**
     * Put an LSP8 on sale.
     * 
     * @param LSP8Address The address of the LSP8.
     * @param tokenId Token id of the `LSP8Address` LSP8 that is to be put on sale.
     *
     * @notice Once this method is called it adds an `LSP8Address` that 
     * points to an array of token ids and adds `tokenId` to that array.
     * After that it calls the `LSP8Address` smart contract and uses the
     * `authorizeOperator` method to allow this smart contract to transfer
     * the LSP8 for the user, if the sale gets matched.
     */
    function _addLSP8Sale (
        address LSP8Address,
        bytes32 tokenId
    )
        internal
    {
        _sale[LSP8Address].add(tokenId);
        ILSP8IdentifiableDigitalAsset(LSP8Address).authorizeOperator(address(this), tokenId);
    }

    /**
     * Remove an LSP8 from sale.
     * 
     * @param LSP8Address The address of the LSP8.
     * @param tokenId Token id of the `LSP8Address` LSP8 that is to be removed from sale.
     *
     * @notice Once this method is called it removes from the `LSP8Address` that 
     * points to an array of token ids the `tokenId`.
     * After that it calls the `LSP8Address` smart contract and uses the
     * `revokeOperator` method to remove the allowence of this smart contract
     * to transfer the LSP8 for the user, if the sale gets matched.
     */
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