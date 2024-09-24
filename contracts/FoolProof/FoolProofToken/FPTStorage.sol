
// SPDX-License-Identifier: BSD-3
pragma solidity ^0.8.9;

import {IERC721PrincipalEnumerable} from "./IERC721PrincipalEnumerable.sol";

struct SubscriptionConfig {
  uint256 price;
  uint32 period;
  uint32 maxDuration;

  uint16 setupNum;
  uint16 setupDenom;
  bool isActive;
}

struct Token {
  address principal;
  address surrogate;
  bool isSet;
}

struct SubscriptionToken {
  address principal;
  address surrogate;
  bool isSet;

  uint256 value;
  uint32 created;
  uint32 started;
  uint32 expires;
}

struct SurrogateStruct {
  IERC721PrincipalEnumerable PRINCIPAL;
  uint8 implementation;
  uint8 version;
  bool useTokenURIPassthrough;

  string tokenURIPrefix;
  string tokenURISuffix;

  uint256 _totalSupply;

  mapping(address => int256) _balances;
  mapping(uint256 => Token) _tokens;
}

struct SubscriptionSurrogateStruct {
  IERC721PrincipalEnumerable PRINCIPAL;
  uint8 implementation;
  uint8 version;
  bool useTokenURIPassthrough;

  string tokenURIPrefix;
  string tokenURISuffix;

  uint256 _totalSupply;

  mapping(address => int256) _balances;
  mapping(uint256 => SubscriptionToken) _tokens;

  SubscriptionConfig CONFIG;
  mapping(address => bool) isBlacklisted;
}

library FPTStorage {
  function getSurrogateStorage(bytes32 slot) internal pure returns (SurrogateStruct storage ss) {
    assembly {
      ss.slot := slot
    }
  }

  function getSubscriptionSurrogateStorage(bytes32 slot) internal pure returns (SubscriptionSurrogateStruct storage subSS) {
    assembly {
      subSS.slot := slot
    }
  }
}
