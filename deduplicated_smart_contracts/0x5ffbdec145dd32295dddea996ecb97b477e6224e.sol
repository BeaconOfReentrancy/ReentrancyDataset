// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

//
//
//                    ┌─┐       ┌─┐ + +
//                    ┌──┘ ┴───────┘ ┴──┐++
//                    │                 │
//                    │       ───       │++ + + +
//                    ███████───███████ │+
//                    │                 │+
//                    │       ─┴─       │
//                    │                 │
//                    └───┐         ┌───┘
//                    │         │
//                    │         │   + +
//                    │         │
//                    │         └──────────────┐
//                    │                        │
//                    │                        ├─┐
//                    │                        ┌─┘
//                    │                        │
//                    └─┐  ┐  ┌───────┬──┐  ┌──┘  + + + +
//                    │ ─┤ ─┤       │ ─┤ ─┤
//                    └──┴──┘       └──┴──┘  + + + +

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./Ownable.sol";

import "./SokeToken.sol";

// MasterChef is the master of Lyptus. He can make Lyptus and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once LYPTUS is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract Soke is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 stakeAmount;         // How many LP tokens the user has provided.
        uint256 balance;
        uint256 pledgeTime;
        bool isExist;
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 poolToken;           // Address of LP token contract.
        uint256 sokeRewardRate;
        uint256 feeRate;
        uint256 feePercent;
        uint256 totalStakeAmount;
        bool isErc20;
        bool isOpen;
    }

    SokeToken public soke;

    PoolInfo[] public poolInfo;

    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    event Stake(address indexed user, uint256 indexed pid, uint256 amount);
    event CancelStake(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        address _SokeTokenAddress
    ) public {
        soke = SokeToken(_SokeTokenAddress);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function addPool(address _poolAddress, uint256 _sokeRewardRate,  uint256 _feeRate, uint256 _feePercent, bool _isErc20, bool _isOpen) public onlyOwner {
        IBEP20 _poolToken = IBEP20(_poolAddress);
        poolInfo.push(PoolInfo({
        poolToken: _poolToken,
        sokeRewardRate: _sokeRewardRate,
        feeRate: _feeRate,
        feePercent: _feePercent,
        totalStakeAmount: 0,
        isErc20: _isErc20,
        isOpen: _isOpen
        }));
    }

    function updatePool(uint256 _pid, address _poolAddress,  uint256 _sokeRewardRate,  uint256 _feeRate, uint256 _feePercent,bool _isErc20, bool _isOpen) public onlyOwner {
        IBEP20 _poolToken = IBEP20(_poolAddress);
        poolInfo[_pid].poolToken = _poolToken;
        poolInfo[_pid].sokeRewardRate = _sokeRewardRate;
        poolInfo[_pid].feeRate = _feeRate;
        poolInfo[_pid].feePercent = _feePercent;
        poolInfo[_pid].isErc20 = _isErc20;
        poolInfo[_pid].isOpen = _isOpen;
    }

    function addUser(uint256 _pid, uint256 _amount) private {
        userInfo[_pid][msg.sender] = UserInfo(
            _amount,
            0,
            block.timestamp,
            true
        );
    }

    function stake() public payable {
        require(msg.value > 0, "stake must gt 0");
        _stake(0, msg.value);
    }

    function stakeToken(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.isErc20, "pool must be erc20 token");

        pool.poolToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        _stake(_pid, _amount);
    }

    function _stake(uint256 _pid, uint256 _amount) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(pool.isOpen, "pool is not opening");

        uint256 realAmount = _amount.mul(pool.feeRate).div(pool.feePercent);

        if(user.isExist == false){
            addUser(_pid, realAmount);
        }else{
            uint256 profit = getUserProfit(_pid, false);
            user.stakeAmount = user.stakeAmount.add(realAmount);

            if (profit > 0) {
                user.balance = user.balance.add(profit);
            }

            user.pledgeTime = block.timestamp;
        }

        pool.totalStakeAmount = pool.totalStakeAmount.add(realAmount);

        emit Stake(msg.sender, _pid, realAmount);
    }


    function cancelStake(uint256 _pid) public payable {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.isExist) {
            if (user.stakeAmount > 0) {
                uint256 stakeAmount = user.stakeAmount;
                uint256 profitAmount = getUserProfit(_pid, true);

                user.stakeAmount = 0;
                user.balance = 0;
                pool.totalStakeAmount = pool.totalStakeAmount.sub(stakeAmount);

                if (pool.isErc20) {
                    pool.poolToken.safeTransfer(address(msg.sender), stakeAmount);
                } else {
                    address payable addr = getPayable(msg.sender);
                    addr.transfer(stakeAmount);
                }

                if (profitAmount > 0) {
                    safeSokeTransfer(address(msg.sender), profitAmount);
                }

                emit CancelStake(msg.sender, _pid, stakeAmount);
            }
        }
    }

    function withdraw(uint256 _pid) public {
        uint256 profitAmount = getUserProfit(_pid, true);
        require(profitAmount > 0,"profit must gt 0");
        UserInfo storage user = userInfo[_pid][msg.sender];
        user.pledgeTime = block.timestamp;
        user.balance = 0;
        safeSokeTransfer(address(msg.sender), profitAmount);
        emit Withdraw(msg.sender, _pid, profitAmount);
    }


    function getUserProfit(uint256 _pid, bool _withBalance) private view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 profit = 0;

        if (user.stakeAmount > 0) {
            uint256 totalStakeAmount = pool.totalStakeAmount;
            if (totalStakeAmount > 0) {
                uint256 time = block.timestamp;
                uint256 hour = time.sub(user.pledgeTime).div(3600);

                if (hour >= 1) {
                    uint256 rate = user.stakeAmount.mul(1e18).div(totalStakeAmount);
                    uint256 profitAmount = rate.mul(pool.sokeRewardRate).mul(hour).div(1e18);
                    if (profitAmount > 0) {
                        profit = profit.add(profitAmount);
                    }
                }
            }
        }

        if (_withBalance) {
            profit = profit.add(user.balance);
        }

        return profit;
    }

    function getProfit(uint256 _pid) public view returns (uint256) {
        uint256 profit = getUserProfit(_pid, true);
        return profit;
    }

    function getPoolStake(uint256 _pid) public view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        return pool.totalStakeAmount;
    }

    function getUserStake(uint256 _pid) public view returns (uint256){
        UserInfo storage user = userInfo[_pid][msg.sender];
        return user.stakeAmount;
    }

    function safeSokeTransfer(address _to, uint256 _amount) internal {
        uint256 sokeBalance = soke.balanceOf(address(this));
        if (_amount > sokeBalance) {
            soke.transfer(_to, sokeBalance);
        } else {
            soke.transfer(_to, _amount);
        }
    }

    function getPayable(address tokenAddress) private pure returns (address payable) {
        return address(uint168(tokenAddress));
    }
}