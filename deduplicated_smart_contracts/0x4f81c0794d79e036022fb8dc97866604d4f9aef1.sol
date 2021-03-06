/**

 *Submitted for verification at Etherscan.io on 2018-09-09

*/



pragma solidity ^0.4.11;



contract SafeMath {

  function safeMul(uint a, uint b) internal returns (uint) {

    uint c = a * b;

    assert(a == 0 || c / a == b);

    return c;

  }



  function safeSub(uint a, uint b) internal returns (uint) {

    assert(b <= a);

    return a - b;

  }



  function safeAdd(uint a, uint b) internal returns (uint) {

    uint c = a + b;

    assert(c>=a && c>=b);

    return c;

  }



  function assert(bool assertion) internal {

    if (!assertion) throw;

  }

}



contract Ownable {

  address public owner;





  /**

   * @dev The Ownable constructor sets the original `owner` of the contract to the sender

   * account.

   */

  function Ownable() {

    owner = msg.sender;

  }





  /**

   * @dev Throws if called by any account other than the owner.

   */

  modifier onlyOwner() {

    if (msg.sender != owner) {

      throw;

    }

    _;

  }





  /**

   * @dev Allows the current owner to transfer control of the contract to a newOwner.

   * @param newOwner The address to transfer ownership to.

   */

  function transferOwnership(address newOwner) onlyOwner {

    if (newOwner != address(0)) {

      owner = newOwner;

    }

  }



}



contract ERC20Basic {

  uint public totalSupply;

  function balanceOf(address who) constant returns (uint);

  function transfer(address to, uint value);

  event Transfer(address indexed from, address indexed to, uint value);

}



contract ERC20 is ERC20Basic {

  function allowance(address owner, address spender) constant returns (uint);

  function transferFrom(address from, address to, uint value);

  function approve(address spender, uint value);

  event Approval(address indexed owner, address indexed spender, uint value);

}





contract BitcoinStore is Ownable, SafeMath {



  address constant public Bitcoin_address = 0xB6eD7644C69416d67B522e20bC294A9a9B405B31;

  uint token_price = 35e14; // 0.0035 eth starting price 



  function getPrice()

  public

  view

  returns (uint)

  {

      return token_price;

  }



  function update_price(uint new_price)

  onlyOwner

  {

      token_price = new_price;

  }



  function send(address _tokenAddr, address dest, uint value)

  onlyOwner

  {

      ERC20(_tokenAddr).transfer(dest, value);

  }



  function multisend(address _tokenAddr, address[] dests, uint[] values)

  onlyOwner

  returns (uint) {

      uint i = 0;

      while (i < dests.length) {

         ERC20(_tokenAddr).transfer(dests[i], values[i]);

         i += 1;

      }

      return(i);

  }



  /* fallback function for when ether is sent to the contract */

  function () external payable {

      uint buytokens = msg.value / token_price;

      ERC20(Bitcoin_address).transfer(msg.sender, buytokens);

  }



  function buy() public payable {

      uint buytokens = msg.value / token_price;

      ERC20(Bitcoin_address).transfer(msg.sender, buytokens);

  }



  function withdraw() onlyOwner {

      msg.sender.transfer(this.balance);

  }

}