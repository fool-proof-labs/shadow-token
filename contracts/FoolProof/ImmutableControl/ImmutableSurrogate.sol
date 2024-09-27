
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { ERC721SurrogateUpgradeable } from "../FoolProofToken/ERC721SurrogateUpgradeable.sol";
import { FPTStorage } from "../FoolProofToken/FPTStorage.sol";

import { IImmutableControl, Proposal, Status } from "./IImmutableControl.sol";
import { IERC721Surrogate, IImmutableSurrogate } from "./IImmutableSurrogate.sol";


contract MadeByApesFPT is
  ERC721SurrogateUpgradeable,
  IImmutableSurrogate
{
  using FPTStorage for bytes32;

  struct DependentToken {
    uint256 dependentTokenId;
    address wallet;
    uint64 expires;
  }

  IERC721 private _dependentCollection;
  mapping(uint256 => DependentToken) private _tokens;


  function initialize(address principal) external override(IERC721Surrogate, ERC721SurrogateUpgradeable) initializer {
    __ERC721Surrogate_init(principal);
  }


  // admin  
  function adminSetSurrogate(uint256 tokenId, address wallet, uint64 expires, uint256 depTokenId) external onlyDelegates() {
    // require _dependentCollection
    // TODO: verify token ownership

    _tokens[tokenId] = DependentToken(
      depTokenId,
      wallet,
      expires
    );

    address principalOwner = PRINCIPAL().ownerOf(tokenId);
    if (wallet == principalOwner || wallet == address(0)) {
      _unsetSurrogate(tokenId, principalOwner);
    }
    else{
      _setSurrogate(tokenId, principalOwner, wallet);
    }
  }

  function adminUnsetSurrogate(uint256 tokenId) external onlyDelegates() {
    _unsetSurrogate(tokenId, PRINCIPAL().ownerOf(tokenId));
  }

  function setDependentCollection(address dependentCollection_) external {
    _dependentCollection = IERC721(dependentCollection_);
  }

  function ownerOf(uint256 tokenId) public override(IERC721Surrogate, ERC721SurrogateUpgradeable) view returns(address) {
    Proposal memory prop = IImmutableControl(address(PRINCIPAL())).proposal(tokenId);
    if (prop.status == Status.INVALID) {
      // revert ERC721NonexistentToken(tokenId);
      return address(0);
    }


    if (prop.status == Status.EXPIRED) {
      // revert ERC721NonexistentToken(tokenId);
      return address(0);
    }

    return super.ownerOf(tokenId);
  }
}
