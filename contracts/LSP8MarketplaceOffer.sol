// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import { ILSP8IdentifiableDigitalAsset } from "/home/b00ste/Projects/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/ILSP8IdentifiableDigitalAsset.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { EnumerableMap } from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import { LSP8MarketplaceSale } from "./LSP8MarketplaceSale.sol";

/**
 * @title LSP8MarketplaceOffer contract
 * @author Afteni Daniel (aka B00ste)
 */
 
contract LSP8MarketplaceOffer is LSP8MarketplaceSale {

    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // --- Storage

    mapping (address => mapping (bytes32 => Offers)) private _offers;
    struct Offers {
        EnumerableSet.AddressSet LSP8Addresses;
        mapping (address => EnumerableSet.Bytes32Set) LSP8TokenIds;
    }

    // --- Modifiers.

    /**
     * Modifier checks if there are no offers with this LSP8.
     * 
     * @param offerLSP8Address The address of the LSP8.
     * @param offerTokenId Token id of the `LSP8Address` LSP8 that is about to be checked.
     *
     * @notice Once called the smart contract calls the `offerLSP8Address` smart contract's
     * method `isOperatorFor` which returns a boolean value. If there are no offers using this LSP8
     * the return falue must be false.
     */
    modifier offerDoesNotExist (
        address offerLSP8Address, 
        bytes32 offerTokenId
    ) {
        require(
            !ILSP8IdentifiableDigitalAsset(offerLSP8Address).isOperatorFor(address(this), offerTokenId),
            "Offer already exists."
        ); _;
    }

    /**
     * Modifier checks if there are offers with this LSP8.
     * 
     * @param offerLSP8Address The address of the LSP8.
     * @param offerTokenId Token id of the `LSP8Address` LSP8 that is about to be checked.
     *
     * @notice Once called the smart contract calls the `offerLSP8Address` smart contract's
     * method `isOperatorFor` which returns a boolean value. If there is an offer with this LSP8
     * the return falue must be true.
     */
    modifier offerExists (
        address offerLSP8Address, 
        bytes32 offerTokenId
    ) {
        require(
            ILSP8IdentifiableDigitalAsset(offerLSP8Address).isOperatorFor(address(this), offerTokenId),
            "Offer does not exist."
        ); _;
    }

    /**
     * Modifier checks if there is an offer for a specific `LSP8Address` and `tokenId`
     * with the `offerLSP8Address` and `offerTokenId`.
     * 
     * @param LSP8Address The address of the LSP8.
     * @param tokenId Token id of the `LSP8Address` LSP8 that is about to be checked.
     * @param offerLSP8Address The address of the offer LSP8.
     * @param offerTokenId Token id of the `offerLSP8Address` LSP8 that is about to be checked.
     *
     * @notice Once called the method checks if there is an offer to `LSP8Address` and `tokenId`
     * from `offerLSP8Address` and `offerTokenId`.
     */
    modifier offerExistsForThisLSP8 (
        address LSP8Address,
        bytes32 tokenId,
        address offerLSP8Address, 
        bytes32 offerTokenId
    ) {
        require(
            _offers[LSP8Address][tokenId].LSP8TokenIds[offerLSP8Address].contains(offerTokenId),
            "Offer does not exist for this LSP8."
        ); _;
    }

    // --- LSP8 Offer functionality.

    /**
     * Create an offer to trade LSP8 for LSP8
     * 
     * @param LSP8Address The address of the LSP8 that will receive an offer.
     * @param tokenId Token id of the `LSP8Address` LSP8.
     * @param offerLSP8Address The address of the LSP8 that will be offered in exchange.
     * @param offerTokenId Token id of the `offerLSP8Address` LSP8.
     *
     * @notice Once this method is called the `offerLSP8Address` will be added to an
     * array of addresses that contains the addresses of all the LSP8s offered for exchange.
     * After that the method creates an array for the `offerLSP8Address` which keeps track
     * of all the token ids that are offered in exchange to `LSP8Address`+`tokenId`.
     */
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
        _offer.LSP8TokenIds[offerLSP8Address].add(offerTokenId);
        ILSP8IdentifiableDigitalAsset(offerLSP8Address).authorizeOperator(address(this), offerTokenId);
    }

    /**
     * Remove an trade offer from an LSP8.
     * 
     * @param LSP8Address The address of the LSP8 that will have an offer removed.
     * @param tokenId Token id of the `LSP8Address` LSP8.
     * @param offerLSP8Address The address of the LSP8 that will be removed from offers.
     * @param offerTokenId Token id of the `offerLSP8Address` LSP8.
     *
     * @notice Once this method is called the `offerLSP8Address` will be removed from an
     * array of addresses that contains the addresses of all the LSP8s offered for exchange.
     * After that the method removes the `offerTokenId` from the array of token ids
     * from `offerLSP8Address` which keeps track of all the token ids that are offered
     * in exchange to `LSP8Address`+`tokenId`.
     */
    function _removeLSP8Offer (
        address LSP8Address,
        bytes32 tokenId,
        address offerLSP8Address,
        bytes32 offerTokenId
    )
        internal
    {
        _offers[LSP8Address][tokenId].LSP8Addresses.remove(offerLSP8Address);
        _offers[LSP8Address][tokenId].LSP8TokenIds[offerLSP8Address].remove(offerTokenId);
        ILSP8IdentifiableDigitalAsset(offerLSP8Address).revokeOperator(address(this), offerTokenId);
    }

    /**
     * Remove all offers of a LSP8.
     * 
     * @param LSP8Address The address of the LSP8 that will have the offers removed.
     * @param tokenId Token id of the `LSP8Address` LSP8.
     *
     * @notice Once this method is called all the offers that exist for the `LSP8Address`
     * and `tokenId`.
     */
    function _removeLSP8Offers (
        address LSP8Address,
        bytes32 tokenId
    )
        internal
    {
        delete _offers[LSP8Address][tokenId];
    }

    /**
     * Return all the addresses that are offered for an LSP8.
     * 
     * @param LSP8Address The address of the LSP8.
     * @param tokenId Token id of the `LSP8Address` LSP8.
     *
     * @return An array of addresses.
     *
     * @notice This method returns an array containing all the addresses
     * that are registred as trade offers for a specific `LSP8Address` and `tokenId`.
     */
    function _returnLSP8OfferAddresses (
        address LSP8Address,
        bytes32 tokenId
    )
        public
        view
        returns(address[] memory)
    {
        return _offers[LSP8Address][tokenId].LSP8Addresses.values();
    }

    /**
     * Return all the token ids of a `offerLSP8Addresss` that are offered for an LSP8.
     * 
     * @param LSP8Address The address of the LSP8.
     * @param tokenId Token id of the `LSP8Address` LSP8.
     * @param offerLSP8Address The address of the LSP8 that is offered in exchange for the `LSP8Address` LSP8.
     *
     * @return An array of bytes32 token ids.
     *
     * @notice This method returns an array containing all the token ids belonging
     * to the `offerLSP8Address` LSP8 that are registred as trade offers for
     * a specific `LSP8Address` and `tokenId`.
     */
    function _returnLSP8OfferTokenIdsByAddress (
        address LSP8Address,
        bytes32 tokenId,
        address offerLSP8Address
    )
        public
        view
        returns(bytes32[] memory)
    {
        Offers storage _offer = _offers[LSP8Address][tokenId];
        bytes32[] memory LSP8TokenIds;
        for (uint i = 0; i < _offer.LSP8TokenIds[offerLSP8Address].length(); i++) {
            LSP8TokenIds[i] = bytes32(_offer.LSP8TokenIds[offerLSP8Address].at(i));
        }
        return LSP8TokenIds;
    }

}