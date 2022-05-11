/**
 *Submitted for verification at Etherscan.io on 2020-06-27
*/

pragma solidity 0.4.24;

contract ERC20TokenInterface {

    function totalSupply () external constant returns (uint);
    function balanceOf (address tokenOwner) external constant returns (uint balance);
    function transfer (address to, uint tokens) external returns (bool success);
    function transferFrom (address from, address to, uint tokens) external returns (bool success);

}

/**
 * Math operations with safety checks that throw on overflows.
 */
library SafeMath {

    function mul (uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }
    
    function div (uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }
    
    function sub (uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add (uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }

}

/**
 * SyoTeam tokens vesting contract. 
 *
 * According to the SyoTeam token distribution structure, there are two parties that should
 * be provided with corresponding token amounts during the 2 years after TGE:
 *      Teams and Strategic Partners: 20%
 *      Early Investors: 40%
 *
 * The SyoTeam "Vesting" smart contract should be in place to ensure meeting the token sale commitments.
 *
 * Two instances of the contract will be deployed for holding tokens. 
 * First instance for "Teams and Strategic Partners" tokens and second for "Early Investors".
 */
contract SyoTokensVesting {

    using SafeMath for uint256;

    /**
     * Address of SyoToken.
     */
    ERC20TokenInterface public syoToken;

    /**
     * Address for receiving tokens.
     */
    address public withdrawAddress;

    /**
     * Tokens vesting stage structure with vesting date and tokens allowed to unlock.
     */
    struct VestingStage {
        uint256 date;
        uint256 tokensUnlockedPercentage;
    }

    /**
     * Array for storing all vesting stages with structure defined above.
     */
    VestingStage[10] public stages;

    /**
     * Starting timestamp of the first stage of vesting (Saturday, 27 June 2020, 12:00:00 GMT).
     * Will be used as a starting point for all dates calculations.
     */
    uint256 public vestingStartTimestamp = 1593248400;

    /**
     * Total amount of tokens sent.
     */
    uint256 public initialTokensBalance;

    /**
     * Amount of tokens already sent.
     */
    uint256 public tokensSent;

    /**
     * Event raised on each successful withdraw.
     */
    event Withdraw(uint256 amount, uint256 timestamp);

    /**
     * Could be called only from withdraw address.
     */
    modifier onlyWithdrawAddress () {
        require(msg.sender == withdrawAddress);
        _;
    }

    /**
     * We are filling vesting stages array right when the contract is deployed.
     *
     * @param token Address of SyoToken that will be locked on contract.
     * @param withdraw Address of tokens receiver when it is unlocked.
     */
    constructor (ERC20TokenInterface token, address withdraw) public {
        syoToken = token;
        withdrawAddress = withdraw;
        initVestingStages();
    }
    
    /**
     * Fallback 
     */
    function () external {
        withdrawTokens();
    }

    /**
     * Calculate tokens amount that is sent to withdrawAddress.
     * 
     * @return Amount of tokens that can be sent.
     */
    function getAvailableTokensToWithdraw () public view returns (uint256 tokensToSend) {
        uint256 tokensUnlockedPercentage = getTokensUnlockedPercentage();
        // In the case of stuck tokens we allow the withdrawal of them all after vesting period ends.
        if (tokensUnlockedPercentage >= 100) {
            tokensToSend = syoToken.balanceOf(this);
        } else {
            tokensToSend = getTokensAmountAllowedToWithdraw(tokensUnlockedPercentage);
        }
    }

    /**
     * Get detailed info about stage. 
     * Provides ability to get attributes of every stage from external callers, ie Web3, truffle tests, etc.
     *
     * @param index Vesting stage number. Ordered by ascending date and starting from zero.
     *
     * @return {
     *    "date": "Date of stage in unix timestamp format.",
     *    "tokensUnlockedPercentage": "Percent of tokens allowed to be withdrawn."
     * }
     */
    function getStageAttributes (uint8 index) public view returns (uint256 date, uint256 tokensUnlockedPercentage) {
        return (stages[index].date, stages[index].tokensUnlockedPercentage);
    }

    /**
     * Setup array with vesting stages dates and percents.
     */
    function initVestingStages () internal {
        uint256 month = 30 days;
        uint256 halfOfYear = 183 days;
        
        stages[0].date = vestingStartTimestamp + halfOfYear;
        stages[1].date = vestingStartTimestamp + halfOfYear + month;
        stages[2].date = vestingStartTimestamp + halfOfYear + month * 2;
        stages[3].date = vestingStartTimestamp + halfOfYear + month * 3;
        stages[4].date = vestingStartTimestamp + halfOfYear + month * 4;
        stages[6].date = vestingStartTimestamp + halfOfYear + month * 5;
        stages[7].date = vestingStartTimestamp + halfOfYear + month * 6;
        stages[8].date = vestingStartTimestamp + halfOfYear + month * 7;
        stages[9].date = vestingStartTimestamp + halfOfYear + month * 8;
        
        stages[0].tokensUnlockedPercentage = 10;
        stages[1].tokensUnlockedPercentage = 20;
        stages[2].tokensUnlockedPercentage = 30;
        stages[3].tokensUnlockedPercentage = 40;
        stages[4].tokensUnlockedPercentage = 50;
        stages[5].tokensUnlockedPercentage = 60;
        stages[6].tokensUnlockedPercentage = 70;
        stages[7].tokensUnlockedPercentage = 80;
        stages[8].tokensUnlockedPercentage = 90;
        stages[9].tokensUnlockedPercentage = 100;
    }

    /**
     * Main method for withdraw tokens from vesting.
     */
    function withdrawTokens () onlyWithdrawAddress private {
        // Setting initial tokens balance on a first withdraw.
        if (initialTokensBalance == 0) {
            setInitialTokensBalance();
        }
        uint256 tokensToSend = getAvailableTokensToWithdraw();
        sendTokens(tokensToSend);
    }

    /**
     * Set initial tokens balance when making the first withdrawal.
     */
    function setInitialTokensBalance () private {
        initialTokensBalance = syoToken.balanceOf(this);
    }

    /**
     * Send tokens to withdrawAddress.
     * 
     * @param tokensToSend Amount of tokens will be sent.
     */
    function sendTokens (uint256 tokensToSend) private {
        if (tokensToSend > 0) {
            // Updating tokens sent counter
            tokensSent = tokensSent.add(tokensToSend);
            // Sending allowed tokens amount
            syoToken.transfer(withdrawAddress, tokensToSend);
            // Raising event
            emit Withdraw(tokensToSend, now);
        }
    }

    /**
     * Calculate tokens available for withdrawal.
     *
     * @param tokensUnlockedPercentage Percent of tokens that are allowed to be sent.
     *
     * @return Amount of tokens that can be sent according to provided percentage.
     */
    function getTokensAmountAllowedToWithdraw (uint256 tokensUnlockedPercentage) private view returns (uint256) {
        uint256 totalTokensAllowedToWithdraw = initialTokensBalance.mul(tokensUnlockedPercentage).div(100);
        uint256 unsentTokensAmount = totalTokensAllowedToWithdraw.sub(tokensSent);
        return unsentTokensAmount;
    }

    /**
     * Get tokens unlocked percentage on current stage.
     * 
     * @return Percent of tokens allowed to be sent.
     */
    function getTokensUnlockedPercentage () private view returns (uint256) {
        uint256 allowedPercent;
        
        for (uint8 i = 0; i < stages.length; i++) {
            if (now >= stages[i].date) {
                allowedPercent = stages[i].tokensUnlockedPercentage;
            }
        }
        
        return allowedPercent;
    }
}

contract TeamAndEarlyInvestorsVesting is SyoTokensVesting {
    constructor(ERC20TokenInterface token, address withdraw) SyoTokensVesting(token, withdraw) public {}
}