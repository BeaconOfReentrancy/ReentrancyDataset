/**

 *Submitted for verification at Etherscan.io on 2018-12-18

*/



pragma solidity ^0.4.4;



// File: contracts/Migrations.sol



contract Migrations {

  address public owner;

  uint public last_completed_migration;



  modifier restricted() {

    if (msg.sender == owner) _;

  }



  function Migrations() public {

    owner = msg.sender;

  }



  function setCompleted(uint completed) restricted public {

    last_completed_migration = completed;

  }



  function upgrade(address new_address) restricted public {

    Migrations upgraded = Migrations(new_address);

    upgraded.setCompleted(last_completed_migration);

  }

}