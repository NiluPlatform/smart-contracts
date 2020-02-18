pragma solidity >=0.5.0 <0.6.0;

import "../Lib/SafeMath.sol";
import "../Lib/Owned.sol";
import "../Lib/AddressUtil.sol";
import "../Pod/MetabankInterface.sol";
import "../NiluToken/ERC20.sol";
//import "../Pod/Bank.sol";

contract Bank2 is Owned, ERC20/*, Bank*/ {

    using SafeMath for uint;
    using AddressUtil for address;
    using AddressUtil for address payable;

    mapping(address => uint256) balances;

    mapping(address => uint256) pendingWithdraws;

    mapping(address => uint256) paidBenefits;

    mapping(address => mapping(address => uint)) internal allowed;

    mapping(address => uint256) lastPaidBenefitPeriod;

    mapping(address => mapping(uint256 => uint256)) roundBalances;
    mapping(address => mapping(uint256 => bool)) roundBalanceSets;

    mapping(uint256 => uint256) periodsBenefits; //per period

    mapping(uint256 => uint256) accumulativePeriodsBalances; //accumulative till period


    uint256 totalBalances;
    uint256 totalPendingWithdraws;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public rate;

    uint256 currentRound;
    uint256 startBlock;
    uint256 duration;

    constructor(string memory n, string memory s, uint256 d ) public {
        rate = 1;
        decimals = 18;
        name = n;
        symbol = s;
        duration = d;
        currentRound = 1;
        startBlock = block.number;
    }

    function setName(string calldata n) external onlyOwner{
        name = n;
    }

    function setSymbol(string calldata s) external onlyOwner{
        symbol = s;
    }

    function setDuration(uint256 d) external onlyOwner{
        duration = d;
    }


    function getOwner() external view returns(address){
      return owner;
    }

    function calculateTotalNiluToBePaid(uint benefit,uint total) external view returns(uint256){
       uint debt = address(this).balance > totalPendingWithdraws ? 0: totalPendingWithdraws.sub(address(this).balance);
       return debt.add(accumulativePeriodsBalances[currentRound].mul( benefit.add(total)).div(total));
    }


    function totalSupply() external view returns (uint) {
        return totalBalances.sub(totalPendingWithdraws);
    }

    function getTotalBalances() external view returns (uint) {
        return totalBalances;
    }

    function getTotalPendingWithdraws() external view returns (uint) {
        return totalPendingWithdraws;
    }

    function accumulativePeriodsBalancesOf(uint256 round) external view returns (uint) {
        return accumulativePeriodsBalances[round];
    }
    function periodsBenefitsAt(uint256 round) external view returns (uint) {
        return periodsBenefits[round];
    }

    function periodsBenefitsOf(address depositor, uint256 round) external view returns (uint) {
        return roundBalances[depositor][round].mul(periodsBenefits[round]).div(accumulativePeriodsBalances[round]);
    }

    function balance() public view returns (uint) {
        return balances[msg.sender];
    }

    function balanceOf(address who) external view returns (uint) {
        return balances[who];
    }

    function roundBalancesOf(address who, uint256 round) external view returns (uint) {
        return roundBalances[who][round];
    }

    function lastPaidBenefitPeriodOf(address who) external view returns (uint) {
        return lastPaidBenefitPeriod[who];
    }

    function pendingWithdrawsOf(address who) external view returns (uint) {
        return pendingWithdraws[who];
    }

    function paidBenefitsOf(address who) external view returns (uint) {
        return paidBenefits[who];
    }

    function transfer(address to, uint value) external returns (bool) {
        return transferFrom(msg.sender, to , value);
    }

    function allowance(address owner, address spender) public view returns (uint) {
        return allowed[owner][spender];
    }

    function approve(address spender, uint value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address payable from, address to, uint value) public returns (bool) {
        if ( to == address(0) || to == owner ){
           return _withdraw(from , from , value) > 0;
        }
        require(from == msg.sender || value <= allowed[from][msg.sender], "Not allowed");
        require(value <= balances[from], "Insufficient balance");
        requestBenefit(from);
        requestBenefit(to);
        if ( value > balances[from].sub(pendingWithdraws[from])){
           uint256 extra = value.sub(balances[from].sub(pendingWithdraws[from]));
           pendingWithdraws[from] = pendingWithdraws[from].sub(extra);
           totalPendingWithdraws = totalPendingWithdraws.sub(extra);
        }
        _decreaseBalance(from, value, true );
        _increaseBalance(to, value, true );
        if ( from != msg.sender)
          allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

    function withdraw(address depositor, address payable iban, uint256 amount) external returns (uint){
       return _withdraw(depositor, iban, amount);
    }

    function _withdraw(address depositor, address payable iban, uint256 value) internal returns (uint){
        if ( depositor == owner ){
            uint256 directWithdraw = value;
            if ( address(this).balance < value ) {
               directWithdraw = address(this).balance;
            }
            iban.transfer(directWithdraw);
            return directWithdraw;
        } else {
            require(depositor == msg.sender || value <= allowed[depositor][msg.sender], "Not allowed");
            require(value <= balances[depositor], "Insufficient balance");
            require(!iban.isContract(), "Iban should be normal address");
            requestBenefit(depositor);
            uint256 netValue = value.add(pendingWithdraws[depositor]);
            uint256 directWithdraw = netValue;
            require(directWithdraw > 0, "Can't withdraw 0 amount");
            if ( pendingWithdraws[depositor] > 0 ) {
                totalPendingWithdraws = totalPendingWithdraws.sub(pendingWithdraws[depositor]);
                pendingWithdraws[depositor] = 0;
            }
            if ( address(this).balance < directWithdraw ) {
               directWithdraw = address(this).balance;
               pendingWithdraws[depositor] = pendingWithdraws[depositor].add(netValue.sub(directWithdraw));
               totalPendingWithdraws = totalPendingWithdraws.add(netValue.sub(directWithdraw));
            }
            _decreaseBalance(depositor, directWithdraw, false );
            if ( depositor != msg.sender)
               allowed[depositor][msg.sender] = allowed[depositor][msg.sender].sub(directWithdraw);
            iban.transfer(directWithdraw);
            return directWithdraw;
        }
    }

    function deposit(address depositor, uint256 amount) external payable returns (uint)  {
       _deposit( depositor, amount);
    }

    function _deposit(address depositor, uint256 amount) internal returns (uint)  {
        require(amount <= msg.value.add(pendingWithdraws[depositor]));
        if ( depositor == owner ){
            periodsBenefits[currentRound] = periodsBenefits[currentRound].add(amount);
            if (block.number >= startBlock.add(duration)){
                uint256 netBenefit = periodsBenefits[currentRound] > totalPendingWithdraws ? periodsBenefits[currentRound].sub(totalPendingWithdraws) : 0;
                periodsBenefits[currentRound] = netBenefit;
                accumulativePeriodsBalances[currentRound.add(1)] = accumulativePeriodsBalances[currentRound];
                currentRound = currentRound.add(1);
                startBlock = block.number;
            }
        } else {
            requestBenefit(msg.sender);
            _increaseBalance(depositor, msg.value, false );
            if ( amount > msg.value && pendingWithdraws[depositor] >= amount.sub(msg.value)){
                pendingWithdraws[depositor] = pendingWithdraws[depositor].sub(amount.sub(msg.value));
                totalPendingWithdraws = totalPendingWithdraws.sub(amount.sub(msg.value));
            }
            owner.transfer(msg.value);
        }
    }

    function _increaseBalance(address depositor, uint256 value, bool transfer) internal{
        balances[depositor] = balances[depositor].add(value);
        roundBalances[depositor][currentRound] = roundBalances[depositor][currentRound].add(value);
        roundBalanceSets[depositor][currentRound] = true;
        if ( ! transfer ){
            accumulativePeriodsBalances[currentRound] = accumulativePeriodsBalances[currentRound].add(value);
            totalBalances = totalBalances.add(value);
        }
    }

    function _decreaseBalance(address depositor, uint256 value, bool transfer) internal {
        balances[depositor] = balances[depositor].sub(value);
        roundBalances[depositor][currentRound] = roundBalances[depositor][currentRound].sub(value);
        roundBalanceSets[depositor][currentRound] = true;
        if ( ! transfer ){
            accumulativePeriodsBalances[currentRound] = accumulativePeriodsBalances[currentRound].sub(value);
            totalBalances = totalBalances.sub(value);
        }
    }

    function requestBenefit(address depositor) public returns (uint256){
        uint256 lastRound = lastPaidBenefitPeriod[depositor];
        uint256 i = lastRound;
        if ( !roundBalanceSets[depositor][currentRound]){
            while ( i <= currentRound ){
                if ( i > 1 && !roundBalanceSets[depositor][i] ){
                    roundBalances[depositor][i] = roundBalances[depositor][i.sub(1)];
                    roundBalanceSets[depositor][i] = true;
                }
                i++;
            }
            i = lastRound;
        }
        uint256 benefitToPay = 0;
        if ( currentRound > 1 && lastRound < currentRound.sub(1) ){
            while (i <= currentRound.sub(1)) {
                if ( i > 0 ) {
                    uint256 pi = periodsBenefits[i];
                    benefitToPay = benefitToPay.add(roundBalances[depositor][i].mul(pi).div(accumulativePeriodsBalances[i]));
                }
                i++;
            }
            lastPaidBenefitPeriod[depositor] = currentRound.sub(1);
            if (benefitToPay > 0) {
                paidBenefits[depositor] = paidBenefits[depositor].add(benefitToPay);
                _increaseBalance(depositor, benefitToPay, false);
            }
        }
        return benefitToPay;
    }

    function nextSettlementBlock() public view returns (uint256){
        return startBlock.add(duration);
    }

    function canSettle() public view returns (bool){
        return block.number >= (startBlock.add(duration));
    }

    function getCurrentRound() public view returns (uint256){
        return currentRound;
    }

    function getStartBlock() public view returns (uint256){
        return startBlock;
    }

    function getDuration() public view returns (uint256){
        return duration;
    }

    function () external payable {
        if ( msg.value > 0 ){
            _deposit(msg.sender, msg.value);
        } else {
           if ( msg.sender != owner ){
                requestBenefit(msg.sender);
           } else {
                _withdraw(msg.sender, msg.sender, address(this).balance);
           }
        }
    }

}
