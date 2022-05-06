// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import {ILSP8IdentifiableDigitalAsset} from "https://github.com/lukso-network/lsp-smart-contracts/blob/develop/contracts/LSP8IdentifiableDigitalAsset/ILSP8IdentifiableDigitalAsset.sol";
import {ILSP7DigitalAsset} from "https://github.com/lukso-network/lsp-smart-contracts/blob/develop/contracts/LSP7DigitalAsset/ILSP7DigitalAsset.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

/**
 * @title FamilyClothingLSP8MarketplaceStorage contract
 * @author Afteni Daniel (aka B00ste)
 */
 
contract LSP8MarketplaceStorage {

    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    // --- Storage.

    EnumerableSet.AddressSet private _users;
    mapping (address => EnumerableSet.Bytes32Set) private _sale;
    mapping (address => mapping (bytes32 => Prices)) private _prices;
    struct Prices {
        EnumerableSet.AddressSet LSP7Addresses;
        EnumerableMap.AddressToUintMap LSP7Amounts;
        uint256 LYXAmount;
    }
    mapping (address => mapping (bytes32 => Offers)) private _offers;
    struct Offers {
        EnumerableSet.AddressSet LSP8Addresses;
        EnumerableMap.AddressToUintMap LSP8TokenIds;
    }

    // --- Modifiers.

    modifier userDoesNotExist {
        require(!_users.contains(msg.sender), "User already exists.");
        _;
    }

    modifier userExists {
        require(_users.contains(msg.sender), "User does not exist.");
        _;
    }

    modifier userOwnsLSP8(address LSP8Address, bytes32 tokenId) {
        require(
            ILSP8IdentifiableDigitalAsset(LSP8Address).tokenOwnerOf(tokenId) == msg.sender,
            "Sender doesn't own this LSP8."
        );
        _;
    }

    modifier LSP8OnSale(address LSP8Address, bytes32 tokenId) {
        require(
            _sale[LSP8Address].contains(tokenId),
            "LSP8 is not on sale."
        );
        _;
    }

    modifier LSP8NotOnSale(address LSP8Address, bytes32 tokenId) {
        require(
            !_sale[LSP8Address].contains(tokenId),
            "LSP8 is on sale."
        );
        _;
    }

    modifier sendEnoughLYX(address LSP8Address, bytes32 tokenId) {
        require(_prices[LSP8Address][tokenId].LYXAmount == msg.value);
        _;
    }

    modifier haveEnoughLSP7Balance(address LSP8Address, bytes32 tokenId, address LSP7Address) {
        require(
            ILSP7DigitalAsset(LSP7Address).balanceOf(msg.sender) > _prices[LSP8Address][tokenId].LSP7Amounts.get(LSP7Address),
            "Sender doesn't have enough token balance."
        );
        _;
    }

    modifier transactionPossible(address LSP8Address, bytes32 tokenId, address LSP7Address) {
        require(_sale[LSP8Address].contains(tokenId), "LSP8 is not on sale.");
        Prices storage _price = _prices[LSP8Address][tokenId];
        for (uint i = 0; i < _price.LSP7Addresses.length(); i++) {
            if (_price.LSP7Addresses.at(i) == LSP7Address) {
                _;
            }
        }
        revert("Seller does not accept this token.");
    }

    // --- Internal functionality.

    // -- User functionality.

    // Add user.
    function _addUser(address newUser) internal {
        _users.add(newUser);
    }

    // Remove user.
    function _removeUser(address newUser) internal {
        _users.remove(newUser);
    }

    // -- Sale functionality.

    // Create sale.
    function _addLSP8Sale(address LSP8Address, bytes32 tokenId) internal {
        _sale[LSP8Address].add(tokenId);
    }

    // Remove sale.
    function _removeLSP8Sale(address LSP8Address, bytes32 tokenId) internal {
        _sale[LSP8Address].remove(tokenId);
    }

    // -- Price functionality

    // - LYX Price functionality.

    // Add LYX amount for buyout of an LSP8.
    function _addLYXPrice(address LSP8Address, bytes32 tokenId, uint256 LYXAmount) internal {
        _prices[LSP8Address][tokenId].LYXAmount = LYXAmount;
    }

    // Getter for LYX amout for buyout of an LSP8.    
    function _returnLYXPrice(address LSP8Address, bytes32 tokenId) public view returns(uint256) {
        return _prices[LSP8Address][tokenId].LYXAmount;
    }

    // - LSP7 Price functionality.

    // Add LSP7 tokenAddresses and buyout amounts for an LSP8.
    function _addLSP7Price(
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

    /**
     * Getter for LSP7 tokenAddresses and LSP8 buyout amounts. Returns two ordered arrays.
     * First array is with tokenAddresses, the second one is with buyout amounts.
     */
    function _returnLSP7Prices(
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
     * Getter for LSP7 buyout amount of an LSP by LSP7 tokenAddress.
     * Returns one tokenAmount.
     */
    function _returnLSP7PriceByAddress(
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

    function _removeLSP8Prices(address LSP8Address, bytes32 tokenId) internal {
        delete _prices[LSP8Address][tokenId];
    }

    // -- Remove info about the sale and sale price.

    function _removeLSP8SaleAndPrice(address LSP8Address, bytes32 tokenId) internal {
        _removeLSP8Prices(LSP8Address, tokenId);
        _removeLSP8Sale(LSP8Address, tokenId);
    }

    // -- UniversalReciever data generator.

    function _returnLSPTransferData(
        address from,
        address to,
        uint256 amount
    )
        internal
        pure
        returns(bytes memory)
    {
        return abi.encodeWithSignature(
            "universalReceiver(bytes32 typeId, bytes memory data)",
            keccak256("TOKEN_RECEIVE"),
            abi.encodePacked(from, to, amount)
        );
    }

}