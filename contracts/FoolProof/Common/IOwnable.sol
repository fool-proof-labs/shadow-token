
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IOwnable{
  function owner() external view returns(address);
  function transferOwnership(address newOwner) external;
}