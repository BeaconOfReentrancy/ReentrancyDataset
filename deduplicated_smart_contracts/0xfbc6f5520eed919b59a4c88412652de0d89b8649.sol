/**

 *Submitted for verification at Etherscan.io on 2018-12-18

*/



pragma solidity ^0.4.23;



library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {

    if (a == 0) {

      return 0;

    }

    c = a * b;

    assert(c / a == b);

    return c;

  }



  function div(uint256 a, uint256 b) internal pure returns (uint256) {

    return a / b;

  }



  function sub(uint256 a, uint256 b) internal pure returns (uint256) {

    assert(b <= a);

    return a - b;

  }



  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {

    c = a + b;

    assert(c >= a);

    return c;

  }

}



contract Ownable {

  address public owner;



  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);



  modifier onlyOwner() {

    require(msg.sender == owner);

    _;

  }



  function transferOwnership(address newOwner) public onlyOwner {

    require(newOwner != address(0));

    emit OwnershipTransferred(owner, newOwner);

    owner = newOwner;

  }

}



contract ERC20Basic {

  function totalSupply() public view returns (uint256);

  function balanceOf(address who) public view returns (uint256);

  function transfer(address to, uint256 value) public returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

}



contract ERC20 is ERC20Basic {

  function allowance(address owner, address spender) public view returns (uint256);

  function transferFrom(address from, address to, uint256 value) public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);

  event Approval(address indexed owner, address indexed spender, uint256 value);

}



contract BasicToken is ERC20Basic {

  using SafeMath for uint256;



  mapping(address => uint256) balances;



  uint256 totalSupply_;



  function totalSupply() public view returns (uint256) {

    return totalSupply_;

  }



  function transfer(address _to, uint256 _value) public returns (bool) {

    require(_to != address(0));

    require(_value <= balances[msg.sender]);



    balances[msg.sender] = balances[msg.sender].sub(_value);

    balances[_to] = balances[_to].add(_value);

    emit Transfer(msg.sender, _to, _value);

    return true;

  }



  function balanceOf(address _owner) public view returns (uint256) {

    return balances[_owner];

  }

}



contract StandardToken is ERC20, BasicToken {



  mapping (address => mapping (address => uint256)) internal allowed;



  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

    require(_to != address(0));

    require(_value <= balances[_from]);

    require(_value <= allowed[_from][msg.sender]);



    balances[_from] = balances[_from].sub(_value);

    balances[_to] = balances[_to].add(_value);

    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

    emit Transfer(_from, _to, _value);

    return true;

  }



  function approve(address _spender, uint256 _value) public returns (bool) {

    allowed[msg.sender][_spender] = _value;

    emit Approval(msg.sender, _spender, _value);

    return true;

  }



  function allowance(address _owner, address _spender) public view returns (uint256) {

    return allowed[_owner][_spender];

  }



  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {

    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

    return true;

  }



  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {

    uint oldValue = allowed[msg.sender][_spender];

    if (_subtractedValue > oldValue) {

      allowed[msg.sender][_spender] = 0;

    } else {

      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);

    }

    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

    return true;

  }

}



contract iToken is StandardToken, Ownable {

  event Mint(address indexed to, uint256 amount);



  modifier hasMintPermission() {

    require(msg.sender == owner);

    _;

  }



  function mint(address _to, uint256 _amount) hasMintPermission public returns (bool) {

    totalSupply_ = totalSupply_.add(_amount);

    balances[_to] = balances[_to].add(_amount);

    emit Mint(_to, _amount);

    emit Transfer(address(0), _to, _amount);

    return true;

  }

}



contract CrowdsaleTokenConstructor is iToken {

  string public name;

  string public symbol;

  uint8 public constant decimals = 18;



  constructor(string _name, string _symbol, address _owner) public {

    name = _name;

    symbol = _symbol;

    owner = _owner;

  }

}