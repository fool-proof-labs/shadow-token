
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IOwnable} from "../Common/IOwnable.sol";
import {IERC721Surrogate} from "./IERC721Surrogate.sol";

contract ShadowRegistryUpgradeable is Initializable, OwnableUpgradeable, UUPSUpgradeable{
  error NotRegistered();
  error SenderNotOwner();
  error ShadowExists(address shadow);

  event ShadowRegistered(address indexed principal, address indexed surrogate);

  string public name;
  address public shadowImpl;
  uint8 public version;

  mapping(address => address) public principalOverrides;
  mapping(address => address) public shadows;

  function initialize() public initializer{
    __Ownable_init(msg.sender);
    __UUPSUpgradeable_init();
    _upgrade();
  } 

  function upgrade() public reinitializer(2){
    _upgrade();
  }

  function _upgrade() private{
    name = "ShadowRegistryUpgradeable v1";
    version = 1;
  }

  function deploy(address principal) external {
    if(shadows[principal] != address(0))
      revert ShadowExists(shadows[principal]);

    //if(msg.sender != IOwnable(principal).owner())
    //  revert SenderNotOwner();

    bytes memory _initialize = abi.encodeCall(IERC721Surrogate.initialize, (principal));
    ERC1967Proxy proxy = new ERC1967Proxy(shadowImpl, _initialize);
    emit ShadowRegistered(principal, address(proxy));

    address shadow = shadows[principal] = address(proxy);
    try IOwnable(shadow).transferOwnership(msg.sender) {}
    catch {}
  }

  function setPrincipalOverride(address shadow, address principal) external onlyOwner{
    if(shadows[principal] != address(0))
      principalOverrides[shadow] = principal;
    else
      revert NotRegistered();
  }

  function setShadow(address principal, address shadow) external onlyOwner{
    shadows[principal] = shadow;
    emit ShadowRegistered(principal, shadow);
  }

  function setShadowImpl(address impl) external onlyOwner{
    shadowImpl = impl;
  }

  function transferShadow(address shadow, address newOwner) external onlyOwner{
    IOwnable(shadow).transferOwnership(newOwner);
  }

  // view
  function principals(address shadow) external view returns(address){
    if(principalOverrides[shadow] != address(0))
      return principalOverrides[shadow];
    else 
      return IERC721Surrogate(shadow).getPrincipal();
  }


  //internal - admin
  function _authorizeUpgrade(address) internal override onlyOwner {
    // owner check
  }
}
