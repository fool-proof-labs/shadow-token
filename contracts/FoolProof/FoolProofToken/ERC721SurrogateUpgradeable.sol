
// SPDX-License-Identifier: BSD-3
pragma solidity ^0.8.9;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721, IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {IERC721PrincipalEnumerable} from "./IERC721PrincipalEnumerable.sol";
import {IERC721Surrogate} from "./IERC721Surrogate.sol";
import {IOwnable} from "../Common/IOwnable.sol";

import {DelegatedUpgradeable} from "../Common/DelegatedUpgradeable.sol";
import {FPTStorage, SurrogateStruct, Token} from "./FPTStorage.sol";


contract ERC721SurrogateUpgradeable is
  DelegatedUpgradeable,
  UUPSUpgradeable,
  IERC721Surrogate
{
  using Strings for uint256;
  using FPTStorage for bytes32;

  bytes32 public constant SurrogateSlot = keccak256("SurrogateSlot");

  function __ERC721Surrogate_init(address principal) internal onlyInitializing {
    __Delegated_init();

    SurrogateStruct storage ss = SurrogateSlot.getSurrogateStorage();
    ss.PRINCIPAL = IERC721PrincipalEnumerable(principal);
    ss.implementation = 1;
    ss.version = 2;

    // emit Implemented();
  }

  function initialize(address _principal) external virtual initializer {
    __UUPSUpgradeable_init();
    __ERC721Surrogate_init(_principal);
  }

  function reinitialize() public virtual reinitializer(2) {
    SurrogateStruct storage ss = SurrogateSlot.getSurrogateStorage();
    require(address(ss.PRINCIPAL) != address(0), "Upgrade failed, null PRINCIPAL");

    ss.implementation = 1;
    ss.version = 2;
  }


  //IERC721Surrogate :: nonpayable
  function assumeOwnership() external {
    address principalOwner = IOwnable(getPrincipal()).owner();
    if(msg.sender != principalOwner)
      revert NotAuthorized();

    if(owner() == principalOwner)
      revert AlreadyOwner();

    _transferOwnership(msg.sender);
  }

  function setSurrogate(uint256 tokenId, address surrogateOwner) public {
    SurrogateStruct storage ss = SurrogateSlot.getSurrogateStorage();

    address principalOwner = ss.PRINCIPAL.ownerOf(tokenId);
    require(principalOwner == msg.sender, "ERC721Surrogate: caller is not owner");

    if (surrogateOwner == principalOwner || surrogateOwner == address(0)) {
      _unsetSurrogate(tokenId, principalOwner);
    }
    else{
      _setSurrogate(tokenId, principalOwner, surrogateOwner);
    }
  }

  function setSurrogates(uint256[] calldata tokenIds, address[] calldata surrogates) external {
    for( uint256 i; i < tokenIds.length; ++i ){
      setSurrogate( tokenIds[i], surrogates[i] );
    }
  }


  function softSync(uint256 tokenId) public {
    SurrogateStruct storage ss = SurrogateSlot.getSurrogateStorage();

    if (ss._tokens[tokenId].principal == address(0))
      emit Transfer(address(0), ss.PRINCIPAL.ownerOf(tokenId), tokenId);
  }

  function softSync(uint256[] calldata tokenIds) external {
    for(uint256 i; i < tokenIds.length; ++i){
      softSync(tokenIds[i]);
    }
  }


  function syncSurrogate(uint256 tokenId) public {
    SurrogateStruct storage ss = SurrogateSlot.getSurrogateStorage();

    address principalOwner = ss.PRINCIPAL.ownerOf( tokenId );
    if (ss._tokens[ tokenId ].principal != principalOwner) {
      _unsetSurrogate(tokenId, principalOwner);
    }
  }

  function syncSurrogates(uint256[] calldata tokenIds) external {
    for( uint256 i; i < tokenIds.length; ++i ){
      syncSurrogate( tokenIds[i] );
    }
  }


  function unsetSurrogate(uint256 tokenId) public {
    address principalOwner = PRINCIPAL().ownerOf(tokenId);
    require(principalOwner == msg.sender, "ERC721Surrogate: caller is not owner");
    _unsetSurrogate(tokenId, principalOwner);
  }

  function unsetSurrogates(uint256[] calldata tokenIds) external {
    for( uint256 i; i < tokenIds.length; ++i ){
      unsetSurrogate( tokenIds[i] );
    }
  }


  // view
  function PRINCIPAL() public view returns(IERC721PrincipalEnumerable) {
    return SurrogateSlot.getSurrogateStorage().PRINCIPAL;
  }

  function getPrincipal() public view returns(address) {
    return address(PRINCIPAL());
  }

  function implementation() external view returns(uint8) {
    return SurrogateSlot.getSurrogateStorage().implementation;
  }

  function token(uint256 tokenId) public view returns(Token memory){
    return SurrogateSlot.getSurrogateStorage()._tokens[tokenId];
  }

  function tokenURIPrefix() public view returns(string memory) {
    return SurrogateSlot.getSurrogateStorage().tokenURIPrefix;
  }

  function tokenURISuffix() public view returns(string memory) {
    return SurrogateSlot.getSurrogateStorage().tokenURISuffix;
  }

  function useTokenURIPassthrough() public view returns(bool) {
    return SurrogateSlot.getSurrogateStorage().useTokenURIPassthrough;
  }

  function version() public view returns(uint8) {
    return SurrogateSlot.getSurrogateStorage().version;
  }


  //ERC721 :: nonpayable
  function approve(address, uint256) external pure override {
    revert NotSupported();
  }

  function safeTransferFrom(address, address to, uint256 tokenId) external {
    setSurrogate( tokenId, to );
  }

  function safeTransferFrom(address, address to, uint256 tokenId, bytes calldata) external {
    setSurrogate( tokenId, to );
  }

  function transferFrom(address, address to, uint256 tokenId) external {
    setSurrogate(tokenId, to);
  }


  //ERC721 :: nonpayable :: not implemented
  function setApprovalForAll(address, bool) external pure {
    revert NotSupported();
  }


  //ERC721 :: view
  function balanceOf(address account) public view virtual override returns(uint256) {
    SurrogateStruct storage ss = SurrogateSlot.getSurrogateStorage();

    int256 balance = int256(ss.PRINCIPAL.balanceOf(account)) + ss._balances[ account ];
    if (balance < 0)
      return 0;
    else
      return uint256(balance);
  }

  function getApproved(uint256 tokenId) external view override returns(address) {
    return PRINCIPAL().ownerOf(tokenId);
  }

  function isApprovedForAll(address, address) external pure override returns(bool) {
    return false;
  }

  function ownerOf(uint256 tokenId) public virtual view returns (address) {
    SurrogateStruct storage ss = SurrogateSlot.getSurrogateStorage();

    address principalOwner = ss.PRINCIPAL.ownerOf(tokenId);
    Token memory _token = ss._tokens[ tokenId ];
    if (_token.principal == principalOwner && _token.isSet)
      return _token.surrogate;
    else
      return principalOwner;
  }


  //ERC721Metadata :: view
  function name() external view override returns (string memory) {
    return PRINCIPAL().name();
  }

  function symbol() external view override returns (string memory) {
    return PRINCIPAL().symbol();
  }

  function tokenURI(uint256 tokenId) external view override returns (string memory) {
    SurrogateStruct storage ss = SurrogateSlot.getSurrogateStorage();

    // check if it exists
    string memory principalURI = ss.PRINCIPAL.tokenURI(tokenId);
    if(ss.useTokenURIPassthrough)
      return principalURI;
    else
      return string(abi.encodePacked(ss.tokenURIPrefix, tokenId.toString(), ss.tokenURISuffix));
  }


  //ERC721Enumerable :: view
  function tokenByIndex(uint256 index) external view returns (uint256) {
    revert NotSupported();

    SurrogateStruct storage ss = SurrogateSlot.getSurrogateStorage();

    try ss.PRINCIPAL.tokenByIndex(index) returns (uint256 at) {
      return at;
    }
    // solhint-disable-next-line no-empty-blocks
    catch {}

    try ss.PRINCIPAL.ownerOf(index) returns (address) {
      return index;
    }
    // solhint-disable-next-line no-empty-blocks
    catch {}

    revert NotSupported();
  }

  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
    require(balanceOf(owner) > index, "ERC721Enumerable: owner index out of bounds" );

    uint256 count;
    uint256 tokenId;
    uint256 supply = totalSupply();
    for(tokenId = 0; tokenId < supply; ++tokenId){
      if(ownerOf(tokenId) == owner){
        if(index == count++)
          return tokenId;
      }
    }

    revert("ERC721Enumerable: owner index out of bounds");
  }

  function totalSupply() public view returns (uint256){
    SurrogateStruct storage ss = SurrogateSlot.getSurrogateStorage();

    try ss.PRINCIPAL.totalSupply() returns (uint256 supply) {
      return supply;
    }
    // solhint-disable-next-line no-empty-blocks
    catch {}

    if (ss._totalSupply > 0)
      return ss._totalSupply;

    revert NotSupported();
  }


  //ERC165
  function supportsInterface(bytes4 interfaceId) external pure override returns(bool){
    return interfaceId == type(IERC165).interfaceId
      || interfaceId == type(IERC721).interfaceId
      || interfaceId == type(IERC721Metadata).interfaceId
      || interfaceId == type(IERC721Enumerable).interfaceId;
  }


  //admin
  function setTokenURI(string calldata newPrefix, string calldata newSuffix, bool usePassthrough) external onlyOwner {
    SurrogateStruct storage ss = SurrogateSlot.getSurrogateStorage();

    ss.tokenURIPrefix = newPrefix;
    ss.tokenURISuffix = newSuffix;
    ss.useTokenURIPassthrough = usePassthrough;
  }

  function setTotalSupply(uint256 supply) external onlyOwner {
    SurrogateSlot.getSurrogateStorage()._totalSupply = supply;
  }


  //internal
  function _setSurrogate(uint256 tokenId, address principalOwner, address surrogateOwner) internal virtual {
    SurrogateStruct storage ss = SurrogateSlot.getSurrogateStorage();

    Token memory prev = ss._tokens[ tokenId ];
    if(prev.principal != principalOwner){
      if(prev.principal != address(0))
        ss._balances[prev.principal] += 1;
      
      ss._balances[principalOwner] -= 1;
    }

    if(prev.surrogate != surrogateOwner){
      if(prev.surrogate != address(0))
        ss._balances[prev.surrogate] -= 1;
      
      ss._balances[surrogateOwner] += 1;
    }

    ss._tokens[tokenId] = Token(principalOwner, surrogateOwner, true);
    emit Transfer(prev.surrogate, surrogateOwner, tokenId);
  }

  function _unsetSurrogate(uint256 tokenId, address principalOwner) internal virtual {
    SurrogateStruct storage ss = SurrogateSlot.getSurrogateStorage();

    Token memory prev = ss._tokens[ tokenId ];
    if(prev.isSet){
      ss._balances[prev.surrogate] -= 1;
      ss._balances[prev.principal] += 1;
    }

    ss._tokens[ tokenId ] = Token(principalOwner, principalOwner, false);
    emit Transfer(prev.surrogate, principalOwner, tokenId);
  }


  //internal - admin
  // solhint-disable-next-line no-empty-blocks
  function _authorizeUpgrade(address) internal virtual override onlyOwner {
    // owner check
  }
}