/**

 *Submitted for verification at Etherscan.io on 2018-12-04

*/



pragma solidity ^0.4.23;



library SafeMath {



  /**

  * @dev Multiplies two numbers, throws on overflow.

  */

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {



    if (a == 0) {

      return 0;

    }



    c = a * b;

    assert(c / a == b);

    return c;

  }



  /**

  * @dev Integer division of two numbers, truncating the quotient.

  */

  function div(uint256 a, uint256 b) internal pure returns (uint256) {



    return a / b;

  }



  /**

  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).

  */

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {

    assert(b <= a);

    return a - b;

  }



  /**

  * @dev Adds two numbers, throws on overflow.

  */

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {

    c = a + b;

    assert(c >= a);

    return c;

  }

}





contract ERC20Basic {

    

  function totalSupply() public view returns (uint256);

  function balanceOf(address who) public view returns (uint256);

  function transfer(address to, uint256 value) public returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  

}



contract ERC20 is ERC20Basic {

    

  function allowance(address owner, address spender)

    public view returns (uint256);



  function transferFrom(address from, address to, uint256 value)

    public returns (bool);



  function approve(address spender, uint256 value) public returns (bool);

  event Approval(

    address indexed owner,

    address indexed spender,

    uint256 value

  );

}



contract DetailedERC20 is ERC20 {

  string public name;

  string public symbol;

  uint8 public decimals;



  constructor(string _name, string _symbol, uint8 _decimals) public {

    name = _name;

    symbol = _symbol;

    decimals = _decimals;

  }

}



/**

 * @title ????ERC20?????????????? 

 * @dev ??????StandardToken????????allowances.

 */

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



  /**

   * @dev ??????????????????????????token

   * @param _from ??????from????

   * @param _to address ??????to????

   * @param _value uint256 ????token????

   */

  function transferFrom(

    address _from,

    address _to,

    uint256 _value

  )

    public

    returns (bool)

  {

    // ????????????

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



  function allowance(

    address _owner,

    address _spender

   )

    public

    view

    returns (uint256)

  {

    return allowed[_owner][_spender];

  }



}



/**

 * @title ?????? Token

 * @dev Token????????

 */

contract BurnableToken is BasicToken {



  event Burn(address indexed burner, uint256 value);



  /**

   * @dev ??????????????token.

   * @param _value ????????token????.

   */

  function burn(uint256 _value) public {

    _burn(msg.sender, _value);

  }



  function _burn(address _who, uint256 _value) internal {

    require(_value <= balances[_who]);

    balances[_who] = balances[_who].sub(_value);

    totalSupply_ = totalSupply_.sub(_value);

    emit Burn(_who, _value);

    emit Transfer(_who, address(0), _value);

  }

}



contract MintableToken is StandardToken {

  event Mint(address indexed to, uint256 amount);

  event MintFinished();



  bool public mintingFinished = false;





  modifier canMint() {

    require(!mintingFinished);

    _;

  }



  /**

   * @dev Function to mint tokens

   * @param _to The address that will receive the minted tokens.

   * @param _amount The amount of tokens to mint.

   * @return A boolean that indicates if the operation was successful.

   */

  function mint(

    address _to,

    uint256 _amount

  )

    public

    canMint

    returns (bool)

  {

    totalSupply_ = totalSupply_.add(_amount);

    balances[_to] = balances[_to].add(_amount);

    emit Mint(_to, _amount);

    emit Transfer(address(0), _to, _amount);

    return true;

  }



  /**

   * @dev Function to stop minting new tokens.

   * @return True if the operation was successful.

   */

  function finishMinting() public  canMint returns (bool) {

    mintingFinished = true;

    emit MintFinished();

    return true;

  }

}



/**

 * @title ??????????token

 * @dev ??burnFrom??????????ERC20??????

 */

contract StandardBurnableToken is BurnableToken, StandardToken,MintableToken {



  /**

   * @dev ????????????????????????token????????????

   * @param _from address token??????????

   * @param _value uint256 ????????token????

   */

  function burnFrom(address _from, uint256 _value) public {

    require(_value <= allowed[_from][msg.sender]);

    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

    _burn(_from, _value);

  }

  

}



contract BHTDtoken is StandardBurnableToken {

    string public name = 'Bhtd';

    string public symbol = 'BHTD';

    uint8 public decimals = 8;

    uint256 public INITIAL_SUPPLY = 32000000000000000; 

    

  constructor() public {

    totalSupply_ = INITIAL_SUPPLY;

    balances[msg.sender] = INITIAL_SUPPLY;

  }



}