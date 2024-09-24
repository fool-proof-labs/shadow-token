
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

// solhint-disable-next-line no-empty-blocks
interface IERC721Principal is IERC721Metadata, IERC721Enumerable {}

