// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import { ILSP7DigitalAsset } from "/home/b00ste/Projects/lsp-smart-contracts/contracts/LSP7DigitalAsset/ILSP7DigitalAsset.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { EnumerableMap } from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import { LSP8MarketplaceSale } from "./LSP8MarketplaceSale.sol";

/**
 * @title LSP8MarketplacePrice contract
 * @author Afteni Daniel (aka B00ste)
 */
 
contract LSP8MarketplacePrice is LSP8MarketplaceSale {

    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    // --- Storage.

    mapping (address => mapping (bytes32 => Prices)) private _prices;
    struct Prices {
        EnumerableSet.AddressSet LSP7Addresses;
        EnumerableMap.AddressToUintMap LSP7Amounts;
        uint256 LYXAmount;
    }

    // --- Modifiers.

    modifier LSP7PriceDoesNotExist (
        address LSP8Address, 
        bytes32 tokenId, 
        address LSP7Address
    ) {
        require(
            !_prices[LSP8Address][tokenId].LSP7Addresses.contains(LSP7Address),
            "There already exists a buyout price in this token. Try to change it."
        ); _;
    }

    modifier LSP7PriceDoesExist (
        address LSP8Address, 
        bytes32 tokenId, 
        address LSP7Address
    ) {
        require(
            _prices[LSP8Address][tokenId].LSP7Addresses.contains(LSP7Address),
            "There is no buyout price in this token. Try to add one."
        ); _;
    }

    modifier sendEnoughLYX (
        address LSP8Address, 
        bytes32 tokenId
    ) {
        require(
            _prices[LSP8Address][tokenId].LYXAmount == msg.value,
            "You didn't send enough LYX"
        ); _;
    }

    modifier haveEnoughLSP7Balance (
        address LSP8Address, 
        bytes32 tokenId, 
        address LSP7Address
    ) {
        require(
            ILSP7DigitalAsset(LSP7Address).balanceOf(msg.sender) > _prices[LSP8Address][tokenId].LSP7Amounts.get(LSP7Address),
            "Sender doesn't have enough token balance."
        ); _;
    }

    modifier sellerAcceptsToken (
        address LSP8Address, 
        bytes32 tokenId, 
        address LSP7Address
    ) { 
        require(
            _prices[LSP8Address][tokenId].LSP7Addresses.contains(LSP7Address),
            "Seller does not accept this token."
        ); _;
    }

    // --- LYX Price functionality.

    // Add LYX buyout amount.
    function _addLYXPrice (
        address LSP8Address,
        bytes32 tokenId,
        uint256 LYXAmount
    )
        internal
    {
        _prices[LSP8Address][tokenId].LYXAmount = LYXAmount;
    }

    // Remove LYX buyout amount.
    function _removeLYXPrice (
        address LSP8Address,
        bytes32 tokenId
    )
        internal
    {
        delete _prices[LSP8Address][tokenId].LYXAmount;
    }

    // Getter for LYX buyout amount.    
    function _returnLYXPrice (
        address LSP8Address,
        bytes32 tokenId
    )
        public
        view
        returns(uint256)
    {
        return _prices[LSP8Address][tokenId].LYXAmount;
    }

    // --- LSP7 Price functionality.

    // Add multiple LSP7 tokenAddresses and buyout amounts to an LSP8.
    function _addLSP7Prices (
        address LSP8Address,
        bytes32 tokenId,
        address[] memory LSP7Addresses,
        uint256[] memory LSP7Amount
    )
        internal
    {
        Prices storage _price = _prices[LSP8Address][tokenId];
        for (uint i = 0; i < LSP7Addresses.length; i++) {
            _price.LSP7Addresses.add(LSP7Addresses[i]);    
            _price.LSP7Amounts.set(LSP7Addresses[i], LSP7Amount[i]);
        }
    }

    // Add one LSP7 tokenAddress and buyout amount to an LSP8.
    function _addLSP7PriceByAddress (
        address LSP8Address,
        bytes32 tokenId,
        address LSP7Address,
        uint256 LSP7Amount
    )
        internal
    {
        Prices storage _price = _prices[LSP8Address][tokenId];
        _price.LSP7Addresses.add(LSP7Address);    
        _price.LSP7Amounts.set(LSP7Address, LSP7Amount);
    }

    /**
     * Getter for all LSP7 tokenAddresses and LSP8 buyout amounts.
     * First array is with tokenAddresses.
     * The second array is with buyout amounts.
     * Returns two ordered arrays.
     */
    function _returnLSP7Prices (
        address LSP8Address,
        bytes32 tokenId
    )
        public
        view
        returns(address[] memory, uint256[] memory)
    {
        Prices storage _price = _prices[LSP8Address][tokenId];
        uint256[] memory LSP7Amounts;
        for (uint i = 0; i < _price.LSP7Addresses.length(); i++) {
            LSP7Amounts[i] = _price.LSP7Amounts.get(_price.LSP7Addresses.at(i));
        }
        return (_price.LSP7Addresses.values(), LSP7Amounts);
    }

    /**
     * Getter for LSP7 buyout amount of an LSP8 by LSP7 tokenAddress.
     * Returns one tokenAmount.
     */
    function _returnLSP7PriceByAddress (
        address LSP8Address,
        bytes32 tokenId,
        address LSP7Address
    )
        internal
        view
        returns(uint256)
    {
        return _prices[LSP8Address][tokenId].LSP7Amounts.get(LSP7Address);
    }

    // Remove a LSP7 price from an LSP8.
    function _removeLSP7PriceByAddress (
        address LSP8Address,
        bytes32 tokenId,
        address LSP7Address
    )
        internal
    {
        _prices[LSP8Address][tokenId].LSP7Addresses.remove(LSP7Address);
        _prices[LSP8Address][tokenId].LSP7Amounts.remove(LSP7Address);
    }

    // Removes all LSP7 prices from an LSP8.
    function _removeLSP8Prices (
        address LSP8Address,
        bytes32 tokenId
    )
        internal
    {
        delete _prices[LSP8Address][tokenId];
    }

}