// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "https://github.com/lukso-network/lsp-smart-contracts/blob/develop/contracts/LSP8IdentifiableDigitalAsset/LSP8IdentifiableDigitalAsset.sol";

contract PlaceholderToken is LSP8IdentifiableDigitalAsset("PlaceholderToken", "PT", msg.sender) {}