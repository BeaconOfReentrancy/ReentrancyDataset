/**
 *Submitted for verification at Etherscan.io on 2019-07-26
*/

pragma solidity ^0.5.10;
 
contract IMigrationContract {
    function migrate(address addr, uint256 nas) external returns (bool success);
}
 
/* ??????????NAS  coin*/
contract SafeMath {
 
    function safeAdd(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }
 
    function safeSubtract(uint256 x, uint256 y) internal pure returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }
 
    function safeMult(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x * y;
        assert((x == 0)||(z/x == y));
        return z;
    }
 
}
 
contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public  returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
 
 
/*  ERC 20 token */
contract StandardToken is Token {
 
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require (_to != address(0));
        require (balances[msg.sender] >= _value && _value > 0);
        require (balances[_to] + _value >= balances[_to]);
        
        uint256 previousBalances = balances[msg.sender] + balances[_to];

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        
        assert(balances[msg.sender] + balances[_to] == previousBalances);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }
 
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require (_to != address(0));
        require (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);

        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
 
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
 
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
 
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
 
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}
 
contract QPCToken is StandardToken, SafeMath {
 
    // metadata
    string  public constant name = "QiaoPi Coin";
    string  public constant symbol = "QPC";
    uint256 public constant decimals = 18;
    string  public version = "1.0";
 
    // contracts
    address public ethFundDeposit;          // ETH???ŵ?ַ
    address public newContractAddr;         // token???µ?ַ
 
    // crowdsale parameters
    bool    public isFunding;                // ״̬?л???true
    uint256 public fundingStartBlock;
    uint256 public fundingStopBlock;
 
    uint256 public currentSupply;           // ?????????е?tokens????
    uint256 public tokenRaised = 0;         // ?ܵ?????????token
    uint256 public tokenMigrated = 0;     // ?ܵ??Ѿ????׵? token
    uint256 public tokenExchangeRate = 100;             // 100 QPC ?һ? 1 ETH
 
    // events
    event AllocateToken(address indexed _to, uint256 _value);   // ??????˽?н???token;
    event IssueToken(address indexed _to, uint256 _value);      // ??????????????token;
    event IncreaseSupply(uint256 _value);
    event DecreaseSupply(uint256 _value);
    event Migrate(address indexed _to, uint256 _value);
 
    // ת??
    function formatDecimals(uint256 _value) internal pure returns (uint256 ) {
        return _value * 10 ** decimals;
    }
 
    // constructor
    constructor(address _ethFundDeposit, uint256 _currentSupply) public {
        ethFundDeposit = _ethFundDeposit;
 
        isFunding = false;                           //ͨ??????ԤCrowdSale״̬
        fundingStartBlock = 0;
        fundingStopBlock = 0;
 
        currentSupply = formatDecimals(_currentSupply);
        totalSupply = formatDecimals(1000000000);
        balances[msg.sender] = totalSupply;

        assert(currentSupply <= totalSupply);
    }
 
    modifier isOwner()  { require(msg.sender == ethFundDeposit); _; }
 
    ///  ????token????
    function setTokenExchangeRate(uint256 _tokenExchangeRate) isOwner external {
        require(_tokenExchangeRate != 0 && _tokenExchangeRate != tokenExchangeRate);
    
        tokenExchangeRate = _tokenExchangeRate;
    }
 
    /// ????token????
    function increaseSupply (uint256 _value) isOwner external {
        uint256 value = formatDecimals(_value);
        assert(value + currentSupply <= totalSupply);

        currentSupply = safeAdd(currentSupply, value);
        emit IncreaseSupply(value);
    }
 
    /// ????token????
    function decreaseSupply (uint256 _value) isOwner external {
        uint256 value = formatDecimals(_value);
        require(value + tokenRaised <= currentSupply);
 
        currentSupply = safeSubtract(currentSupply, value);
        emit DecreaseSupply(value);
    }
 
    ///  ???????????? ?쳣?Ĵ???
    function startFunding (uint256 _fundingStartBlock, uint256 _fundingStopBlock) isOwner external {
        require(!isFunding);
        require(_fundingStartBlock < _fundingStopBlock);
        require(block.number < _fundingStartBlock);
 
        fundingStartBlock = _fundingStartBlock;
        fundingStopBlock = _fundingStopBlock;
        isFunding = true;
    }
 
    ///  ?ر??????쳣????
    function stopFunding() isOwner external {
        require(isFunding);
        isFunding = false;
    }
 
    /// ??????һ???µĺ?ͬ??????token?????߸???token??
    function setMigrateContract(address _newContractAddr) isOwner external {
        require(_newContractAddr != newContractAddr);
        newContractAddr = _newContractAddr;
    }
 
    /// ?????µ??????ߵ?ַ
    function changeOwner(address _newFundDeposit) isOwner() external {
        require (_newFundDeposit != address(0x0));
        ethFundDeposit = _newFundDeposit;
    }
 
    ///ת??token???µĺ?Լ
    function migrate() external {
        require(!isFunding);
        require(newContractAddr != address(0x0));
        uint256 tokens = balances[msg.sender];
        require (tokens != 0);
 
        balances[msg.sender] = 0;
        tokenMigrated = safeAdd(tokenMigrated, tokens);
 
        IMigrationContract newContract = IMigrationContract(newContractAddr);
        
        assert (newContract.migrate(msg.sender, tokens));
 
        emit Migrate(msg.sender, tokens);               // log it
    }

    /// ת??ETH ??QPC?Ŷ?
    function transferETH() isOwner external {
        require (address(this).balance != 0);

        assert (msg.sender.send(address(this).balance));
    }
 
    ///  ??QPC token???䵽Ԥ??????ַ??
    function allocateToken (address _addr, uint256 _eth) isOwner external {
        require (_eth != 0);
        require (_addr != address(0x0));
 
        uint256 tokens = safeMult(formatDecimals(_eth), tokenExchangeRate);
        require (tokens + tokenRaised <= currentSupply);
 
        tokenRaised = safeAdd(tokenRaised, tokens);
        balances[_addr] += tokens;
 
        emit AllocateToken(_addr, tokens);
    }
 
    /// ????token
    function () external payable {
        require (isFunding);
        require (msg.value != 0);
 
        require (block.number >= fundingStartBlock);
        require (block.number <= fundingStopBlock);
 
        uint256 tokens = safeMult(msg.value, tokenExchangeRate);
        require (tokens + tokenRaised <= currentSupply);
 
        tokenRaised = safeAdd(tokenRaised, tokens);
        balances[msg.sender] += tokens;
 
        emit IssueToken(msg.sender, tokens);  //??¼??־
    }
}