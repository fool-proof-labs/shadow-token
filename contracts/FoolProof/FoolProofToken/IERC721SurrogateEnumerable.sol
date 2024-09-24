
// SPDX-License-Identifier: BSD-3
pragma solidity ^0.8.0;

import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import {IERC721Surrogate} from "./IERC721Surrogate.sol";

interface IERC721SurrogateEnumerable is IERC721Enumerable, IERC721Surrogate {
  //IER721Enumerable
  function tokenByIndex(uint256 index) external override(IERC721Enumerable, IERC721Surrogate) view returns (uint256);
  function tokenOfOwnerByIndex(address owner, uint256 index) external override(IERC721Enumerable, IERC721Surrogate) view returns (uint256);
  function totalSupply() external override(IERC721Enumerable, IERC721Surrogate) view returns (uint256);
}
