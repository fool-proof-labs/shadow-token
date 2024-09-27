
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { IERC721Surrogate } from "../FoolProofToken/IERC721Surrogate.sol";

import { IImmutableControl } from "./IImmutableControl.sol";


interface IImmutableSurrogate is IERC721Surrogate {
  function adminSetSurrogate(uint256 tokenId, address wallet, uint64 expires, uint256 depTokenId) external;
  function adminUnsetSurrogate(uint256 tokenId) external;
}
