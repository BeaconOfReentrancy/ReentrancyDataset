/**

 *Submitted for verification at Etherscan.io on 2018-10-30

*/



pragma solidity ^0.4.18;





// ----------------------------------------------------------------------------

// Safe maths

// ----------------------------------------------------------------------------

contract SafeMath {

    function safeAdd(uint a, uint b) public pure returns (uint c) {

        c = a + b;

        require(c >= a);

    }

    function safeSub(uint a, uint b) public pure returns (uint c) {

        require(b <= a);

        c = a - b;

    }

    function safeMul(uint a, uint b) public pure returns (uint c) {

        c = a * b;

        require(a == 0 || c / a == b);

    }

    function safeDiv(uint a, uint b) public pure returns (uint c) {

        require(b > 0);

        c = a / b;

    }

}





// ----------------------------------------------------------------------------

// ERC Token Standard #20 Interface

// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md

// ----------------------------------------------------------------------------

contract ERC20Interface {

    function totalSupply() public constant returns (uint);

    function balanceOf(address tokenOwner) public constant returns (uint balance);

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);

    function transfer(address to, uint tokens) public returns (bool success);

    function approve(address spender, uint tokens) public returns (bool success);

    function transferFrom(address from, address to, uint tokens) public returns (bool success);



    event Transfer(address indexed from, address indexed to, uint tokens);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    

        /* This notifies clients about the amount burnt */

    event Burn(address indexed from, uint256 value);

	

	/* This notifies clients about the amount frozen */

    event Freeze(address indexed from, uint256 value);

	

	/* This notifies clients about the amount unfrozen */

    event Unfreeze(address indexed from, uint256 value);

}





// ----------------------------------------------------------------------------

// Contract function to receive approval and execute function in one call

//

// Borrowed from MiniMeToken

// ----------------------------------------------------------------------------

contract ApproveAndCallFallBack {

    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;

}





// ----------------------------------------------------------------------------

// Owned contract

// ----------------------------------------------------------------------------

contract Owned {

    address public owner;

    address public newOwner;



    event OwnershipTransferred(address indexed _from, address indexed _to);



    function Owned() public {

        owner = msg.sender;

    }



    modifier onlyOwner {

        require(msg.sender == owner);

        _;

    }



    function transferOwnership(address _newOwner) public onlyOwner {

        newOwner = _newOwner;

    }

    function acceptOwnership() public {

        require(msg.sender == newOwner);

        OwnershipTransferred(owner, newOwner);

        owner = newOwner;

        newOwner = address(0);

    }

}





// ----------------------------------------------------------------------------

// ERC20 Token, with the addition of symbol, name and decimals and assisted

// token transfers

// ----------------------------------------------------------------------------

contract WealthChainToken is ERC20Interface, Owned, SafeMath {

    string public symbol;

    string public  name;

    uint8 public decimals;

    uint public _totalSupply;

    

    

    mapping (address => bool) public frozenAccount;

    mapping(address => uint) balances;

    mapping(address => mapping(address => uint)) allowed;

    

    event FrozenFunds(address target, bool frozen);





    // ------------------------------------------------------------------------

    // Constructor

    // ------------------------------------------------------------------------

    function WealthChainToken() public {

        symbol = "WCT";

        name = "Wealth Chain Token";

        decimals = 18;

        _totalSupply = 200000000000000000000000000;

        balances[0x6CC1d11751Efa9402Ed417696a134D1534272c91] = _totalSupply;

        Transfer(address(0), 0x6CC1d11751Efa9402Ed417696a134D1534272c91, _totalSupply);

    }





    // ------------------------------------------------------------------------

    // Total supply

    // ------------------------------------------------------------------------

    function totalSupply() public constant returns (uint) {

        return _totalSupply  - balances[address(0)];

    }





    // ------------------------------------------------------------------------

    // Get the token balance for account tokenOwner

    // ------------------------------------------------------------------------

    function balanceOf(address tokenOwner) public constant returns (uint balance) {

        return balances[tokenOwner];

    }



    function freezeAccount(address target, bool freeze) onlyOwner {

        frozenAccount[target] = freeze;

        emit FrozenFunds(target, freeze);

    }



    // ------------------------------------------------------------------------

    // Transfer the balance from token owner's account to to account

    // - Owner's account must have sufficient balance to transfer

    // - 0 value transfers are allowed

    // ------------------------------------------------------------------------

    function transfer(address to, uint tokens) public returns (bool success) {

        require(!frozenAccount[msg.sender]);

        balances[msg.sender] = safeSub(balances[msg.sender], tokens);

        balances[to] = safeAdd(balances[to], tokens);

        Transfer(msg.sender, to, tokens);

        return true;

    }

    

    function burn(uint256 _value) returns (bool success) {

        if (balances[msg.sender] < _value) throw; 

		if (_value <= 0) throw; 

        balances[msg.sender] = SafeMath.safeSub(balances[msg.sender], _value); 

        _totalSupply = SafeMath.safeSub(_totalSupply,_value);  

        Burn(msg.sender, _value);

        return true;

    }





    // ------------------------------------------------------------------------

    // Token owner can approve for spender to transferFrom(...) tokens

    // from the token owner's account

    //

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md

    // recommends that there are no checks for the approval double-spend attack

    // as this should be implemented in user interfaces 

    // ------------------------------------------------------------------------

    function approve(address spender, uint tokens) public returns (bool success) {

        allowed[msg.sender][spender] = tokens;

        Approval(msg.sender, spender, tokens);

        return true;

    }





    // ------------------------------------------------------------------------

    // Transfer tokens from the from account to the to account

    // 

    // The calling account must already have sufficient tokens approve(...)-d

    // for spending from the from account and

    // - From account must have sufficient balance to transfer

    // - Spender must have sufficient allowance to transfer

    // - 0 value transfers are allowed

    // ------------------------------------------------------------------------

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {

        balances[from] = safeSub(balances[from], tokens);

        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);

        balances[to] = safeAdd(balances[to], tokens);

        Transfer(from, to, tokens);

        return true;

    }





    // ------------------------------------------------------------------------

    // Returns the amount of tokens approved by the owner that can be

    // transferred to the spender's account

    // ------------------------------------------------------------------------

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {

        return allowed[tokenOwner][spender];

    }





    // ------------------------------------------------------------------------

    // Token owner can approve for spender to transferFrom(...) tokens

    // from the token owner's account. The spender contract function

    // receiveApproval(...) is then executed

    // ------------------------------------------------------------------------

    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {

        allowed[msg.sender][spender] = tokens;

        Approval(msg.sender, spender, tokens);

        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);

        return true;

    }





    // ------------------------------------------------------------------------

    // Don't accept ETH

    // ------------------------------------------------------------------------

    function () public payable {

        revert();

    }





    // ------------------------------------------------------------------------

    // Owner can transfer out any accidentally sent ERC20 tokens

    // ------------------------------------------------------------------------

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {

        return ERC20Interface(tokenAddress).transfer(owner, tokens);

    }

}