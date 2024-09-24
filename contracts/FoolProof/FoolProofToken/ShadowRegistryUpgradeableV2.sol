
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {IOwnable} from "../Common/IOwnable.sol";
import {IERC721Surrogate} from "./IERC721Surrogate.sol";

contract ShadowRegistryUpgradeableV2 is Initializable, OwnableUpgradeable, UUPSUpgradeable{
  error NotRegistered();
  error SenderNotOwner();
  error ShadowExists(address shadow);

  event ShadowRegistered(address indexed principal, address indexed surrogate, string name, string symbol);

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
    name = "ShadowRegistryUpgradeable v2";
    version = 2;
  }

  function deploy(address principal) external {
    if(shadows[principal] != address(0))
      revert ShadowExists(shadows[principal]);

    //if(msg.sender != IOwnable(principal).owner())
    //  revert SenderNotOwner();

    bytes memory _initialize = abi.encodeCall(IERC721Surrogate.initialize, (principal));
    ERC1967Proxy proxy = new ERC1967Proxy(shadowImpl, _initialize);
    address shadow = shadows[principal] = address(proxy);

    // solhint-disable-next-line no-empty-blocks
    try IOwnable(shadow).transferOwnership(msg.sender) {} catch {}

    string memory name_ = getName(principal);
    string memory symbol_ = getSymbol(principal);
    emit ShadowRegistered(principal, address(proxy), name_, symbol_);
  }

  function setPrincipalOverride(address shadow, address principal) external onlyOwner{
    if(shadows[principal] != address(0))
      principalOverrides[shadow] = principal;
    else
      revert NotRegistered();
  }

  function setShadow(
    address principal,
    address shadow,
    string memory name_,
    string memory symbol
  ) external onlyOwner{
    shadows[principal] = shadow;
    emit ShadowRegistered(principal, shadow, name_, symbol);
  }

  function setShadowImpl(address impl) external onlyOwner{
    shadowImpl = impl;
  }

  function transferShadow(address shadow, address newOwner) public onlyOwner{
    IOwnable(shadow).transferOwnership(newOwner);
  }


  // view
  function getName(address principal) public view returns(string memory name_) {
    try IERC721Metadata(principal).name() returns (string memory tmpName) {
      name_ = tmpName;
    }
    // solhint-disable-next-line no-empty-blocks
    catch {}
  }

  function getSymbol(address principal) public view returns(string memory symbol_) {
    try IERC721Metadata(principal).symbol() returns (string memory tmpSymbol) {
      symbol_ = tmpSymbol;
    }
    // solhint-disable-next-line no-empty-blocks
    catch {}
  }

  function principals(address shadow) external view returns(address){
    if(principalOverrides[shadow] != address(0))
      return principalOverrides[shadow];
    else 
      return IERC721Surrogate(shadow).getPrincipal();
  }


  //internal - admin
  // solhint-disable-next-line no-empty-blocks
  function _authorizeUpgrade(address) internal override onlyOwner {}
}
