
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721, IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {IOwnable} from "../Common/IOwnable.sol";
import {IERC721Principal} from "./IERC721Principal.sol";
import {IERC721PrincipalEnumerable} from "./IERC721PrincipalEnumerable.sol";
import {IERC721Surrogate, IERC721SubscriptionSurrogate} from "./IERC721SubscriptionSurrogate.sol";

import {FPTStorage, SubscriptionConfig, SubscriptionSurrogateStruct, SubscriptionToken} from "./FPTStorage.sol";
import {ERC721SurrogateUpgradeable} from "./ERC721SurrogateUpgradeable.sol";


contract ERC721SubscriptionSurrogateUpgradeable is
  IERC721SubscriptionSurrogate,
  ERC721SurrogateUpgradeable,
  ReentrancyGuard
{
  using Strings for uint256;
  using FPTStorage for bytes32;

  uint256 public constant FP_ROYALTY_MILS = 69;
  address public constant FP_WALLET = 0x282D35Ee1b589F003db896b988fc59e2665Fa6a1;

  function __ERC721SubscriptionSurrogate_init(address _principal) internal onlyInitializing {
    __ERC721Surrogate_init(_principal);

    SubscriptionSurrogateStruct storage subSS = SurrogateSlot.getSubscriptionSurrogateStorage();
    subSS.PRINCIPAL = IERC721PrincipalEnumerable(_principal);
    subSS.implementation = 2;
    subSS.version = 1;

    // emit Implemented(address(this), subSS.implementation, subSS.version);
  }

  function initialize(address _principal) external override(IERC721Surrogate, ERC721SurrogateUpgradeable) initializer {
    // __Ownable_init(msg.sender);
    __Delegated_init();
    __ERC721SubscriptionSurrogate_init(_principal);

    SubscriptionSurrogateStruct storage subSS = SurrogateSlot.getSubscriptionSurrogateStorage();
    require(address(subSS.PRINCIPAL) != address(0), "Upgrade failed, null PRINCIPAL");

    subSS.PRINCIPAL = IERC721PrincipalEnumerable(_principal);
    subSS.implementation = 2;
    subSS.version = 2;

    // emit Implemented(address(this), subSS.implementation, subSS.version);
  }

  function reinitialize() public override reinitializer(2) {
    SubscriptionSurrogateStruct storage subSS = SurrogateSlot.getSubscriptionSurrogateStorage();
    require(address(subSS.PRINCIPAL) != address(0), "Upgrade failed, null PRINCIPAL");

    subSS.implementation = 2;
    subSS.version = 2;
    // emit Implemented(address(this), ss.implementation, ss.version);
  }

  function withdraw() external onlyOwner {
    uint256 totalBalance = address(this).balance;
    require(totalBalance > 0, "no funds available");
    Address.sendValue(payable(owner()), totalBalance);
  }


  //Subscription :: payable
  function cancel(uint16 tokenId) external payable nonReentrant {
    address fptOwner = ownerOf(tokenId);
    require(msg.sender == fptOwner, "Cancellations are restricted to the current FPT owner");

    SubscriptionSurrogateStruct storage subSS = SurrogateSlot.getSubscriptionSurrogateStorage();
    SubscriptionToken memory token = subSS._tokens[tokenId];
    uint32 timestamp = uint32(block.timestamp);
    require(token.expires > timestamp, "Subscription expired");

    uint32 duration = token.expires - token.started;
    uint32 remainder = token.expires - timestamp;
    uint256 _refund = token.value * remainder / duration;
    require(address(this).balance > _refund, "Insufficient balance");

    subSS._tokens[tokenId] = SubscriptionToken(
      token.principal,
      token.surrogate,
      token.isSet,

      0, //value
      token.created,
      token.started,
      timestamp
    );
    emit SubscriptionUpdate(msg.sender, tokenId, token.started, timestamp);

    Address.sendValue(payable(fptOwner), _refund);
  }

  function subscribe(uint16 tokenId, uint16 periods) external payable nonReentrant {
    SubscriptionSurrogateStruct storage subSS = SurrogateSlot.getSubscriptionSurrogateStorage();
    require(!subSS.isBlacklisted[msg.sender], "Blacklisted accounts cannot amplify tokens");

    bool isOwner = false;
    isOwner = msg.sender == ownerOf(tokenId);
    if (!isOwner) {
      isOwner = msg.sender == subSS.PRINCIPAL.ownerOf(tokenId);
    }
    require(isOwner, "Sales/Subscriptions are restricted to the current FPT owner");

    SubscriptionConfig memory cfg = subSS.CONFIG;
    require(cfg.isActive,                     "Sales/Subscriptions are currently closed" );
    require(msg.value == periods * cfg.price, "Not enough ETH for selected duration" );



    // TODO: cfg.maxDuration


    // TODO: payment splitter?
    uint256 royalty = msg.value * FP_ROYALTY_MILS / 1000;
    Address.sendValue(payable(FP_WALLET), royalty);

    uint32 duration = uint32(periods * cfg.period);
    uint256 setup = cfg.setupDenom > 0 ?
      msg.value * cfg.setupNum / cfg.setupDenom : 0;
    uint256 remainder = msg.value - (royalty + setup);
    _updateSubscription(tokenId, duration, remainder);
  }

  //Subscription :: view
  function isAmped(uint16 tokenId) external view returns(bool) {
    SubscriptionSurrogateStruct storage subSS = SurrogateSlot.getSubscriptionSurrogateStorage();

    address tokenOwner = ownerOf(tokenId);
    if(subSS.isBlacklisted[tokenOwner])
      return false;

    SubscriptionToken memory token = subSS._tokens[tokenId];
    return token.started <= block.timestamp && block.timestamp <= token.expires;
  }


  // view
  function CONFIG() public view returns(SubscriptionConfig memory) {
    return SurrogateSlot.getSubscriptionSurrogateStorage().CONFIG;
  }

  function isBlacklisted(address account) public view returns(bool) {
    return SurrogateSlot.getSubscriptionSurrogateStorage().isBlacklisted[account];
  }

  function tokenSS(uint256 tokenId) public view returns(SubscriptionToken memory){
    SubscriptionSurrogateStruct storage subSS = SurrogateSlot.getSubscriptionSurrogateStorage();
    SubscriptionToken memory token = subSS._tokens[tokenId];
    return token;
  }


  //ERC721 :: view
  function balanceOf(address account) public view override(IERC721Surrogate, ERC721SurrogateUpgradeable) returns(uint256) {
    revert NotSupported();
    // int256 balance = int256(PRINCIPAL.balanceOf(account)) + _balances[ account ];
    // if( balance < 0 )
    //   return 0;
    // else
    //   return uint256(balance);
  }


  //admin
  function amplify(uint16[] calldata tokenIds, uint16 periods) external payable onlyOwner {
    SubscriptionSurrogateStruct storage subSS = SurrogateSlot.getSubscriptionSurrogateStorage();

    SubscriptionConfig memory cfg = subSS.CONFIG;
    uint32 duration = uint32(periods * cfg.period);


    //TODO: maxDuration


    address account;
    uint16 tokenId;
    for(uint16 i = 0; i < tokenIds.length; ++i){
      tokenId = tokenIds[i];
      account = ownerOf(tokenId);
      require(!subSS.isBlacklisted[account], "Blacklisted accounts cannot amplify tokens");
      _updateSubscription(tokenId, duration, 0);
    }
  }

  function refund(uint16[] calldata tokenIds, bool setExpired) public payable onlyOwner nonReentrant {
    SubscriptionSurrogateStruct storage subSS = SurrogateSlot.getSubscriptionSurrogateStorage();

    address account;
    uint16 tokenId;
    uint256 totalValue;
    for (uint256 i = 0; i < tokenIds.length; ++i) {
      tokenId = tokenIds[i];
      SubscriptionToken memory token = subSS._tokens[tokenId];

      // TODO: calculate this
      totalValue += token.value;

      if(account == address(0)){
        account = ownerOf(tokenId);
      }
      else if(account != ownerOf(tokenId)){
        revert("Only one owner can be refunded");
      }
    }
    require(totalValue < address(this).balance, "not enough ETH on contract");

    if(setExpired){
      uint32 expires = uint32(block.timestamp);

      for(uint256 i = 0; i < tokenIds.length; ++i){
        tokenId = tokenIds[i];
        SubscriptionToken storage token = subSS._tokens[tokenId];
        token.expires = expires;
        emit SubscriptionUpdate(account, tokenId, token.started, token.expires);
      }
    }

    Address.sendValue(payable(account), totalValue);
  }

  function setConfig(SubscriptionConfig calldata newConfig) external onlyOwner {
    if(newConfig.setupDenom > 0)
      require(newConfig.setupNum < newConfig.setupDenom, "Numerator must be less than denominator");

    SurrogateSlot.getSubscriptionSurrogateStorage().CONFIG = newConfig;
  }

  function setStatus(address payable account, bool isBlacklisted_ /*, uint16[] calldata tokenIds*/ ) external payable onlyOwner {
    SubscriptionSurrogateStruct storage subSS = SurrogateSlot.getSubscriptionSurrogateStorage();

    subSS.isBlacklisted[account] = isBlacklisted_;

    // TODO: refund
  }


  //internal
  function _setSurrogate(uint256 tokenId, address principalOwner, address surrogateOwner) internal override {
    SubscriptionSurrogateStruct storage subSS = SurrogateSlot.getSubscriptionSurrogateStorage();

    SubscriptionToken memory prev = subSS._tokens[ tokenId ];
    if(prev.principal != principalOwner){
      if(prev.principal != address(0))
        subSS._balances[prev.principal] += 1;

      subSS._balances[principalOwner] -= 1;
    }

    if(prev.surrogate != surrogateOwner){
      if(prev.surrogate != address(0))
        subSS._balances[prev.surrogate] -= 1;
      
      subSS._balances[surrogateOwner] += 1;
    }

    subSS._tokens[ tokenId ] = SubscriptionToken(
      principalOwner,
      surrogateOwner,
      true,

      // TODO: reset?
      prev.value,
      prev.created,
      prev.started,
      prev.expires
    );
    emit Transfer(prev.surrogate, surrogateOwner, tokenId);
  }

  function _unsetSurrogate(uint256 tokenId, address principalOwner) internal override {
    SubscriptionSurrogateStruct storage subSS = SurrogateSlot.getSubscriptionSurrogateStorage();

    SubscriptionToken memory prev = subSS._tokens[ tokenId ];
    if (prev.isSet) {
      subSS._balances[prev.surrogate] -= 1;
      subSS._balances[prev.principal] += 1;
    }

    subSS._tokens[ tokenId ] = SubscriptionToken(
      principalOwner,
      principalOwner,
      false,

      // TODO: reset?
      prev.value,
      prev.created,
      prev.started,
      prev.expires
    );
    emit Transfer(prev.surrogate, principalOwner, tokenId);
  }

  function _cancelSubscription(uint256 tokenId) internal {

  }

  function _updateSubscription(uint256 tokenId, uint32 seconds_, uint256 value) internal {
    SubscriptionSurrogateStruct storage subSS = SurrogateSlot.getSubscriptionSurrogateStorage();

    uint32 ts = uint32(block.timestamp);
    SubscriptionToken memory token = subSS._tokens[tokenId];

    //new subscription
    if (token.created == 0) {
      subSS._tokens[tokenId] = SubscriptionToken(
        token.principal,
        token.surrogate,
        token.isSet,

        value,
        ts,
        ts,
        ts + seconds_
      );
      emit SubscriptionUpdate(msg.sender, tokenId, ts, ts + seconds_);
    }
    //expired re-sub
    else if (token.expires < ts) {
      subSS._tokens[tokenId] = SubscriptionToken(
        token.principal,
        token.surrogate,
        token.isSet,

        value,
        token.created,
        ts,
        ts + seconds_
      );
      emit SubscriptionUpdate(msg.sender, tokenId, ts, ts + seconds_);
    }
    //extension
    else{
      subSS._tokens[tokenId] = SubscriptionToken(
        token.principal,
        token.surrogate,
        token.isSet,

        token.value + value,
        token.created,
        token.started,
        token.expires + seconds_
      );
      emit SubscriptionUpdate(msg.sender, tokenId, token.started, token.expires + seconds_);
    }
  }


  //internal - admin
  // solhint-disable-next-line no-empty-blocks
  function _authorizeUpgrade(address) internal virtual override onlyOwner {}
}
