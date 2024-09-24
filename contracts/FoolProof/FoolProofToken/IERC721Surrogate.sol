
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IERC721Surrogate is IERC721Metadata, IERC721Enumerable {
  error AlreadyOwner();
  error NotAuthorized();
  error NotSupported();

  //IERC721Surrogate
  function initialize(address _principal) external;

  function setSurrogate(uint256 tokenId, address surrogate) external;
  function setSurrogates(uint256[] calldata tokenIds, address[] calldata surrogates) external;

  function softSync(uint256 tokenId) external;
  function softSync(uint256[] calldata tokenIds) external;

  function syncSurrogate(uint256 tokenId) external;
  function syncSurrogates(uint256[] calldata tokenIds) external;

  function unsetSurrogate(uint256 tokenId) external;
  function unsetSurrogates(uint256[] calldata tokenIds) external;

  function getPrincipal() external view returns(address);
  function implementation() external view returns(uint8);
  function version() external view returns(uint8);


  //IERC721
  function balanceOf(address owner) external view returns (uint256 balance);
  function ownerOf(uint256 tokenId) external view returns (address owner);

  //IERC721Metadata
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function tokenURI(uint256 tokenId) external view returns (string memory);

  //IER721Enumerable
  function tokenByIndex(uint256 index) external view returns (uint256);
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
  function totalSupply() external view returns (uint256);
}
