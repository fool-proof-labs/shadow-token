
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC721EnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { DelegatedUpgradeable } from "../Common/DelegatedUpgradeable.sol";
import { IERC721Principal } from "../FoolProofToken/IERC721Principal.sol";
import { IERC721Surrogate } from "../FoolProofToken/IERC721Surrogate.sol";

import { IImmutableControl, Proposal, Status } from "./IImmutableControl.sol";
import { IImmutableSurrogate } from "./IImmutableSurrogate.sol";


contract ImmutableControl is
  ERC721EnumerableUpgradeable,
  DelegatedUpgradeable,
  UUPSUpgradeable,
  IImmutableControl,
  IERC721Principal
{
  error FPTUnset();
  error NotProposer();
  error OwnershipCheckFailed();

  event ProposalSubmitted(uint256 indexed tokenId, address indexed wallet, string name, string description);
  event ProposalUpdated(uint256 indexed tokenId, address indexed wallet, Status status, uint64 expires);

  // TODO: explicit slot
  IERC721 private _bayc;
  IImmutableSurrogate private _fpt;
  uint256 private _supply;

  // NOTE: tokens are proposals
  mapping(uint256 => Proposal) public _tokens;

  constructor(){}

  function initialize(address baycAddress) external initializer {
    __Delegated_init();
    __ERC721_init("Made by Apes", "MBA");

    // TODO: __MBA_init();
    _bayc = IERC721(baycAddress);
    _supply = 1;
  }


  // admin
  function approve(uint256 tokenId, uint64 expires, bytes calldata) external onlyEOADelegates() {
    if (address(_fpt) == address(0))
      revert FPTUnset();

    // TODO: admins cannot approve their own proposals

    Proposal storage aProposal = _tokens[tokenId];
    aProposal.expires = expires;
    aProposal.status = Status.APPROVED;
    emit ProposalUpdated(tokenId, aProposal.wallet, aProposal.status, expires);

    _fpt.adminSetSurrogate(tokenId, aProposal.wallet, aProposal.expires, aProposal.baycTokenId);
  }

  function deny(uint256 tokenId, bytes calldata) external onlyEOADelegates() {
    if (address(_fpt) == address(0))
      revert FPTUnset();

    Proposal storage dProposal = _tokens[tokenId];
    dProposal.expires = uint64(block.timestamp);
    dProposal.status = Status.DENIED;
    emit ProposalUpdated(tokenId, dProposal.wallet, dProposal.status, dProposal.expires);
  }

  // TODO: Revoke status:
  // - Revoked: generic
  // - Expired: time based
  // - Violated: action based
  function revoke(uint256 tokenId, bytes calldata) external onlyEOADelegates() {
    if (address(_fpt) == address(0))
      revert FPTUnset();

    Proposal storage rProposal = _tokens[tokenId];
    rProposal.expires = uint64(block.timestamp);
    rProposal.status = Status.REVOKED;
    emit ProposalUpdated(tokenId, rProposal.wallet, rProposal.status, rProposal.expires);

    _fpt.adminUnsetSurrogate(tokenId);
  }

  function setFPT(address fpt) external onlyEOADelegates {
    _fpt = IImmutableSurrogate(fpt);
  }


  // user
  function propose(uint256 baycTokenId, string calldata name, string calldata description) external {
    if (_bayc.ownerOf(baycTokenId) != msg.sender)
      revert OwnershipCheckFailed();


    uint256 tokenId = _supply++;
    _tokens[tokenId] = Proposal(
      baycTokenId,
      msg.sender,
      0,
      Status.SUBMITTED,
      name,
      description
    );

    _mint(owner(), tokenId);
    _update(owner(), tokenId, address(0));

    emit ProposalSubmitted(tokenId, msg.sender, name, description);
    emit ProposalUpdated(tokenId, msg.sender, Status.SUBMITTED, 0);
  }

  function withdraw(uint256 tokenId) external {
    Proposal storage wProposal = _tokens[tokenId];
    if (wProposal.wallet != msg.sender)
      revert NotProposer();


    wProposal.status = Status.WITHDRAWN;
    emit ProposalUpdated(tokenId, wProposal.wallet, wProposal.status, 0);
  }


  // view
  function proposal(uint256 tokenId) public view returns(Proposal memory) {
    // TODO: exists
    Proposal memory prop = _tokens[tokenId];
    if(prop.status != Status.APPROVED)
      return prop;


    // else, is the proposal not expired
    if(prop.expires < block.timestamp){
      prop.status = Status.EXPIRED;
      return prop;
    }

    // else, is the BAYC token still owned by this wallet?
    if(_bayc.ownerOf(prop.baycTokenId) != prop.wallet){
      prop.status = Status.INVALID;
      return prop;
    }

    // else, ok
    return prop;
  }

  function proposals(uint256[] calldata tokenIds) external view returns(Proposal[] memory) {
    Proposal[] memory _proposals = new Proposal[](tokenIds.length);
    for(uint256 i = 0; i < tokenIds.length; ++i) {
      _proposals[i] = proposal(tokenIds[i]);
    }
    return _proposals;
  }


  //Upgrade authorization
  // solhint-disable-next-line no-empty-blocks
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
