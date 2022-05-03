// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "https://github.com/lukso-network/lsp-smart-contracts/blob/develop/contracts/LSP8IdentifiableDigitalAsset/ILSP8IdentifiableDigitalAsset.sol";
import "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";

/**
 * @title FamilyClothingMarketplace contract
 * @author Afteni Daniel (aka B00ste)
 */

contract Marketplace {

    // --- Errors

    error UserAlreadyExists(address UPAddress);
    error UserDoesNotExist(address UPAddress);
    error NFTIsNotOnSale(address NFTAddress);
    error TokenIdIsNotOnSale(address NFTAddress, uint tokenId);
    error SenderIsNotOwnerOfNFT(address UPAddress, address NFTAddress, uint tokenId);

    // --- Storage

    // All user addresses.
    address[] userAddresses;

    // Mapping from `UPAddress` to info about the User.
    mapping (address => User) users;

    // Useful information about users.
    struct User {
        uint index;
        string username;
    }

    // All NFT addresses.
    address[] NFTAddresses;
    
    // Mapping from `NFTAddress` to info about the NFT.
    mapping (address => NFT) NFTs;

    /**
     * The NFT struct keeps track of tokenIds on sale.
     * The inDb bool helps us check if we already have
     * a tokenId on sale for a NFT address.
     * NFTOwner will point to the owner of a tokenId.
     */

    struct NFT {
        bool inDb;
        uint index;
        uint[] tokenIds;
        mapping (uint => address) NFTOwner;
    }

    // --- User functionality.

    /**
     * We create a user by verifying first that there is no user with that address.
     * Then we update our database and create a new User Struct.
     */

    function createUser(string memory _username) public {
        if (bytes(users[msg.sender].username).length != 0) {
            revert UserAlreadyExists(msg.sender);
        }
        users[msg.sender].username = _username;
        users[msg.sender].index = userAddresses.length;
        userAddresses.push(msg.sender);
    }

    /**
     * Remove address from the database and remove user's struct.
     */

    function removeUser() public {
        userAddresses[users[msg.sender].index] = userAddresses[userAddresses.length - 1];
        userAddresses.pop();
        delete users[msg.sender];
    }

    // --- On sale functionality.

    /**
     * Firstly we have to verify that there is a user with that
     * Then we save the tokenId to the array.
     */

    function _putForSale(address _NFTAddress, uint256 _tokenId) public {
        //ToDo verify that such TokenId exists for that particular NFT. And that user owns it.
        if (bytes(users[msg.sender].username).length == 0) {
            revert UserDoesNotExist(msg.sender);
        }
        if (!NFTs[_NFTAddress].inDb) {
            NFTs[_NFTAddress].inDb = true;
            NFTs[_NFTAddress].index = NFTAddresses.length;
            NFTAddresses.push(_NFTAddress);
        }
        NFTs[_NFTAddress].tokenIds.push(_tokenId);
        NFTs[_NFTAddress].NFTOwner[_tokenId] = msg.sender;
    }

    /**
     * Firstly we have to check that the NFT is on sale
     * and that the user that tries to delete it is
     * actually the owner of the sale.
     * Then we delete the tokenId from sale and if
     * there are no more NFTs on sale for that address
     * we delete the whole struct.
     */

    function _removeFromSale(address _NFTAddress, uint256 _tokenId) public {
        if (!NFTs[_NFTAddress].inDb) {
        revert NFTIsNotOnSale(_NFTAddress);
        }
        else if (NFTs[_NFTAddress].NFTOwner[_tokenId] == address(0)) {
        revert TokenIdIsNotOnSale(_NFTAddress, _tokenId);
        }
        else if (NFTs[_NFTAddress].NFTOwner[_tokenId] != msg.sender){
        revert SenderIsNotOwnerOfNFT(msg.sender, _NFTAddress, _tokenId);
        }
        delete NFTs[_NFTAddress].NFTOwner[_tokenId];
        for (uint i = 0; i < NFTs[_NFTAddress].tokenIds.length; i++) {
            if (NFTs[_NFTAddress].tokenIds[i] == _tokenId) {
                NFTs[_NFTAddress].tokenIds[i] = NFTs[_NFTAddress].tokenIds[NFTs[_NFTAddress].tokenIds.length];
                NFTs[_NFTAddress].tokenIds.pop();
            }
        }
        if (NFTs[_NFTAddress].tokenIds.length == 0) {
            NFTAddresses[NFTs[_NFTAddress].index] = NFTAddresses[NFTAddresses.length - 1];
            NFTAddresses.pop();
            delete NFTs[_NFTAddress];
        }
    }

    // --- User getters

    function getNrOfUsers() public view returns(uint nrOfUsers_) {
        nrOfUsers_ = userAddresses.length;
    }

    function getUsernameByIndex(uint _index) public view returns(string memory username_) {
        username_ = users[userAddresses[_index]].username;
    }

    // --- NFT getters

    function getNrOfNFTs() public view returns(uint nrOfNFTs_) {
        nrOfNFTs_ = NFTAddresses.length;
    }

    function getNrOfTokenIdsByIndexOfNFT(uint _NFTIndex) public view returns(uint nrOfTokenIds_) {
        nrOfTokenIds_ = NFTs[NFTAddresses[_NFTIndex]].tokenIds.length;
    }

    function getNFTTokenIdByIndexes(uint _NFTIndex, uint _tokenIdIndex) public view returns(uint tokenId_) {
        tokenId_ = NFTs[NFTAddresses[_NFTIndex]].tokenIds[_tokenIdIndex];
    }

}