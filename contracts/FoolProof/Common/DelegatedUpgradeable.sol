
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract DelegatedUpgradeable is OwnableUpgradeable{
  event DelegateUpdate(address indexed account, bool indexed isAuthorized);

  error NotEOA();
  error NotAContract();
  error UnauthorizedDelegate();

  // TODO: explicit slot
  mapping(address => bool) internal _delegates;

  modifier onlyContractDelegates {
    if(!_delegates[msg.sender]) revert UnauthorizedDelegate();
    if(!_isContract(msg.sender)) revert NotAContract();

    _;
  }

  modifier onlyDelegates {
    if(!_delegates[msg.sender]) revert UnauthorizedDelegate();

    _;
  }

  modifier onlyEOADelegates {
    if(!_delegates[msg.sender]) revert UnauthorizedDelegate();
    if(_isContract(msg.sender)) revert NotEOA();

    _;
  }


  // solhint-disable-next-line func-name-mixedcase
  function __Delegated_init() internal onlyInitializing {
    __Ownable_init_unchained(msg.sender);
    setDelegate(owner(), true);
  }

  //onlyOwner
  function isDelegate(address addr) external view onlyOwner returns(bool) {
    return _delegates[addr];
  }

  function setDelegate(address addr, bool isDelegate_) public onlyOwner {
    _delegates[addr] = isDelegate_;
    emit DelegateUpdate(addr, isDelegate_);
  }

  function transferOwnership(address newOwner) public virtual override onlyOwner {
    setDelegate(newOwner, true);
    super.transferOwnership(newOwner);
  }

  function _isContract(address _addr) private view returns (bool) {
    uint32 size;
    assembly {
      size := extcodesize(_addr)
    }
    return (size > 0);
  }
}
