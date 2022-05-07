// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

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

    // --- LSP8 Offer functionality.

    // Create an offer to trade LSP8 for LSP8
    function _makeOffer (
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
    }

    // Remove an trade offer from an LSP8.
    function _removeOffer (
        address LSP8Address,
        bytes32 tokenId,
        address offerLSP8Address
    )
        internal
    {
        _offers[LSP8Address][tokenId].LSP8Addresses.remove(offerLSP8Address);
        _offers[LSP8Address][tokenId].LSP8TokenIds.remove(offerLSP8Address);
    }

    /**
     * Return all offers. You will get 2 arrays.
     * First array will return all offerLSP8Addresses.
     * Second array will return all offerLSP8TokenIds.
     * The arrays are ordered.
     */
    function _returnOffers (
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