
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC721Surrogate} from "./IERC721Surrogate.sol";
import {SubscriptionConfig, SubscriptionToken} from "./FPTStorage.sol";

interface IERC721SubscriptionSurrogate is IERC721Surrogate {
  event SubscriptionUpdate(address indexed account, uint256 indexed tokenId, uint32 started, uint32 expires);

  function withdraw() external;

  //token owners - payable
  function subscribe(uint16 tokenId, uint16 periods) external payable;
  
  //token owners - view
  function isAmped(uint16 tokenId) external view returns(bool);
  function isBlacklisted(address account) external view returns(bool);
  function tokenSS(uint256 tokenId) external view returns(SubscriptionToken memory);

  //owner - writable
  function amplify(uint16[] calldata tokenIds, uint16 periods) external payable;
  function refund(uint16[] calldata tokenIds, bool setExpired) external payable;
  function setConfig(SubscriptionConfig calldata newConfig) external;
}