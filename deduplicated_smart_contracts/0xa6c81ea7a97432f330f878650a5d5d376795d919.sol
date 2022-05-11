// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import './MTGY.sol';
import './MTGYSpend.sol';
import './MTGYAtomicSwapInstance.sol';

/**
 * @title MTGYAtomicSwap
 * @dev This is the main contract that supports holding metadata for MTGY atomic inter and intrachain swapping
 */
contract MTGYAtomicSwap is Ownable {
  struct TargetSwapInfo {
    bytes32 id;
    uint256 timestamp;
    uint256 index;
    address creator;
    address sourceContract;
    string targetNetwork;
    address targetContract;
    bool isActive;
  }

  MTGY private _mtgy;
  MTGYSpend private _spend;

  uint256 public mtgyServiceCost = 25000 * 10**18;
  uint256 public swapCreationGasLoadAmount = 1 * 10**16; // 10 finney (0.01 ether)
  address public creator;
  address payable public oracleAddress;

  // mapping with "0xSourceContractInstance" => targetContractInstanceInfo that
  // our oracle can query and get the target network contract as needed.
  TargetSwapInfo[] public targetSwapContracts;
  mapping(address => TargetSwapInfo) public targetSwapContractsIndexed;
  mapping(address => TargetSwapInfo) private lastUserCreatedContract;

  // event CreateSwapContract(
  //   uint256 timestamp,
  //   address contractAddress,
  //   string targetNetwork,
  //   address indexed targetContract,
  //   address creator
  // );

  constructor(
    address _mtgyAddress,
    address _mtgySpendAddress,
    address _oracleAddress
  ) {
    creator = msg.sender;
    _mtgy = MTGY(_mtgyAddress);
    _spend = MTGYSpend(_mtgySpendAddress);
    oracleAddress = payable(_oracleAddress);
  }

  function updateSwapCreationGasLoadAmount(uint256 _amount) external onlyOwner {
    swapCreationGasLoadAmount = _amount;
  }

  function getLastCreatedContract(address _addy)
    external
    view
    returns (TargetSwapInfo memory)
  {
    return lastUserCreatedContract[_addy];
  }

  function changeOracleAddress(address _oracleAddress, bool _changeAll)
    external
    onlyOwner
  {
    oracleAddress = payable(_oracleAddress);
    if (_changeAll) {
      for (uint256 _i = 0; _i < targetSwapContracts.length; _i++) {
        MTGYAtomicSwapInstance _contract = MTGYAtomicSwapInstance(
          targetSwapContracts[_i].sourceContract
        );
        _contract.changeOracleAddress(oracleAddress);
      }
    }
  }

  function changeMtgyTokenAddy(address _tokenAddy) external onlyOwner {
    _mtgy = MTGY(_tokenAddy);
  }

  function changeSpendAddress(address _spendAddress) external onlyOwner {
    _spend = MTGYSpend(_spendAddress);
  }

  /**
   * @dev If the price of MTGY changes significantly, need to be able to adjust price
   * to keep cost appropriate for providing the service
   */
  function changeMtgyServiceCost(uint256 _newCost) external onlyOwner {
    mtgyServiceCost = _newCost;
  }

  function getAllSwapContracts()
    external
    view
    returns (TargetSwapInfo[] memory)
  {
    return targetSwapContracts;
  }

  function updateSwapContract(
    uint256 _createdBlockTimestamp,
    address _sourceContract,
    address _targetContract,
    bool _isActive
  ) external {
    TargetSwapInfo storage swapContInd = targetSwapContractsIndexed[
      _sourceContract
    ];
    TargetSwapInfo storage swapCont = targetSwapContracts[swapContInd.index];

    require(
      msg.sender == creator ||
        msg.sender == swapCont.creator ||
        msg.sender == oracleAddress,
      'updateSwapContract must be contract creator'
    );

    bytes32 _id = sha256(
      abi.encodePacked(swapCont.creator, _createdBlockTimestamp)
    );
    require(
      swapCont.id == _id && swapContInd.id == _id,
      "we don't recognize the info you sent with the swap"
    );

    swapCont.targetContract = address(0) != _targetContract
      ? _targetContract
      : swapCont.targetContract;
    swapCont.isActive = _isActive;
    swapContInd.targetContract = swapCont.targetContract;
    swapContInd.isActive = _isActive;
  }

  function createNewAtomicSwapContract(
    address _tokenAddy,
    uint256 _tokenSupply,
    uint256 _maxSwapAmount,
    string memory _targetNetwork,
    address _targetContract
  ) external payable returns (uint256, address) {
    require(
      msg.value >= swapCreationGasLoadAmount,
      'Going to ask the user to fill up the atomic swap contract with some gas'
    );
    _mtgy.transferFrom(msg.sender, address(this), mtgyServiceCost);
    _mtgy.approve(address(_spend), mtgyServiceCost);
    _spend.spendOnProduct(mtgyServiceCost);

    MTGYAtomicSwapInstance _contract = new MTGYAtomicSwapInstance(
      address(_mtgy),
      address(_spend),
      oracleAddress,
      msg.sender,
      _tokenAddy,
      _maxSwapAmount
    );
    oracleAddress.transfer(msg.value);
    ERC20 _token = ERC20(_tokenAddy);
    _token.transferFrom(msg.sender, address(_contract), _tokenSupply);
    _contract.updateSupply();
    _contract.transferOwnership(oracleAddress);

    uint256 _ts = block.timestamp;
    TargetSwapInfo memory newContract = TargetSwapInfo({
      id: sha256(abi.encodePacked(msg.sender, _ts)),
      timestamp: _ts,
      index: targetSwapContracts.length,
      creator: msg.sender,
      sourceContract: address(_contract),
      targetNetwork: _targetNetwork,
      targetContract: _targetContract,
      isActive: true
    });

    targetSwapContracts.push(newContract);
    targetSwapContractsIndexed[address(_contract)] = newContract;
    lastUserCreatedContract[msg.sender] = newContract;
    // emit CreateSwapContract(
    //   _ts,
    //   address(_contract),
    //   _targetNetwork,
    //   _targetContract,
    //   msg.sender
    // );
    return (_ts, address(_contract));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract MTGY is IERC20 {
  string public constant name = 'The moontography project';
  string public constant symbol = 'MTGY';
  uint8 public constant decimals = 18;

  address public constant burnWallet =
    0x000000000000000000000000000000000000dEaD;
  address public constant devWallet =
    0x3A3ffF4dcFCB7a36dADc40521e575380485FA5B8;
  address public constant rewardsWallet =
    0x87644cB97C1e2Cc676f278C88D0c4d56aC17e838;

  mapping(address => uint256) balances;
  mapping(address => mapping(address => uint256)) allowed;

  event Spend(address indexed owner, uint256 value);

  uint256 totalSupply_;

  using SafeMath for uint256;

  constructor(uint256 total) {
    totalSupply_ = total;
    balances[msg.sender] = totalSupply_;
  }

  function totalSupply() public view override returns (uint256) {
    return totalSupply_;
  }

  function balanceOf(address tokenOwner)
    public
    view
    override
    returns (uint256)
  {
    return balances[tokenOwner];
  }

  function transfer(address receiver, uint256 numTokens)
    public
    override
    returns (bool)
  {
    require(numTokens <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(numTokens);
    balances[receiver] = balances[receiver].add(numTokens);
    emit Transfer(msg.sender, receiver, numTokens);
    return true;
  }

  function approve(address delegate, uint256 numTokens)
    public
    override
    returns (bool)
  {
    allowed[msg.sender][delegate] = numTokens;
    emit Approval(msg.sender, delegate, numTokens);
    return true;
  }

  function allowance(address owner, address delegate)
    public
    view
    override
    returns (uint256)
  {
    return allowed[owner][delegate];
  }

  function transferFrom(
    address owner,
    address buyer,
    uint256 numTokens
  ) public override returns (bool) {
    require(numTokens <= balances[owner]);
    require(numTokens <= allowed[owner][msg.sender]);

    balances[owner] = balances[owner].sub(numTokens);
    allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
    balances[buyer] = balances[buyer].add(numTokens);
    emit Transfer(owner, buyer, numTokens);
    return true;
  }

  /**
   * spendOnProduct: used by a moontography product for a user to spend their tokens on usage of a product
   *   25% goes to dev wallet
   *   25% goes to rewards wallet for rewards
   *   50% burned
   */
  function spendOnProduct(uint256 amountTokens) public returns (bool) {
    require(amountTokens <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(amountTokens);
    uint256 half = amountTokens / 2;
    uint256 quarter = half / 2;
    // 50% burn
    balances[burnWallet] = balances[burnWallet].add(half);
    // 25% rewards wallet
    balances[rewardsWallet] = balances[rewardsWallet].add(quarter);
    // 25% dev wallet
    balances[devWallet] = balances[devWallet].add(
      amountTokens - half - quarter
    );
    emit Spend(msg.sender, amountTokens);
    return true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

/**
 * @title MTGYSpend
 * @dev Logic for spending $MTGY on products in the moontography ecosystem.
 */
contract MTGYSpend is Ownable {
  ERC20 private _mtgy;

  struct SpentInfo {
    uint256 timestamp;
    uint256 tokens;
  }

  address public constant burnWallet =
    0x000000000000000000000000000000000000dEaD;
  address public devWallet = 0x3A3ffF4dcFCB7a36dADc40521e575380485FA5B8;
  address public rewardsWallet = 0x87644cB97C1e2Cc676f278C88D0c4d56aC17e838;
  address public mtgyTokenAddy;

  SpentInfo[] public spentTimestamps;
  uint256 public totalSpent = 0;

  event Spend(address indexed owner, uint256 value);

  constructor(address _mtgyTokenAddy) {
    mtgyTokenAddy = _mtgyTokenAddy;
    _mtgy = ERC20(_mtgyTokenAddy);
  }

  function changeMtgyTokenAddy(address _mtgyAddy) external onlyOwner {
    mtgyTokenAddy = _mtgyAddy;
    _mtgy = ERC20(_mtgyAddy);
  }

  function changeDevWallet(address _newDevWallet) external onlyOwner {
    devWallet = _newDevWallet;
  }

  function changeRewardsWallet(address _newRewardsWallet) external onlyOwner {
    rewardsWallet = _newRewardsWallet;
  }

  function getSpentByTimestamp() external view returns (SpentInfo[] memory) {
    return spentTimestamps;
  }

  /**
   * spendOnProduct: used by a moontography product for a user to spend their tokens on usage of a product
   *   25% goes to dev wallet
   *   25% goes to rewards wallet for rewards
   *   50% burned
   */
  function spendOnProduct(uint256 _productCostTokens) external returns (bool) {
    totalSpent += _productCostTokens;
    spentTimestamps.push(
      SpentInfo({ timestamp: block.timestamp, tokens: _productCostTokens })
    );
    uint256 _half = _productCostTokens / uint256(2);
    uint256 _quarter = _half / uint256(2);

    // 50% burn
    _mtgy.transferFrom(msg.sender, burnWallet, _half);
    // 25% rewards wallet
    _mtgy.transferFrom(msg.sender, rewardsWallet, _quarter);
    // 25% dev wallet
    _mtgy.transferFrom(
      msg.sender,
      devWallet,
      _productCostTokens - _half - _quarter
    );
    emit Spend(msg.sender, _productCostTokens);
    return true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './MTGY.sol';
import './MTGYSpend.sol';

/**
 * @title MTGYAtomicSwapInstance
 * @dev This is the main contract that supports holding metadata for MTGY atomic inter and intrachain swapping
 */
contract MTGYAtomicSwapInstance is Ownable {
  MTGY private _mtgy;
  MTGYSpend private _spend;
  ERC20 private _token;

  address public tokenOwner;
  address public oracleAddress;
  uint256 public originalSupply;
  uint256 public maxSwapAmount;
  uint256 public mtgyServiceCost = 1 * 10**18;
  uint256 public minimumGasForOperation = 2 * 10**15; // 2 finney (0.002 ETH)
  bool public isActive = true;

  struct Swap {
    bytes32 id;
    uint256 origTimestamp;
    uint256 currentTimestamp;
    bool isOutbound;
    bool isComplete;
    bool isRefunded;
    bool isSendGasFunded;
    address swapAddress;
    uint256 amount;
  }

  mapping(bytes32 => Swap) public swaps;
  mapping(address => Swap) public lastUserSwap;

  event ReceiveTokensFromSource(
    bytes32 indexed id,
    uint256 origTimestamp,
    address sender,
    uint256 amount
  );

  event SendTokensToDestination(
    bytes32 indexed id,
    address receiver,
    uint256 amount
  );

  event RefundTokensToSource(
    bytes32 indexed id,
    address sender,
    uint256 amount
  );

  event TokenOwnerUpdated(address previousOwner, address newOwner);

  constructor(
    address _mtgyAddress,
    address _mtgySpendAddress,
    address _oracleAddress,
    address _tokenOwner,
    address _tokenAddy,
    uint256 _maxSwapAmount
  ) {
    oracleAddress = _oracleAddress;
    tokenOwner = _tokenOwner;
    maxSwapAmount = _maxSwapAmount;
    _mtgy = MTGY(_mtgyAddress);
    _spend = MTGYSpend(_mtgySpendAddress);
    _token = ERC20(_tokenAddy);
  }

  function getSwapTokenAddress() external view returns (address) {
    return address(_token);
  }

  function changeActiveState(bool _isActive) external {
    require(
      msg.sender == owner() || msg.sender == tokenOwner,
      'changeActiveState user must be contract creator'
    );
    isActive = _isActive;
  }

  function changeMtgyServiceCost(uint256 _newCost) external onlyOwner {
    mtgyServiceCost = _newCost;
  }

  // should only be called after we instantiate a new instance of
  // this and it's to handle weird tokenomics where we don't get
  // original full supply
  function updateSupply() external onlyOwner {
    originalSupply = _token.balanceOf(address(this));
  }

  function changeOracleAddress(address _oracleAddress) external onlyOwner {
    oracleAddress = _oracleAddress;
    transferOwnership(oracleAddress);
  }

  function updateTokenOwner(address newOwner) external {
    require(
      msg.sender == tokenOwner || msg.sender == owner(),
      'user must be current token owner to change it'
    );
    address previousOwner = tokenOwner;
    tokenOwner = newOwner;
    emit TokenOwnerUpdated(previousOwner, newOwner);
  }

  function depositTokens(uint256 _amount) external {
    require(msg.sender == tokenOwner, 'depositTokens user must be token owner');
    _token.transferFrom(msg.sender, address(this), _amount);
  }

  function withdrawTokens(uint256 _amount) external {
    require(
      msg.sender == tokenOwner,
      'withdrawTokens user must be token owner'
    );
    _token.transfer(msg.sender, _amount);
  }

  function updateSwapCompletionStatus(bytes32 _id, bool _isComplete)
    external
    onlyOwner
  {
    swaps[_id].isComplete = _isComplete;
  }

  function updateMinimumGasForOperation(uint256 _amountGas) external onlyOwner {
    minimumGasForOperation = _amountGas;
  }

  function receiveTokensFromSource(uint256 _amount)
    external
    payable
    returns (bytes32, uint256)
  {
    require(isActive, 'this atomic swap instance is not active');
    require(
      msg.value >= minimumGasForOperation,
      'you must also send enough gas to cover the target transaction'
    );
    require(
      maxSwapAmount == 0 || _amount <= maxSwapAmount,
      'trying to send more than maxSwapAmount'
    );

    if (mtgyServiceCost > 0) {
      _mtgy.transferFrom(msg.sender, address(this), mtgyServiceCost);
      _mtgy.approve(address(_spend), mtgyServiceCost);
      _spend.spendOnProduct(mtgyServiceCost);
    }

    payable(oracleAddress).transfer(msg.value);
    _token.transferFrom(msg.sender, address(this), _amount);

    uint256 _ts = block.timestamp;
    bytes32 _id = sha256(abi.encodePacked(msg.sender, _ts, _amount));
    swaps[_id] = Swap({
      id: _id,
      origTimestamp: _ts,
      currentTimestamp: _ts,
      isOutbound: false,
      isComplete: false,
      isRefunded: false,
      isSendGasFunded: false,
      swapAddress: msg.sender,
      amount: _amount
    });
    lastUserSwap[msg.sender] = swaps[_id];
    emit ReceiveTokensFromSource(_id, _ts, msg.sender, _amount);
    return (_id, _ts);
  }

  function unsetLastUserSwap(address _addy) external onlyOwner {
    delete lastUserSwap[_addy];
  }

  // msg.sender must be the user who originally created the swap.
  // Otherwise, the unique identifier will not match from the originally
  // sending txn.
  //
  // NOTE: We're aware this function can be spoofed by creating a sha256 hash of msg.sender's address
  // and _origTimestamp, but it's important to note refundTokensFromSource and sendTokensToDestination
  // can only be executed by the owner/oracle. Therefore validation should be done by the oracle before
  // executing those and the only possibility of a vulnerability is if someone has compromised the oracle account.
  function fundSendToDestinationGas(
    bytes32 _id,
    uint256 _origTimestamp,
    uint256 _amount
  ) external payable {
    require(
      msg.value >= minimumGasForOperation,
      'you must send enough gas to cover the send transaction'
    );
    require(
      _id == sha256(abi.encodePacked(msg.sender, _origTimestamp, _amount)),
      "we don't recognize this swap"
    );
    payable(oracleAddress).transfer(msg.value);
    swaps[_id] = Swap({
      id: _id,
      origTimestamp: _origTimestamp,
      currentTimestamp: block.timestamp,
      isOutbound: true,
      isComplete: false,
      isRefunded: false,
      isSendGasFunded: true,
      swapAddress: msg.sender,
      amount: _amount
    });
  }

  // This must be called AFTER fundSendToDestinationGas has been executed
  // for this txn to fund this send operation
  function refundTokensFromSource(bytes32 _id) external {
    require(isActive, 'this atomic swap instance is not active');

    Swap storage swap = swaps[_id];

    _confirmSwapExistsGasFundedAndSenderValid(swap);
    swap.isRefunded = true;
    _token.transfer(swap.swapAddress, swap.amount);
    emit RefundTokensToSource(_id, swap.swapAddress, swap.amount);
  }

  // This must be called AFTER fundSendToDestinationGas has been executed
  // for this txn to fund this send operation
  function sendTokensToDestination(bytes32 _id) external returns (bytes32) {
    require(isActive, 'this atomic swap instance is not active');

    Swap storage swap = swaps[_id];

    _confirmSwapExistsGasFundedAndSenderValid(swap);
    _token.transfer(swap.swapAddress, swap.amount);
    swap.currentTimestamp = block.timestamp;
    swap.isComplete = true;
    emit SendTokensToDestination(_id, swap.swapAddress, swap.amount);
    return _id;
  }

  function _confirmSwapExistsGasFundedAndSenderValid(Swap memory swap)
    private
    view
    onlyOwner
  {
    // functions that call this should only be called by the current owner
    // or oracle address as they will do the appropriate validation beforehand
    // to confirm the receiving swap is valid before sending tokens to the user.
    require(
      swap.origTimestamp > 0 && swap.amount > 0,
      'swap does not exist yet.'
    );
    // We're just validating here that the swap has not been
    // completed and gas has been funded before moving forward.
    require(
      !swap.isComplete && !swap.isRefunded && swap.isSendGasFunded,
      'swap has already been completed, refunded, or gas has not been funded'
    );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

{
  "metadata": {
    "bytecodeHash": "none"
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}