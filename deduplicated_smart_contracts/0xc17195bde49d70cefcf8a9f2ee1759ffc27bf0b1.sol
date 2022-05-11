/**

 *Submitted for verification at Etherscan.io on 2018-09-09

*/



pragma solidity ^0.4.18;



contract Ownable {

    address public owner;

    

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    

    function Ownable() public {

        owner = msg.sender;

    }

    

    modifier onlyOwner() {

        require(msg.sender == owner);

        _;

    }

    

    function transferOwnership(address newOwner) onlyOwner public {

        require(newOwner != address(0));

        OwnershipTransferred(owner, newOwner);

        owner = newOwner;

    }

}



contract Pausable is Ownable {

    bool public paused = false;

    

    event Pause();

    event Unpause();



    modifier whenNotPaused() {

        require(!paused);

        _;

    }

    

    modifier whenPaused() {

        require(paused);

        _;

    }

    

    function pause() onlyOwner whenNotPaused public {

        paused = true;

        Pause();

    }

    

    function unpause() onlyOwner whenPaused public {

        paused = false;

        Unpause();

    }

}



contract ERC20Basic {

    uint256 public totalSupply;

    function balanceOf(address who) public constant returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

}



contract BasicToken is ERC20Basic {

    using SafeMath for uint256;

    

    mapping(address => uint256) balances;

    

    function transfer(address _to, uint256 _value) public returns (bool) {

        require(_to != address(0));

        require(_value <= balances[msg.sender]);

        

        // SafeMath.sub will throw if there is not enough balance.

        balances[msg.sender] = balances[msg.sender].sub(_value);

        balances[_to] = balances[_to].add(_value);

        Transfer(msg.sender, _to, _value);

        return true;

    }

    

    function balanceOf(address _owner) public constant returns (uint256 balance) {

        return balances[_owner];

    }

}



contract ERC20 is ERC20Basic {

    function allowance(address owner, address spender) public constant returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);

}



library SafeERC20 {

    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {

        assert(token.transfer(to, value));

    }

    

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {

        assert(token.transferFrom(from, to, value));

    }

    

    function safeApprove(ERC20 token, address spender, uint256 value) internal {

        assert(token.approve(spender, value));

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

        Transfer(_from, _to, _value);

        return true;

    }



    function approve(address _spender, uint256 _value) public returns (bool) {

        allowed[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);

        return true;

    }



    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {

        return allowed[_owner][_spender];

    }



    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {

        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;

    }



    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {

        uint oldValue = allowed[msg.sender][_spender];

        

        if (_subtractedValue > oldValue) {

            allowed[msg.sender][_spender] = 0;

        } else {

            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);

        }

        

        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;

    }

}

  

contract LockableToken is StandardToken, Ownable {

    mapping (address => uint256) internal lockaddress;

    

    event Lock(address indexed locker, uint256 time);

    

    function lockStatus(address _address) public constant returns(uint256) {

        return lockaddress[_address];

    }

    

    function lock(address _address, uint256 _time) onlyOwner public {

        require(_time > now);

        

        lockaddress[_address] = _time;

        Lock(_address, _time);

    }

    

    modifier isNotLocked() {

        require(lockaddress[msg.sender] < now || lockaddress[msg.sender] == 0);

        _;

    }

}

  

contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

    

    function burn(uint256 _value) public {

        require(_value > 0);

        require(_value <= balances[msg.sender]);

        

        address burner = msg.sender;

        balances[burner] = balances[burner].sub(_value);

        totalSupply = totalSupply.sub(_value);

        Burn(burner, _value);

    }

}



contract PausableToken is StandardToken, LockableToken, Pausable {

    modifier whenNotPausedOrOwner() {

        require(msg.sender == owner || !paused);

        _;

    }

    

    function transfer(address _to, uint256 _value) public whenNotPausedOrOwner isNotLocked returns (bool) {

        return super.transfer(_to, _value);

    }

    

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPausedOrOwner isNotLocked returns (bool) {

        return super.transferFrom(_from, _to, _value);

    }

    

    function approve(address _spender, uint256 _value) public whenNotPausedOrOwner isNotLocked returns (bool) {

        return super.approve(_spender, _value);

    }

    

    function increaseApproval(address _spender, uint _addedValue) public whenNotPausedOrOwner isNotLocked returns (bool success) {

        return super.increaseApproval(_spender, _addedValue);

    }

    

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPausedOrOwner isNotLocked returns (bool success) {

        return super.decreaseApproval(_spender, _subtractedValue);

    }

}



contract Groocoin is PausableToken, BurnableToken {

    string constant public name = "Groocoin";

    string constant public symbol = "GROO";

    uint256 constant public decimals = 18;

    uint256 constant TOKEN_UNIT = 10 ** uint256(decimals);

    uint256 constant INITIAL_SUPPLY = 30000000000 * TOKEN_UNIT;

    

    function Groocoin() public {

        paused = true;

        

        totalSupply = INITIAL_SUPPLY;

        Transfer(0x0, msg.sender, INITIAL_SUPPLY);

        balances[msg.sender] = INITIAL_SUPPLY;

    }

}



library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        uint256 c = a * b;

        assert(a == 0 || c / a == b);

        return c;

    }

    

    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        uint256 c = a / b;

        return c;

    }

    

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {

        assert(b <= a);

        return a - b;

    }

    

    function add(uint256 a, uint256 b) internal pure returns (uint256) {

        uint256 c = a + b;

        assert(c >= a);

        return c;

    }

}