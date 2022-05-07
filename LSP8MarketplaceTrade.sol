// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import { ILSP8IdentifiableDigitalAsset } from "https://github.com/lukso-network/lsp-smart-contracts/blob/develop/contracts/LSP8IdentifiableDigitalAsset/ILSP8IdentifiableDigitalAsset.sol";
import { ILSP7DigitalAsset } from "https://github.com/lukso-network/lsp-smart-contracts/blob/develop/contracts/LSP7DigitalAsset/ILSP7DigitalAsset.sol";
import { LSP8MarketplaceSale } from "./LSP8MarketplaceSale.sol";

/**
 * @title LSP8MarketplaceTrade contract
 * @author Afteni Daniel (aka B00ste)
 */

 contract LSP8MarketplaceTrade {

    // --- UniversalReciever data generator.

    function _returnLSPTransferData (
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

    // --- LSP8 and LSP7 transfer functions.

    function _transferLSP8 (
        address LSP8Address,
        address from,
        address to,
        bytes32 tokenId,
        bool force,
        uint256 amount
    )
        internal
    {
        ILSP8IdentifiableDigitalAsset(LSP8Address)
        .transfer(
            from,
            to,
            tokenId,
            force,
            _returnLSPTransferData(from, to, amount)
        );
    }

    function _transferLSP7 (
        address LSP7Address,
        address from,
        address to,
        uint256 amount,
        bool force
    )
        internal
    {
        ILSP7DigitalAsset(LSP7Address).authorizeOperator(address(this), amount);
        ILSP7DigitalAsset(LSP7Address)
        .transfer(
            from,
            to,
            amount,
            force,
            _returnLSPTransferData(from, to, amount)
        );

    }

 }