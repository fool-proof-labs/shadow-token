
// SPDX-License-Identifier: BSD-3
pragma solidity ^0.8.9;

interface IOwnable{
  function owner() external view returns(address);
  function transferOwnership(address newOwner) external;
}