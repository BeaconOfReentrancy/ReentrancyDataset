pragma solidity 0.6.4;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

contract MiningReward is Initializable {
    using SafeMath for uint256;

    using SafeERC20 for IERC20;

    bool internal _notEntered;

    /// @notice ??????????????????
    address public rewardToken;

    /// @notice ???????????????
    address public admin;

    /// @notice ?????????????????????
    address public proposedAdmin;

    /// @notice ??????????????????
    uint256 public datetime;

    /// @notice ??????????????????
    /// @param amount ??????????????????????????????
    struct Balance {
        uint256 amount;
    }

    /// @notice ?????????????????????
    address public coinAdmin;

    /// @notice ???????????????????????????
    address public proposedCoinAdmin;

    /// @notice ???????????? => ????????????????????????
    mapping(address => Balance) public userBalance;

    /// @notice ??????????????????????????????
    /// @param admin ???????????????
    /// @param proposedAdmin ?????????????????????
    event ProposeAdmin(address admin, address proposedAdmin);

    /// @notice ?????????Claim Admin
    /// @param oldAdmin ??????????????????
    /// @param newAdmin ??????????????????
    event ClaimAdmin(address oldAdmin, address newAdmin);

    /// @notice ??????????????????????????????????????????????????????
    /// @param amount ??????
    event WithdrawRewardWithAmount(uint256 amount);

    /// @notice ??????????????????????????????????????????????????????
    /// @param amount ??????
    event WithdrawReward(uint256 amount);

    /// @notice ???????????????????????????????????????????????????????????????????????????
    /// @param addr ????????????
    /// @param amount ??????
    event WithdrawRewardToAddress(address addr, uint256 amount);

    /// @notice ???????????????????????????????????????????????????????????????????????????
    /// @param addr ????????????
    /// @param amount ??????
    event WithdrawRewardToAddressWithAmount(address addr, uint256 amount);

    /// @notice ???????????????????????????
    /// @param addr ????????????
    /// @param amount ??????
    event ClaimReward(address addr, uint256 amount);

    /// @notice ???????????????????????????
    /// @param oldToken ?????????
    /// @param newToken ?????????
    event SetRewardToken(address oldToken, address newToken);

    /// @notice ?????????????????????????????????
    /// @param accounts ??????????????????
    /// @param amounts ??????????????????
    /// @param datetime ?????????
    event BatchSet(address[] accounts, uint256[] amounts, uint256 datetime);

    /// @notice ?????????????????????????????????????????????????????????????????????
    /// @param account ????????????
    /// @param amount ????????????
    event Set(address account, uint256 amount);

    /// @notice ???????????????
    /// @param _admin ???????????????
    /// @param _rewardToken ??????????????????
    function initialize(address _admin, address _coinAdmin, address _rewardToken)
        public
        initializer
    {
        admin = _admin;
        coinAdmin = _coinAdmin;
        rewardToken = _rewardToken;
        _notEntered = true;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "Admin required");
        _;
    }

    modifier onlyCoinAdmin {
        require(msg.sender == coinAdmin, "CoinAdmin required");
        _;
    }

    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true;
    }

    /// @notice ????????????????????????
    /// @param _rewardToken ??????????????????
    function setRewardToken(address _rewardToken) public onlyCoinAdmin {
        address oldToken = rewardToken;
        rewardToken = _rewardToken;

        emit SetRewardToken(oldToken, rewardToken);
    }

    /// @notice ???????????????????????????
    /// @param _proposedAdmin ?????????????????????
    function proposeAdmin(address _proposedAdmin) public onlyAdmin {
        require(_proposedAdmin != address(0));
        proposedAdmin = _proposedAdmin;

        emit ProposeAdmin(admin, _proposedAdmin);
    }

    /// @notice ??????????????? claim ??????
    function claimAdmin() public {
        require(msg.sender == proposedAdmin, "ProposedAdmin required");
        address oldAdmin = admin;
        admin = proposedAdmin;
        proposedAdmin = address(0);

        emit ClaimAdmin(oldAdmin, admin);
    }

    /// @notice ???????????????????????????
    /// @param _proposedCoinAdmin ?????????????????????
    function proposeCoinAdmin(address _proposedCoinAdmin) public onlyCoinAdmin {
        require(_proposedCoinAdmin != address(0));
        proposedCoinAdmin = _proposedCoinAdmin;

        // emit ProposeAdmin(admin, _proposedCoinAdmin);
    }

    /// @notice ??????????????? claim ??????
    function claimCoinAdmin() public {
        require(msg.sender == proposedCoinAdmin, "proposedCoinAdmin required");
        // address oldCoinAdmin = coinAdmin;
        coinAdmin = proposedCoinAdmin;
        proposedCoinAdmin = address(0);

        // emit ClaimAdmin(oldAdmin, admin);
    }

    /// @notice ?????????????????????????????????????????????????????????
    /// @param amount ????????????
    function withdrawRewardWithAmount(uint256 amount) public onlyCoinAdmin {
        require(
            IERC20(rewardToken).balanceOf(address(this)) > 0,
            "No reward left"
        );
        require(amount > 0, "Invalid amount");
        IERC20(rewardToken).safeTransfer(admin, amount);

        emit WithdrawRewardWithAmount(amount);
    }

    /// @notice ??????????????????????????????????????????????????????
    function withdrawReward() public onlyCoinAdmin {
        require(
            IERC20(rewardToken).balanceOf(address(this)) > 0,
            "No reward left"
        );
        uint256 balance = checkRewardBalance();
        IERC20(rewardToken).safeTransfer(admin, balance);

        emit WithdrawReward(balance);
    }

    /// @notice ???????????????????????????????????????????????????????????????????????????
    /// @param addr ??????????????????
    function withdrawRewardToAddress(address addr) public onlyCoinAdmin {
        require(
            IERC20(rewardToken).balanceOf(address(this)) > 0,
            "No reward left"
        );
        uint256 balance = checkRewardBalance();
        IERC20(rewardToken).safeTransfer(addr, balance);

        emit WithdrawRewardToAddress(addr, balance);
    }

    /// @notice ??????????????????????????????????????????????????????????????????????????????????????????
    /// @param addr ??????????????????
    /// @param amount ????????????
    function withdrawRewardToAddressWithAmount(address addr, uint256 amount)
        public
        onlyCoinAdmin
    {
        require(
            IERC20(rewardToken).balanceOf(address(this)) > 0,
            "No reward left"
        );
        IERC20(rewardToken).safeTransfer(addr, amount);

        emit WithdrawRewardToAddressWithAmount(addr, amount);
    }

    /// @notice ?????????????????????????????????
    /// @param accounts ??????????????????
    /// @param amount ??????????????????
    /// @param _datetime ?????????
    function batchSet(
        address[] calldata accounts,
        uint256[] calldata amount,
        uint256 _datetime
    ) external onlyAdmin {
        require(_datetime > datetime, "Invalid time");
        uint256 userCount = accounts.length;
        require(userCount == amount.length, "Invalid input");
        for (uint256 i = 0; i < userCount; ++i) {
            userBalance[accounts[i]].amount = userBalance[accounts[i]]
                .amount
                .add(amount[i]);
        }
        datetime = _datetime;

        emit BatchSet(accounts, amount, _datetime);
    }

    /// @notice ????????????????????????????????????????????????????????????
    /// @param account ????????????
    /// @param amount ????????????
    function set(address account, uint256 amount) external onlyAdmin {
        userBalance[account].amount = amount;

        emit Set(account, amount);
    }

    /// @notice ?????????????????????????????????
    function claimReward() public nonReentrant {
        uint256 claimAmount = userBalance[msg.sender].amount;
        require(claimAmount > 0, "No reward");
        require(
            checkRewardBalance() >= claimAmount,
            "Insufficient rewardToken"
        );
        userBalance[msg.sender].amount = 0;
        IERC20(rewardToken).safeTransfer(msg.sender, claimAmount);

        emit ClaimReward(msg.sender, claimAmount);
    }

    /// @notice ?????????????????????????????????
    function checkBalance(address account) public view returns (uint256) {
        return userBalance[account].amount;
    }

    /// @notice ??????????????????????????????
    function checkRewardBalance() public view returns (uint256) {
        return IERC20(rewardToken).balanceOf(address(this));
    }
}