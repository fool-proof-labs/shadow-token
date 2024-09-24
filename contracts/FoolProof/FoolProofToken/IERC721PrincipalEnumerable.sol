
// SPDX-License-Identifier: BSD-3
pragma solidity ^0.8.9;

import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import {IERC721Principal} from "./IERC721Principal.sol";

// solhint-disable-next-line no-empty-blocks
interface IERC721PrincipalEnumerable is IERC721Enumerable, IERC721Principal {}

