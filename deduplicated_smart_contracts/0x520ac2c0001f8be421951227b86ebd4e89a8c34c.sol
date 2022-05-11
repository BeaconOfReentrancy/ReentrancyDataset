/**
 *Submitted for verification at Etherscan.io on 2019-09-20
*/

pragma solidity ^0.5.7;
contract MarginParent {
  bytes constant _margin_swap_compiled = hex"608060405234801561001057600080fd5b50604051610faf380380610faf8339818101604052608081101561003357600080fd5b8101908080519060200190929190805190602001909291908051906020019092919080519060200190929190505050836000558260015581600255806003556001740100000000000000000000000000000000000000045550505050610f118061009e6000396000f3fe6080604052600436106100705760003560e01c806357aee3661161004e57806357aee366146101455780635ccbf176146101d657806369328dec14610305578063c29982381461038057610070565b80632d891fba14610072578063439370b1146100ed57806347e7ef24146100f7575b005b34801561007e57600080fd5b506100eb6004803603606081101561009557600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff16906020019092919080359060200190929190803573ffffffffffffffffffffffffffffffffffffffff169060200190929190505050610406565b005b6100f56104ac565b005b6101436004803603604081101561010d57600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff169060200190929190803590602001909291905050506104b9565b005b34801561015157600080fd5b506101946004803603602081101561016857600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff169060200190929190505050610562565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b610303600480360360c08110156101ec57600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff16906020019092919080359060200190929190803573ffffffffffffffffffffffffffffffffffffffff16906020019092919080359060200190929190803573ffffffffffffffffffffffffffffffffffffffff1690602001909291908035906020019064010000000081111561027d57600080fd5b82018360208201111561028f57600080fd5b803590602001918460018302840111640100000000831117156102b157600080fd5b91908080601f016020809104026020016040519081016040528093929190818152602001838380828437600081840152601f19601f820116905080830192505050505050509192919290505050610570565b005b34801561031157600080fd5b5061037e6004803603606081101561032857600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff16906020019092919080359060200190929190803573ffffffffffffffffffffffffffffffffffffffff16906020019092919050505061087b565b005b34801561038c57600080fd5b50610404600480360360208110156103a357600080fd5b81019080803590602001906401000000008111156103c057600080fd5b8201836020820111156103d257600080fd5b803590602001918460208302840111640100000000831117156103f457600080fd5b90919293919293905050506108a0565b005b61040e610e54565b610416610e76565b60005433181561042b5760016020526001603ffd5b600084848715610470577fa9059cbb00000000000000000000000000000000000000000000000000000000855285600486015286602486015287905060449250600091505b602084848785855af1806104895760026020526001603ffd5b88156104a15784516104a05760036020526001603ffd5b5b505050505050505050565b6104b76000346104b9565b565b6104c1610e98565b6104c9610e76565b348318841516156104df5760016020526001603ffd5b83156105525734156104f65760026020526001603ffd5b7f23b872dd000000000000000000000000000000000000000000000000000000008252336004830152306024830152826044830152600081526020816064846000885af1815115811517156105505760036020526001603ffd5b505b61055c8484610a80565b50505050565b600081600401549050919050565b610578610e54565b610580610e76565b600080543318156105965760006020526001603ffd5b6002740100000000000000000000000000000000000000045414156105c05760016020526001603ffd5b600274010000000000000000000000000000000000000004556001547f0a681c590000000000000000000000000000000000000000000000000000000084528960048501528860248501526000806044866000855af1806106265760026020526001603ffd5b50891561069457341561063e5760036020526001603ffd5b7f095ea7b30000000000000000000000000000000000000000000000000000000084528560048501528860248501526000835260208360448660008e5af1835115811517156106925760046020526001603ffd5b505b303188156106e8577f70a08231000000000000000000000000000000000000000000000000000000008552336004860152600084526020846024878c5afa806106e25760056020526001603ffd5b50835190505b863b6106f95760056020526001603ffd5b600080875160208901348b5af1806107165760076020526001603ffd5b507f095ea7b3000000000000000000000000000000000000000000000000000000008552866004860152600060248601526000845260208460448760008f5af18451158115171561076c5760086020526001603ffd5b50303189156107c1577f70a08231000000000000000000000000000000000000000000000000000000008652336004870152600085526020856024888d5afa806107bb5760096020526001603ffd5b50845190505b818110156107d457600a6020526001603ffd5b8181039350888410156107ec57600b6020526001603ffd5b5050506107f98782610a80565b60008060c88a04915089820190506108148b82600154610ca1565b600174010000000000000000000000000000000000000004558a8552886020860152896040860152826060860152816080860152867f4a2af5744adbfadba82ab831aea212bad92f5a70fef2079562044f423e99985160a087a25050505050505050505050565b6000543318156108905760016020526001603ffd5b61089b838383610ca1565b505050565b6000543318156108b55760006020526001603ffd5b600435602018156108cb5760016020526001603ffd5b6024356044368260200260440118156108e95760026020526001603ffd5b6040513680600083376004810382828460006002545af1806109105760036020526001603ffd5b8251602018156109255760046020526001603ffd5b602083015185181561093c5760056020526001603ffd5b6000805b868110156109635760208102604086010151808317925050600181019050610940565b5080156109755760066020526001603ffd5b50505050600354602083028201825b81811015610a775780356040516004810160008152858318156109df577f6f307dc3000000000000000000000000000000000000000000000000000000008252602081600484865afa806109dd5760076020526001603ffd5b505b80518381600401558015610a68577f095ea7b30000000000000000000000000000000000000000000000000000000083528360048401527fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff602484015260448301600081526020816044866000865af181511581151715610a655760086020526001603ffd5b50505b50505050602081019050610984565b50505050505050565b610a88610eba565b610a90610e76565b836004015480610aa55760646020526001603ffd5b7f17bfdfbc0000000000000000000000000000000000000000000000000000000083523060048401526020826024856000855af180610ae95760656020526001603ffd5b5060035482518080871015610afc578690505b8015610bcc577f4e4d9fea00000000000000000000000000000000000000000000000000000000865260048184861815610b62577f0e75270200000000000000000000000000000000000000000000000000000000885282600489015260249150600090505b602087838a848a5af180610b7b5760666020526001603ffd5b3d60008114610b975760208114610baf5760696020526001603ffd5b86881815610baa5760676020526001603ffd5b610bc2565b885115610bc15760686020526001603ffd5b5b50838a0399505050505b50508415610c99577f1249c58b00000000000000000000000000000000000000000000000000000000845260048582841815610c34577fa0712d6800000000000000000000000000000000000000000000000000000000865286600487015260249150600090505b602085838884885af180610c4d57606a6020526001603ffd5b3d60008114610c695760208114610c8157606d6020526001603ffd5b84861815610c7c57606b6020526001603ffd5b610c94565b865115610c9357606c6020526001603ffd5b5b505050505b505050505050565b610ca9610eba565b610cb1610e76565b846004015480610cc65760c86020526001603ffd5b847f3af9e6690000000000000000000000000000000000000000000000000000000084523060048501526020836024866000865af180610d0b5760c96020526001603ffd5b5082518080831015610d1b578290505b8015610d7e577f852a12e30000000000000000000000000000000000000000000000000000000086528060048701526020856024886000885af180610d655760ca6020526001603ffd5b855115610d775760cb6020526001603ffd5b8184039350505b50508015610dd1577fc5ebeaec0000000000000000000000000000000000000000000000000000000084528060048501526020836024866000865af1835181151715610dcf5760cc6020526001603ffd5b505b600086868915610e16577fa9059cbb00000000000000000000000000000000000000000000000000000000875287600488015288602488015289905060449250600091505b602086848985855af180610e2f5760cd6020526001603ffd5b8a15610e47578651610e465760ce6020526001603ffd5b5b5050505050505050505050565b6040518060600160405280600390602082028038833980820191505090505090565b6040518060200160405280600190602082028038833980820191505090505090565b6040518060800160405280600490602082028038833980820191505090505090565b604051806040016040528060029060208202803883398082019150509050509056fea265627a7a72305820503959851dedd176dfcca1317ff48977fb16045d1ed8a4e0ee153aa6d10b87db64736f6c634300050a0032";
  address _manager_address;
  address _manager_proposed;
  address _comptroller_address;
  address _cEther_address;
  uint256[2**160] _white_listed_addresses;
  address public _last_create_address;
  
  constructor(address comptroller_address, address cEther_address) public payable  {
    assembly {
      sstore(_comptroller_address_slot, comptroller_address)
      sstore(_cEther_address_slot, cEther_address)
      sstore(_manager_address_slot, caller)
      sstore(add(_white_listed_addresses_slot, caller), 1)
    }
  }
  
  function () external payable  {}
  
  function managerPropose(address new_manager) external  {
    assembly {
      if xor(caller, sload(_manager_address_slot)) {
        mstore(32, 1)
        revert(63, 1)
      }
      sstore(_manager_proposed_slot, new_manager)
    }
  }
  
  function managerSet() external  {
    assembly {
      let proposed := sload(_manager_proposed_slot)
      if xor(caller, proposed) {
        mstore(32, 1)
        revert(63, 1)
      }
      sstore(add(_white_listed_addresses_slot, sload(_manager_address_slot)), 0)
      sstore(add(_white_listed_addresses_slot, proposed), 1)
      sstore(_manager_address_slot, proposed)
    }
  }
  
  function setupMargin() external 
  returns (address margin_contract) {
    bytes memory margin_swap_compiled = _margin_swap_compiled;
    assembly {
      let compiled_bytes := mload(margin_swap_compiled)
      let contract_start := add(margin_swap_compiled, 0x20)
      let cursor := add(contract_start, compiled_bytes)
      mstore(cursor, caller)
      cursor := add(cursor, 0x20)
      mstore(cursor, address)
      cursor := add(cursor, 0x20)
      mstore(cursor, sload(_comptroller_address_slot))
      cursor := add(cursor, 0x20)
      mstore(cursor, sload(_cEther_address_slot))
      cursor := add(cursor, 0x20)
      mstore(0x40, cursor)
      let contract_size := sub(cursor, contract_start)
      margin_contract := create2(0, contract_start, contract_size, caller)
      if iszero(margin_contract) {
        mstore(32, 1)
        revert(63, 1)
      }
      sstore(_last_create_address_slot, margin_contract)
      sstore(add(_white_listed_addresses_slot, margin_contract), 1)
    }
  }
  
  function isMarginSetup(address owner) public view 
  returns (address margin_contract, bool enabled) {
    margin_contract = getMarginAddress(owner);
    assembly {
      enabled := sload(add(_white_listed_addresses_slot, margin_contract))
    }
  }
  
  function getMarginAddress(address owner) public view 
  returns (address margin_contract) {
    bytes memory margin_swap_compiled = _margin_swap_compiled;
    assembly {
      let compiled_bytes := mload(margin_swap_compiled)
      let contract_start := add(margin_swap_compiled, 0x20)
      let cursor := add(contract_start, compiled_bytes)
      mstore(cursor, owner)
      cursor := add(cursor, 0x20)
      mstore(cursor, address)
      cursor := add(cursor, 0x20)
      mstore(cursor, sload(_comptroller_address_slot))
      cursor := add(cursor, 0x20)
      mstore(cursor, sload(_cEther_address_slot))
      cursor := add(cursor, 0x20)
      mstore(0x40, cursor)
      let contract_size := sub(cursor, contract_start)
      let contract_hash := keccak256(contract_start, contract_size)
      mstore(margin_swap_compiled, or(shl(0xa0, 0xff), address))
      mstore(add(margin_swap_compiled, 0x20), owner)
      mstore(add(margin_swap_compiled, 0x40), contract_hash)
      let address_hash := keccak256(add(margin_swap_compiled, 11), 85)
      margin_contract := and(address_hash, 0xffffffffffffffffffffffffffffffffffffffff)
    }
  }
  
  function getCapital(address asset, uint256 amount) external  {
    
    uint256[3] memory m_in;
    
    uint256[1] memory m_out;
    assembly {
      if iszero(sload(add(_white_listed_addresses_slot, caller))) {
        mstore(32, 1)
        revert(63, 1)
      }
      let m_in_size := 0
      let wei_to_send := amount
      let dest := caller
      if asset {
        mstore(m_in, /* fn_hash("transfer(address,uint256)") */ 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
        mstore(add(m_in, 4), caller)
        mstore(add(m_in, 0x24), amount)
        dest := asset
        m_in_size := 0x44
        wei_to_send := 0
      }
      let result := call(gas, dest, wei_to_send, m_in, m_in_size, m_out, 32)
      if iszero(result) {
        mstore(32, 2)
        revert(63, 1)
      }
      if asset {
        if iszero(mload(m_out)) {
          mstore(32, 3)
          revert(63, 1)
        }
      }
    }
  }
}