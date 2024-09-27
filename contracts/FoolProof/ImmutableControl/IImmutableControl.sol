
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

enum Status {
  NONE,     //0
  SUBMITTED, //1
  WITHDRAWN, //2
  DENIED,   //3
  APPROVED, //4 LICENSED
  INVALID,  //5
  EXPIRED,  //6
  REVOKED,  //7
  VIOLATED  //8
}

struct Proposal {
  uint256 baycTokenId;
  address wallet;
  uint64 expires;
  Status status;
  string name;         // TODO: use events?
  string description;  // TODO: use events?
}

interface IImmutableControl {
  function initialize(address baycAddress) external;

  // admin
  function approve(uint256 tokenId, uint64 expires, bytes calldata data) external;
  function deny(uint256 tokenId, bytes calldata data) external;
  function revoke(uint256 tokenId, bytes calldata data) external;

  // user
  function propose(uint256 tokenId, string calldata name, string calldata description) external;
  function withdraw(uint256 tokenId) external;

  // view
  function proposal(uint256 tokenId) external view returns(Proposal memory);
}
