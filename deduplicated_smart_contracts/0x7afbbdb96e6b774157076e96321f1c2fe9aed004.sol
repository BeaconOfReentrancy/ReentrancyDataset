// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import { FundRaisingGuild } from "./FundRaisingGuild.sol";

/// @title Fund raising platform facilitated by launch pool
/// @author BlockRocket.tech
/// @dev Fork of MasterChef.sol from SushiSwap
/// @dev Only the owner can add new pools
contract LaunchPoolERC20FundRaisingNftLockedWithVesting is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @dev Details about each user in a pool
    struct UserInfo {
        uint256 amount;     // How many tokens are staked in a pool
        uint256 pledgeFundingAmount; // Based on staked tokens, the funding that has come from the user (or not if they choose to pull out)
        uint256 rewardDebtRewards; // Reward debt. See explanation below.
        uint256 tokenAllocDebt;
        //
        // We do some fancy math here. Basically, once vesting has started in a pool (if they have deposited), the amount of reward tokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebtRewards
        //
        // The amount can never change once the staking period has ended
    }

    /// @dev Info of each pool.
    struct PoolInfo {
        IERC20 rewardToken; // Address of the reward token contract.
        IERC20 fundRaisingToken; // Address of the fund raising token contract.
        uint256 tokenAllocationStartBlock; // Block when users stake counts towards earning reward token allocation
        uint256 stakingEndBlock; // Before this block, staking is permitted
        uint256 pledgeFundingEndBlock; // Between stakingEndBlock and this number pledge funding is permitted
        uint256 targetRaise; // Amount that the project wishes to raise
        uint256 maxStakingAmountPerUser; // Max. amount of tokens that can be staked per account/user
        uint256[] whitelistTokenIds; // List of whitelisted nft token ids that users must hold to be able to stake
    }

    /// @dev staking token is fixed for all pools
    IERC20 public stakingToken;

    /// @dev nft token contract for all pools
    IERC1155 public nftToken;

    /// @dev Container for holding all rewards
    FundRaisingGuild public rewardGuildBank;

    /// @dev List of pools that users can stake into
    PoolInfo[] public poolInfo;

    // Pool to accumulated share counters
    mapping(uint256 => uint256) public poolIdToAccPercentagePerShare;
    mapping(uint256 => uint256) public poolIdToLastPercentageAllocBlock;

    // Number of reward tokens distributed per block for this pool
    mapping(uint256 => uint256) public poolIdToRewardPerBlock;

    // Last block number that reward token distribution took place
    mapping(uint256 => uint256) public poolIdToLastRewardBlock;

    // Block number when rewards start
    mapping(uint256 => uint256) public poolIdToRewardStartBlock;

    // Block number when cliff ends
    mapping(uint256 => uint256) public poolIdToRewardCliffEndBlock;

    // Block number when rewards end
    mapping(uint256 => uint256) public poolIdToRewardEndBlock;

    // Per LPOOL token staked, how much reward token earned in pool that users will get
    mapping(uint256 => uint256) public poolIdToAccRewardPerShareVesting;

    // Total rewards being distributed up to rewardEndBlock
    mapping(uint256 => uint256) public poolIdToMaxRewardTokensAvailableForVesting;

    // Total amount staked into the pool
    mapping(uint256 => uint256) public poolIdToTotalStaked;

    // Total amount of funding received by stakers after stakingEndBlock and before pledgeFundingEndBlock
    mapping(uint256 => uint256) public poolIdToTotalRaised;

    // For every staker that funded their pledge, the sum of all of their allocated percentages
    mapping(uint256 => uint256) public poolIdToTotalFundedPercentageOfTargetRaise;

    // True when funds have been claimed
    mapping(uint256 => bool) public poolIdToFundsClaimed;

    /// @dev Per pool, info of each user that stakes ERC20 tokens.
    /// @dev Pool ID => User Address => User Info
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Available before staking ends for any given project. Essentitally 100% to 18 dp
    uint256 public constant TOTAL_TOKEN_ALLOCATION_POINTS = (100 * (10 ** 18));

    event ContractDeployed(address indexed guildBank);
    event PoolAdded(uint256 indexed pid);
    event Pledge(address indexed user, uint256 indexed pid, uint256 amount);
    event PledgeFunded(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardsSetUp(uint256 indexed pid, uint256 amount, uint256 rewardEndBlock);
    event RewardClaimed(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event FundRaisingClaimed(uint256 indexed pid, address indexed recipient, uint256 amount);

    /// @param _stakingToken Address of the staking token for all pools
    constructor(IERC20 _stakingToken, IERC1155 _nftToken) public {
        require(address(_stakingToken) != address(0), "constructor: _stakingToken must not be zero address");
        require(address(_nftToken) != address(0), "constructor: _nftToken must not be zero address");

        stakingToken = _stakingToken;
        nftToken = _nftToken;
        rewardGuildBank = new FundRaisingGuild(address(this));

        emit ContractDeployed(address(rewardGuildBank));
    }

    /// @dev Returns the number of pools that have been added by the owner
    /// @return Number of pools
    function numberOfPools() external view returns (uint256) {
        return poolInfo.length;
    }

    /// @dev Can only be called by the contract owner
    function add(
        IERC20 _rewardToken,
        IERC20 _fundRaisingToken,
        uint256 _tokenAllocationStartBlock,
        uint256 _stakingEndBlock,
        uint256 _pledgeFundingEndBlock,
        uint256 _targetRaise,
        uint256 _maxStakingAmountPerUser,
        bool _withUpdate,
        uint256[] memory _whitelistTokenIds
    ) public onlyOwner {
        address rewardTokenAddress = address(_rewardToken);
        require(rewardTokenAddress != address(0), "add: _rewardToken is zero address");
        address fundRaisingTokenAddress = address(_fundRaisingToken);
        require(fundRaisingTokenAddress != address(0), "add: _fundRaisingToken is zero address");
        require(_tokenAllocationStartBlock < _stakingEndBlock, "add: _tokenAllocationStartBlock must be before staking end");
        require(_stakingEndBlock < _pledgeFundingEndBlock, "add: staking end must be before funding end");
        require(_targetRaise > 0, "add: Invalid raise amount");

        if (_withUpdate) {
            massUpdatePools();
        }

        poolInfo.push(PoolInfo({
            rewardToken : _rewardToken,
            fundRaisingToken : _fundRaisingToken,
            tokenAllocationStartBlock: _tokenAllocationStartBlock,
            stakingEndBlock: _stakingEndBlock,
            pledgeFundingEndBlock: _pledgeFundingEndBlock,
            targetRaise: _targetRaise,
            maxStakingAmountPerUser: _maxStakingAmountPerUser,
            whitelistTokenIds:_whitelistTokenIds
        }));

        poolIdToLastPercentageAllocBlock[poolInfo.length.sub(1)] = _tokenAllocationStartBlock;

        emit PoolAdded(poolInfo.length.sub(1));
    }

    // step 1
    function pledge(uint256 _pid, uint256 _amount) external nonReentrant {
        require(_pid < poolInfo.length, "pledge: Invalid PID");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(_amount > 0, "pledge: No pledge specified");
        require(block.number <= pool.stakingEndBlock, "pledge: Staking no longer permitted");
        if(pool.whitelistTokenIds.length > 0) {
            // loop through the list and check users balance of those NFTs
            bool holdsNft = false;
            for (uint256 i = 0; i < pool.whitelistTokenIds.length; ++i) {
                if(nftToken.balanceOf(msg.sender, pool.whitelistTokenIds[i]) > 0) {
                    holdsNft = true;
                    break;
                }
            }
            // add require that they have one in their balance
            require(holdsNft, "pledge: user does not hold required NFT to participate");
        }

        require(user.amount.add(_amount) <= pool.maxStakingAmountPerUser, "pledge: can not exceed max staking amount per user");

        updatePool(_pid);

        user.amount = user.amount.add(_amount);
        user.tokenAllocDebt = user.tokenAllocDebt.add(_amount.mul(poolIdToAccPercentagePerShare[_pid]).div(1e18));

        poolIdToTotalStaked[_pid] = poolIdToTotalStaked[_pid].add(_amount);

        stakingToken.safeTransferFrom(address(msg.sender), address(this), _amount);

        emit Pledge(msg.sender, _pid, _amount);
    }

    function getPledgeFundingAmount(uint256 _pid) public view returns (uint256) {
        require(_pid < poolInfo.length, "getPledgeFundingAmount: Invalid PID");
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][msg.sender];

        (uint256 accPercentPerShare,) = getAccPercentagePerShareAndLastAllocBlock(_pid);

        uint256 userPercentageAllocated = user.amount.mul(accPercentPerShare).div(1e18).sub(user.tokenAllocDebt);
        return userPercentageAllocated.mul(pool.targetRaise).div(TOTAL_TOKEN_ALLOCATION_POINTS);
    }

    // step 2
    function fundPledge(uint256 _pid) external nonReentrant {
        require(_pid < poolInfo.length, "fundPledge: Invalid PID");

        updatePool(_pid);

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.pledgeFundingAmount == 0, "fundPledge: Pledge has already been funded");
        if(pool.whitelistTokenIds.length > 0) {
            // loop through the list and check users balance of those NFTs
            bool holdsNft = false;
            for (uint256 i = 0; i < pool.whitelistTokenIds.length; ++i) {
                if(nftToken.balanceOf(msg.sender, pool.whitelistTokenIds[i]) > 0) {
                    holdsNft = true;
                    break;
                }
            }
            // add require that they have one in their balance
            require(holdsNft, "fundPledge: user does not hold required NFT to participate");
        }
        require(block.number > pool.stakingEndBlock, "fundPledge: Staking is still taking place");
        require(block.number <= pool.pledgeFundingEndBlock, "fundPledge: Deadline has passed to fund your pledge");

        require(user.amount > 0, "fundPledge: Must have staked");
        uint256 pledgeFundingAmount = getPledgeFundingAmount(_pid);
        require(pledgeFundingAmount > 0, "fundPledge: must have positive pledge amount");

        // this will fail if the sender does not have the right amount of the token
        pool.fundRaisingToken.safeTransferFrom(msg.sender, address(this), pledgeFundingAmount);
        
        poolIdToTotalRaised[_pid] = poolIdToTotalRaised[_pid].add(pledgeFundingAmount);

        (uint256 accPercentPerShare,) = getAccPercentagePerShareAndLastAllocBlock(_pid);
        uint256 userPercentageAllocated = user.amount.mul(accPercentPerShare).div(1e18).sub(user.tokenAllocDebt);
        poolIdToTotalFundedPercentageOfTargetRaise[_pid] = poolIdToTotalFundedPercentageOfTargetRaise[_pid].add(userPercentageAllocated);

        user.pledgeFundingAmount = pledgeFundingAmount; // ensures pledges can only be done once

        stakingToken.safeTransfer(address(msg.sender), user.amount);

        emit PledgeFunded(msg.sender, _pid, pledgeFundingAmount);
    }

    // pre-step 3 for project
    function getTotalRaisedVsTarget(uint256 _pid) external view returns (uint256 raised, uint256 target) {
        return (poolIdToTotalRaised[_pid], poolInfo[_pid].targetRaise);
    }

    // step 3
    function setupVestingRewards(uint256 _pid, uint256 _rewardAmount,  uint256 _rewardStartBlock, uint256 _rewardCliffEndBlock, uint256 _rewardEndBlock)
    external nonReentrant onlyOwner {
        require(_pid < poolInfo.length, "setupVestingRewards: Invalid PID");
        require(_rewardStartBlock > block.number, "setupVestingRewards: start block in the past");
        require(_rewardCliffEndBlock >= _rewardStartBlock, "setupVestingRewards: Cliff must be after or equal to start block");
        require(_rewardEndBlock > _rewardCliffEndBlock, "setupVestingRewards: end block must be after cliff block");

        PoolInfo storage pool = poolInfo[_pid];

        require(block.number > pool.pledgeFundingEndBlock, "setupVestingRewards: Stakers are still pledging");

        uint256 vestingLength = _rewardEndBlock.sub(_rewardStartBlock);

        poolIdToMaxRewardTokensAvailableForVesting[_pid] = _rewardAmount;
        poolIdToRewardPerBlock[_pid] = _rewardAmount.div(vestingLength);

        poolIdToRewardStartBlock[_pid] = _rewardStartBlock;
        poolIdToLastRewardBlock[_pid] = _rewardStartBlock;

        poolIdToRewardCliffEndBlock[_pid] = _rewardCliffEndBlock;

        poolIdToRewardEndBlock[_pid] = _rewardEndBlock;

        pool.rewardToken.safeTransferFrom(msg.sender, address(rewardGuildBank), _rewardAmount);

        emit RewardsSetUp(_pid, _rewardAmount, _rewardEndBlock);
    }

    function pendingRewards(uint256 _pid, address _user) external view returns (uint256) {
        require(_pid < poolInfo.length, "pendingRewards: invalid _pid");

        UserInfo memory user = userInfo[_pid][_user];

        // If they have staked but have not funded their pledge, they are not entitled to rewards
        if (user.pledgeFundingAmount == 0) {
            return 0;
        }

        uint256 accRewardPerShare = poolIdToAccRewardPerShareVesting[_pid];
        uint256 rewardEndBlock = poolIdToRewardEndBlock[_pid];
        uint256 lastRewardBlock = poolIdToLastRewardBlock[_pid];
        uint256 rewardPerBlock = poolIdToRewardPerBlock[_pid];
        if (block.number > lastRewardBlock && rewardEndBlock != 0 && poolIdToTotalStaked[_pid] != 0) {
            uint256 maxEndBlock = block.number <= rewardEndBlock ? block.number : rewardEndBlock;
            uint256 multiplier = getMultiplier(lastRewardBlock, maxEndBlock);
            uint256 reward = multiplier.mul(rewardPerBlock);
            accRewardPerShare = accRewardPerShare.add(reward.mul(1e18).div(poolIdToTotalFundedPercentageOfTargetRaise[_pid]));
        }

        (uint256 accPercentPerShare,) = getAccPercentagePerShareAndLastAllocBlock(_pid);
        uint256 userPercentageAllocated = user.amount.mul(accPercentPerShare).div(1e18).sub(user.tokenAllocDebt);
        return userPercentageAllocated.mul(accRewardPerShare).div(1e18).sub(user.rewardDebtRewards);
    }

    function massUpdatePools() public {
        for (uint256 pid = 0; pid < poolInfo.length; pid++) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        require(_pid < poolInfo.length, "updatePool: invalid _pid");

        PoolInfo storage poolInfo = poolInfo[_pid];

        // staking not started
        if (block.number < poolInfo.tokenAllocationStartBlock) {
            return;
        }

        // if no one staked, nothing to do
        if (poolIdToTotalStaked[_pid] == 0) {
            poolIdToLastPercentageAllocBlock[_pid] = block.number;
            return;
        }

        // token allocation not finished
        uint256 maxEndBlockForPercentAlloc = block.number <= poolInfo.stakingEndBlock ? block.number : poolInfo.stakingEndBlock;
        uint256 blocksSinceLastPercentAlloc = getMultiplier(poolIdToLastPercentageAllocBlock[_pid], maxEndBlockForPercentAlloc);

        if (poolIdToRewardEndBlock[_pid] == 0 && blocksSinceLastPercentAlloc > 0) {
            (uint256 accPercentPerShare, uint256 lastAllocBlock) = getAccPercentagePerShareAndLastAllocBlock(_pid);
            poolIdToAccPercentagePerShare[_pid] = accPercentPerShare;
            poolIdToLastPercentageAllocBlock[_pid] = lastAllocBlock;
        }

        // project has not sent rewards
        if (poolIdToRewardEndBlock[_pid] == 0) {
            return;
        }

        // cliff has not passed for pool
        if (block.number < poolIdToRewardCliffEndBlock[_pid]) {
            return;
        }

        uint256 rewardEndBlock = poolIdToRewardEndBlock[_pid];
        uint256 lastRewardBlock = poolIdToLastRewardBlock[_pid];
        uint256 maxEndBlock = block.number <= rewardEndBlock ? block.number : rewardEndBlock;
        uint256 multiplier = getMultiplier(lastRewardBlock, maxEndBlock);

        // No point in doing any more logic as the rewards have ended
        if (multiplier == 0) {
            return;
        }

        uint256 rewardPerBlock = poolIdToRewardPerBlock[_pid];
        uint256 reward = multiplier.mul(rewardPerBlock);

        poolIdToAccRewardPerShareVesting[_pid] = poolIdToAccRewardPerShareVesting[_pid].add(reward.mul(1e18).div(poolIdToTotalFundedPercentageOfTargetRaise[_pid]));
        poolIdToLastRewardBlock[_pid] = maxEndBlock;
    }

    function getAccPercentagePerShareAndLastAllocBlock(uint256 _pid) internal view returns (uint256 accPercentPerShare, uint256 lastAllocBlock) {
        PoolInfo memory poolInfo = poolInfo[_pid];
        uint256 tokenAllocationPeriodInBlocks = poolInfo.stakingEndBlock.sub(poolInfo.tokenAllocationStartBlock);

        uint256 allocationAvailablePerBlock = TOTAL_TOKEN_ALLOCATION_POINTS.div(tokenAllocationPeriodInBlocks);

        uint256 maxEndBlockForPercentAlloc = block.number <= poolInfo.stakingEndBlock ? block.number : poolInfo.stakingEndBlock;
        uint256 multiplier = getMultiplier(poolIdToLastPercentageAllocBlock[_pid], maxEndBlockForPercentAlloc);
        uint256 totalPercentageUnlocked = multiplier.mul(allocationAvailablePerBlock);

        return (
            poolIdToAccPercentagePerShare[_pid].add(totalPercentageUnlocked.mul(1e18).div(poolIdToTotalStaked[_pid])),
            maxEndBlockForPercentAlloc
        );
    }

    function claimReward(uint256 _pid) public nonReentrant {
        updatePool(_pid);

        require(block.number >= poolIdToRewardCliffEndBlock[_pid], "claimReward: Not past cliff");

        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.pledgeFundingAmount > 0, "claimReward: Nice try pal");

        PoolInfo storage pool = poolInfo[_pid];

        uint256 accRewardPerShare = poolIdToAccRewardPerShareVesting[_pid];

        (uint256 accPercentPerShare,) = getAccPercentagePerShareAndLastAllocBlock(_pid);
        uint256 userPercentageAllocated = user.amount.mul(accPercentPerShare).div(1e18).sub(user.tokenAllocDebt);
        uint256 pending = userPercentageAllocated.mul(accRewardPerShare).div(1e18).sub(user.rewardDebtRewards);

        if (pending > 0) {
            user.rewardDebtRewards = userPercentageAllocated.mul(accRewardPerShare).div(1e18);
            safeRewardTransfer(pool.rewardToken, msg.sender, pending);

            emit RewardClaimed(msg.sender, _pid, pending);
        }
    }

    // withdraw only permitted post `pledgeFundingEndBlock` and you can only take out full amount if you did not fund the pledge
    // functions like the old emergency withdraw as it does not concern itself with claiming rewards
    function withdraw(uint256 _pid) external nonReentrant {
        require(_pid < poolInfo.length, "withdraw: invalid _pid");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount > 0, "withdraw: No stake to withdraw");
        require(user.pledgeFundingAmount == 0, "withdraw: Only allow non-funders to withdraw");
        require(block.number > pool.pledgeFundingEndBlock, "withdraw: Not yet permitted");

        uint256 withdrawAmount = user.amount;

        // remove the record for this user
        delete userInfo[_pid][msg.sender];

        stakingToken.safeTransfer(msg.sender, withdrawAmount);

        emit Withdraw(msg.sender, _pid, withdrawAmount);
    }

    function claimFundRaising(uint256 _pid) external nonReentrant onlyOwner {
        require(_pid < poolInfo.length, "claimFundRaising: invalid _pid");
        PoolInfo storage pool = poolInfo[_pid];

        uint256 rewardPerBlock = poolIdToRewardPerBlock[_pid];
        require(rewardPerBlock != 0, "claimFundRaising: rewards not yet sent");
        require(poolIdToFundsClaimed[_pid] == false, "claimFundRaising: Already claimed funds");

        poolIdToFundsClaimed[_pid] = true;
        // this will fail if the sender does not have the right amount of the token
        pool.fundRaisingToken.transfer(owner(), poolIdToTotalRaised[_pid]);

        emit FundRaisingClaimed(_pid, owner(), poolIdToTotalRaised[_pid]);
    }

    /// @dev Can only be called by the contract owner
    function updateNftTokenAddress(IERC1155 _nftToken) public onlyOwner {
        require(address(_nftToken) != address(0), "constructor: _nftToken must not be zero address");
        nftToken = _nftToken;
    }

    function poolIdToAllowedTokenIds(uint256 _pid) public view returns (uint256[] memory) {
        require(_pid < poolInfo.length, "poolIdToAllowedTokenIds: invalid _pid");
        return poolInfo[_pid].whitelistTokenIds;
    }

    ////////////
    // Private /
    ////////////

    /// @dev Safe reward transfer function, just in case if rounding error causes pool to not have enough rewards.

    function safeRewardTransfer(IERC20 _rewardToken, address _to, uint256 _amount) private {
        uint256 bal = rewardGuildBank.tokenBalance(_rewardToken);
        if (_amount > bal) {
            rewardGuildBank.withdrawTo(_rewardToken, _to, bal);
        } else {
            rewardGuildBank.withdrawTo(_rewardToken, _to, _amount);
        }
    }

    /// @dev Return reward multiplier over the given _from to _to block.
    /// @param _from Block number
    /// @param _to Block number
    /// @return Number of blocks that have passed
    function getMultiplier(uint256 _from, uint256 _to) private view returns (uint256) {
        return _to.sub(_from);
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

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract FundRaisingGuild {
    using SafeERC20 for IERC20;

    address public stakingContract;

    constructor(address _stakingContract) public {
        stakingContract = _stakingContract;
    }

    function withdrawTo(IERC20 _token, address _recipient, uint256 _amount) external {
        require(msg.sender == stakingContract, "Guild.withdrawTo: Only staking contract");
        _token.safeTransfer(_recipient, _amount);
    }

    function tokenBalance(IERC20 _token) external returns (uint256) {
        return _token.balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

{
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