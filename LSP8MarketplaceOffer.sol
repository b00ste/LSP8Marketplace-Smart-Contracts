// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import { ILSP8IdentifiableDigitalAsset } from "https://github.com/lukso-network/lsp-smart-contracts/blob/develop/contracts/LSP8IdentifiableDigitalAsset/ILSP8IdentifiableDigitalAsset.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { EnumerableMap } from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import { LSP8MarketplaceSale } from "./LSP8MarketplaceSale.sol";

/**
 * @title LSP8MarketplaceOffer contract
 * @author Afteni Daniel (aka B00ste)
 */
 
contract LSP8MarketplaceOffer is LSP8MarketplaceSale {

    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    // --- Storage

    mapping (address => mapping (bytes32 => Offers)) private _offers;
    struct Offers {
        EnumerableSet.AddressSet LSP8Addresses;
        EnumerableMap.AddressToUintMap LSP8TokenIds;
    }

    // --- Modifiers.

    modifier offerDoesNotExist (
        address offerLSP8Address, 
        bytes32 offerTokenId
    ) {
        require(
            !ILSP8IdentifiableDigitalAsset(offerLSP8Address).isOperatorFor(address(this), offerTokenId),
            "Offer already exists."
        ); _;
    }

    modifier offerExists (
        address offerLSP8Address, 
        bytes32 offerTokenId
    ) {
        require(
            ILSP8IdentifiableDigitalAsset(offerLSP8Address).isOperatorFor(address(this), offerTokenId),
            "Offer does not exist."
        ); _;
    }

    modifier offerExistsForThisLSP8 (
        address LSP8Address,
        bytes32 tokenId,
        address offerLSP8Address, 
        bytes32 offerTokenId
    ) {
        require(
            _offers[LSP8Address][tokenId].LSP8TokenIds.get(offerLSP8Address) == uint(offerTokenId),
            "Offer does not exist for this LSP8."
        ); _;
    }

    // --- LSP8 Offer functionality.

    // Create an offer to trade LSP8 for LSP8
    function _makeLSP8Offer (
        address LSP8Address,
        bytes32 tokenId,
        address offerLSP8Address,
        bytes32 offerTokenId
    )
        internal
    {
        Offers storage _offer = _offers[LSP8Address][tokenId];
        _offer.LSP8Addresses.add(offerLSP8Address);
        _offer.LSP8TokenIds.set(offerLSP8Address, uint(offerTokenId));
        ILSP8IdentifiableDigitalAsset(offerLSP8Address).authorizeOperator(address(this), offerTokenId);
    }

    // Remove an trade offer from an LSP8.
    function _removeLSP8Offer (
        address LSP8Address,
        bytes32 tokenId,
        address offerLSP8Address,
        bytes32 offerTokenId
    )
        internal
    {
        _offers[LSP8Address][tokenId].LSP8Addresses.remove(offerLSP8Address);
        _offers[LSP8Address][tokenId].LSP8TokenIds.remove(offerLSP8Address);
        ILSP8IdentifiableDigitalAsset(offerLSP8Address).revokeOperator(address(this), offerTokenId);
    }

    // Remove all offers.
    function _removeLSP8Offers (
        address LSP8Address,
        bytes32 tokenId
    )
        internal
    {
        delete _offers[LSP8Address][tokenId];
    }

    /**
     * Return all offers. You will get 2 arrays.
     * First array will return all offerLSP8Addresses.
     * Second array will return all offerLSP8TokenIds.
     * The arrays are ordered.
     */
    function _returnLSP8Offers (
        address LSP8Address,
        bytes32 tokenId
    )
        public
        view
        returns(address[] memory, bytes32[] memory)
    {
        Offers storage _offer = _offers[LSP8Address][tokenId];
        bytes32[] memory LSP8TokenIds;
        for (uint i = 0; i < _offer.LSP8Addresses.length(); i++) {
            LSP8TokenIds[i] = bytes32(_offer.LSP8TokenIds.get(_offer.LSP8Addresses.at(i)));
        }
        return (_offer.LSP8Addresses.values(), LSP8TokenIds);
    }

}