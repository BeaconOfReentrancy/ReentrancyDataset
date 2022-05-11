// solium-disable linebreak-style
pragma solidity ^0.4.24;

import "./SafeMath.sol";

/**
* ERC Token Standard #20 Interface
* https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
 */
contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract ERC20Base is ERC20Interface {
    using SafeMath for uint256;

    string public symbol;
    string public name;
    uint8 public decimals;
    uint public totalSupply_;
    address public owner;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    /** 
    * @dev Constructor
    */
    constructor(address _owner) public {
        symbol = "ABM";
        name = "ABMatrix Shareholding Token";
        decimals = 18;
        totalSupply_ = 1 * (10 ** 7) * (10 ** 18);
        owner = _owner;
        balances[owner] = totalSupply_;
        emit Transfer(address(0), owner, totalSupply_);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint _value) public returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
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

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Destoys `amount` tokens, reducing the total supply.
     * @param _account the address which to burn.
     * @param _amount must have at least `amount` tokens.
     */
    function burn(address _account, uint256 _amount) public onlyOwner {
        require(_account != address(0), "burn to the zero address");
        
        totalSupply_ = totalSupply_.sub(_amount);
        balances[_account] = balances[_account].sub(_amount);
        emit Transfer(_account, address(0), _amount);
    }

    /** 
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     * @param _account the address which to fund.
     * @param _amount the amount of funds.
     */
    function mint(address _account, uint256 _amount) public onlyOwner {
        require(_account != address(0), "mint to the zero address");

        totalSupply_ = totalSupply_.add(_amount);
        balances[_account] = balances[_account].add(_amount);
        emit Transfer(address(0), _account, _amount);
    }
}

contract Token is ERC20Base {
    constructor() public
        ERC20Base(0x68307D03aaD558716061762b9B62F0F5d17C5c4a)
    {
    }
}