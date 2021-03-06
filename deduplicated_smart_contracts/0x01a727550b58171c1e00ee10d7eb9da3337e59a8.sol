pragma solidity 0.5.11;
import "./SafeMath.sol";

contract PXB   {
    using SafeMath for uint256;

   
    event PassiveDeposit(
        address indexed _investor2,
        uint256 _investmentValue2,
        uint256 _ID2,
        uint256 _unlocktime2,
        uint256 _dailyIncome,
        uint256 _investmentTime
    );
   
    event PassiveSpent(
        address indexed _acclaimer2,
        uint256 indexed _amout2
    );
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    string constant public name = "PIXBY";
    string constant public symbol = "PXB";
    string constant public standard = "PXB Token";
    uint256 constant public decimals = 18 ;
    uint256 private _totalSupply;
    uint256 public totalInvestmentAfterInterest;
    uint256 public passiveInvestorIndex = 1;
    uint256 constant public interestRate = 23;
    uint256 public minForPassive = 35000 * (10 ** uint256(decimals));
    uint256 public maxForPassive = 2500000 * (10 ** uint256(decimals));
    uint256 constant public Percent = 1000000000;
    uint256 constant internal daysInYear = 365;
    uint256 constant internal secondsInDay = 86400;
    uint256 internal _startSupply = 450000000 * (10 ** uint256(decimals));
    address payable public fundsWallet;
    enum TermData {DEFAULT, ONE, TWO, THREE}

    mapping(uint256 => PassiveIncome) private passiveInvestors;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    struct PassiveIncome {
        address investorAddress2;
        uint256 investedAmount2;
        uint256 dailyPassiveIncome;
        uint256 investmentTimeStamp;
        uint256 investmentUnlocktime2;
        uint256 day;
        bool spent2;
        uint256 Days;
    }
    constructor (address payable _fundsWallet)  public {
        _totalSupply = _startSupply;
        fundsWallet = _fundsWallet;
        _balances[msg.sender] = _startSupply;
        _balances[address(1)] = 0;
        emit Transfer(
            address(1),
            msg.sender,
            _startSupply
        );
    
    }
    function () external payable{
        
    }
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(this));
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(_msgSender(), spender, value);
        return true;
    }
    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
        return true;
    }
    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue));
        return true;
    }
    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
    /**
    * @dev Destroys `amount` tokens from the caller.
    *
    * See {ERC20-_burn}.
    */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }
    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    
    
    function makePassiveIncomeInvestment(uint256 _amount,uint256 _unlockTime) external returns (uint256) {
        require(_balances[_msgSender()] >= _amount, "You  have insufficent amount of tokens");
        require(_amount >= minForPassive, "Investment amount should be greater than 35,000 PXB");
        require(_amount <= maxForPassive, "Investment amount should be smaller than 2,500,000 PXB");
        require(_unlockTime <= secondsInDay.mul(365), "Investment term should be smaller than 365 days");
        require(_unlockTime >= (secondsInDay.mul(2)) && (_unlockTime.mod(secondsInDay)) == 0, "Wrong investment time");

        // Term time is currently in days
        uint256 passiveDays = (_unlockTime.div(secondsInDay));

        uint256 interestOnInvestment = getInterestRate(_amount, passiveDays);
        uint256 currentInvestor = passiveInvestorIndex;
        passiveInvestorIndex++;
        passiveInvestors[currentInvestor] = PassiveIncome(
            _msgSender(),
            _amount,
            interestOnInvestment,
            block.timestamp,
            block.timestamp.add(secondsInDay.mul(passiveDays)),
            1,
            false,
            passiveDays
        );
        emit Transfer(
            _msgSender(),
            address(1),
            _amount
        );
        emit Transfer(
            address(1),
            address(1),
            interestOnInvestment.mul(passiveDays)
        );
        emit PassiveDeposit(
            _msgSender(),
            _amount,
            currentInvestor,
            block.timestamp.add((secondsInDay * passiveDays)),
            passiveInvestors[currentInvestor].dailyPassiveIncome,
            passiveInvestors[currentInvestor].investmentTimeStamp
        );
        _balances[_msgSender()] = _balances[_msgSender()].sub(_amount);
        _balances[address(1)] = _balances[address(1)].add((interestOnInvestment.mul(passiveDays)).add(_amount));
        _totalSupply = _totalSupply.sub(_amount);
        return (currentInvestor);
    }


    function releasePassiveIncome(uint256 _passiveIncomeID) external returns (bool success) {
        require(passiveInvestors[_passiveIncomeID].investorAddress2 == _msgSender(), "Only the investor can claim the investment");
        require(passiveInvestors[_passiveIncomeID].spent2 == false, "The investment is already claimed");

        require(passiveInvestors[_passiveIncomeID].investmentTimeStamp.add(120) < block.timestamp,
        "Unlock time for the investment did not mature");
        require(passiveInvestors[_passiveIncomeID].investmentTimeStamp.add((
        secondsInDay.mul(passiveInvestors[_passiveIncomeID].day))) < block.timestamp,
        "Unlock time for the investment did not pass");
        require(passiveInvestors[_passiveIncomeID].day <= passiveInvestors[_passiveIncomeID].Days.add(1), "The investment is already claimed");
        uint256 totalReward = 0;
        uint256 numberOfDaysHeld = (block.timestamp.sub(passiveInvestors[_passiveIncomeID].investmentTimeStamp)).div(secondsInDay);
        if(numberOfDaysHeld >= passiveInvestors[_passiveIncomeID].Days){
            passiveInvestors[_passiveIncomeID].spent2 = true;
            numberOfDaysHeld = passiveInvestors[_passiveIncomeID].Days;
            totalReward = passiveInvestors[_passiveIncomeID].investedAmount2;
        }
        uint numberOfDaysOwed = numberOfDaysHeld.sub((passiveInvestors[_passiveIncomeID].day.sub(1)));
        uint totalDailyPassiveIncome = passiveInvestors[_passiveIncomeID].dailyPassiveIncome.mul(numberOfDaysOwed);
        passiveInvestors[_passiveIncomeID].day = numberOfDaysHeld.add(1);
        totalReward = totalReward.add(totalDailyPassiveIncome);
        if(totalReward > 0){
            _totalSupply = _totalSupply.add(totalReward);
            _balances[address(1)] = _balances[address(1)].sub(totalReward);
            _balances[_msgSender()] = _balances[_msgSender()].add(totalReward);
            emit Transfer(
                address(1),
                _msgSender(),
                totalReward
            );
            emit PassiveSpent(
                _msgSender(),
                totalReward
            );
            return true;
        }
        else{
            revert(
                "There is no total reward earned."
            );
        }
    }
   
   
    
    function getPassiveDetails (uint _passiveIncomeID) external view returns (
        address investorAddress2,
        uint256 investedAmount2,
        uint256 dailyPassiveIncome,
        uint256 investmentTimeStamp,
        uint256 investmentUnlocktime2,
        uint256 day,
        bool spent2
    ){
        return(
            passiveInvestors[_passiveIncomeID].investorAddress2,
            passiveInvestors[_passiveIncomeID].investedAmount2,
            passiveInvestors[_passiveIncomeID].dailyPassiveIncome,
            passiveInvestors[_passiveIncomeID].investmentTimeStamp,
            passiveInvestors[_passiveIncomeID].investmentUnlocktime2,
            passiveInvestors[_passiveIncomeID].day,
            passiveInvestors[_passiveIncomeID].spent2
        );
    }
    function getPassiveIncomeDay(uint256 _passiveIncomeID) external view returns (uint256) {
        return(passiveInvestors[_passiveIncomeID].day);
    }
    function getPassiveIncomeStatus(uint256 _passiveIncomeID) external view returns (bool) {
        return (passiveInvestors[_passiveIncomeID].spent2);
    }
    function getPassiveInvestmentTerm(uint256 _passiveIncomeID) external view returns (uint256){
        return (passiveInvestors[_passiveIncomeID].investmentUnlocktime2);
    }
    function getPassiveNumberOfDays (uint _passiveIncomeID) external view returns (uint256){
        return (block.timestamp.sub(passiveInvestors[_passiveIncomeID].investmentTimeStamp)).div(secondsInDay);
    }
    function getPassiveInvestmentTimeStamp(uint256 _passiveIncomeID) external view returns (uint256){
        return (passiveInvestors[_passiveIncomeID].investmentTimeStamp);
    }
   
  
    function getBlockTimestamp () external view returns (uint blockTimestamp){
        return block.timestamp;
    }
    function getInterestRate(uint256 _investment, uint _term) public view returns (uint256 rate) {
        require(_investment < _totalSupply, "The investment is too large");


        uint256 Precentege = _term.mul(23).mul(Percent).div(365);
        uint256 interestoninvestment = Precentege.div(100).mul(_investment).div(_term);

        return (interestoninvestment.div(Percent));

    }
   
    function getSimulatedDailyIncome (uint _passiveIncomeID) external view returns (
        uint _numberOfDaysHeld,
        uint _numberOfDaysOwed,
        uint _totalDailyPassiveIncome,
        uint _dailyPassiveIncome,
        uint _totalReward,
        uint _day,
        bool _spent
    ){
        _spent = false;
        _numberOfDaysHeld = (block.timestamp - passiveInvestors[_passiveIncomeID].investmentTimeStamp) / secondsInDay;
        if(_numberOfDaysHeld > passiveInvestors[_passiveIncomeID].day){
            _numberOfDaysHeld = passiveInvestors[_passiveIncomeID].day;
            _totalReward = passiveInvestors[_passiveIncomeID].investedAmount2;
            _spent = true;
        }
        _numberOfDaysOwed = _numberOfDaysHeld - (passiveInvestors[_passiveIncomeID].day - 1);
        _totalDailyPassiveIncome = passiveInvestors[_passiveIncomeID].dailyPassiveIncome * _numberOfDaysOwed;
        _day = _numberOfDaysHeld.add(1);
        _totalReward = _totalReward.add(_totalDailyPassiveIncome);
        _dailyPassiveIncome = passiveInvestors[_passiveIncomeID].dailyPassiveIncome;
        return (
            _numberOfDaysHeld,
            _numberOfDaysOwed,
            _totalDailyPassiveIncome,
            _dailyPassiveIncome,
            _totalReward,
            _day,
            _spent
        );
    }
}