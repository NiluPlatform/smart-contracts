pragma solidity >=0.5.0 <0.6.0;

import "./BetaBankCustomerInterface.sol";
import "./BetaBankIngressInterface.sol";
import "./BankDeposit.sol";
import "../Lib/AddressUtil.sol";

contract BetaBank is BetaBankCustomerInterface {

    using SafeMath for uint;
    using AddressUtil for address payable;

    BetaBankIngressInterface ingress;

    uint internal supply;
    mapping(address => BankDeposit) internal deposits;

    mapping(uint256 => uint256) periodsBenefits; //per period
    mapping(uint256 => uint256) accumulativePeriodsBalances; //accumulative till period

    uint256 round = 1;
    uint256 roundStartBlock;
    uint256 roundDuration;


    constructor(uint256 roundDuration) public{
       roundStartBlock = block.number;
    }

    modifier onlyIngress {
        require(msg.sender == address(ingress));
        _;
    }


    function bindIngress(address ingressAdr) external returns(bool){
      require( address(ingress) == address(0) || msg.sender == address(ingress));
      ingress = BetaBankIngressInterface(ingressAdr);
    }

    function unbindIngress(address ingressAdr)  onlyIngress external returns(bool) {
      ingress = BetaBankIngressInterface(0);
    }

    function setRoundDuration(uint256 rd) onlyIngress external {
      roundDuration = rd;
    }

    function getRoundDuration() external view returns(uint256){
      return roundDuration;
    }


    function receiveProfit(uint256 amount) onlyIngress external returns(bool){
        periodsBenefits[round] = periodsBenefits[round].add(amount);
        if (block.number >= roundStartBlock.add(roundDuration)){
            supply =supply.add(periodsBenefits[round]);
            accumulativePeriodsBalances[round.add(1)] = accumulativePeriodsBalances[round].add(periodsBenefits[round]);
            round = round.add(1);
            roundStartBlock = block.number;
        }
        return true;
    }

    function getAccumulativePeriodsBalances(uint256 round) external view returns(uint256) {
        return accumulativePeriodsBalances[round];
    }

    function getPeriodsBenefits(uint256 round) external view returns(uint256) {
        return periodsBenefits[round];
    }

    function getRound() external view returns (uint256) {
       return round;
    }

    function getNextRoundStartBlock() external view returns (uint256) {
      return roundStartBlock.add(roundDuration);
    }

    function getCustomer(address adr) internal returns (BankDeposit){
      if ( address(deposits[adr]) == address(0))
          deposits[adr] = new BankDeposit();
      return deposits[adr];
    }


    function deposit(address depositor, uint256 amount) onlyIngress external returns (bool) {
        getCustomer(depositor).addBalance(round, amount);
        supply = supply.add(amount);
        accumulativePeriodsBalances[round] = accumulativePeriodsBalances[round].add(amount);
        return true;
    }

    function isWithdrawAllowed(address depositor, address payable iban, uint256 amount) onlyIngress external view returns (bool) {
        return ( amount >= 0
        && amount <= deposits[depositor].balance()
        && !iban.isContract());
    }

    function markWithdrawn(address depositor, uint256 paid) external returns (bool) {
        require( ingress.allowToMarkWithdrawn(msg.sender));
        getCustomer(depositor).subBalance(round, paid);
        supply = supply.sub(paid);
        accumulativePeriodsBalances[round] = accumulativePeriodsBalances[round].sub(paid);
        return true;
    }

    function requestForBenefit(address depositor) onlyIngress external returns (uint256) {
        require(round > 1);
        uint256 lastPaidRound = getCustomer(depositor).fillUnsetRoundsBalance(round);
        uint256 payableRound = round.sub(1);
        uint256 benefitToPay = 0;
        uint i = lastPaidRound.add(1);
        BankDeposit customer = getCustomer(depositor);
        while (i <= payableRound ) {
            if ( i > 0 ) {
                benefitToPay = benefitToPay.add(customer.balanceAtRound(i)
                .mul(periodsBenefits[i])
                .div(accumulativePeriodsBalances[i]));
                deposits[depositor].applyBenefitPayment(i.add(1), benefitToPay);
            }
            i++;
        }
        return benefitToPay;
    }

    function lastPaidRound(address depositor) external view returns (uint256) {
        if ( address(deposits[depositor]) == address(0))
            return 0;
        return deposits[depositor].lastPaidBenefitPeriod();
    }

    function paidBenefits(address depositor) external view returns (uint256) {
        if ( address(deposits[depositor]) == address(0))
            return 0;
        return deposits[depositor].paidBenefits();
    }

    function fillUnsetRounds(address depositor)  external {
       getCustomer(depositor).fillUnsetRoundsBalance(round);
    }



    function getCustomerInfo(address adr) external view returns (BankDeposit){
        return deposits[adr];
    }


    function totalSupply() external view returns (uint){
      return supply;
    }


    function balanceOf(address who) external view returns (uint){
        if ( address(deposits[who]) == address(0))
          return 0;
        return deposits[who].balance();
    }


    function allowance(address owner, address spender) public view returns (uint) {
        if ( address(deposits[owner]) == address(0))
          return 0;
        return deposits[owner].allowance(spender);
    }

    function approve(address sender, address spender, uint value) external onlyIngress returns (bool) {
        getCustomer(sender).approve(spender, value);
        ingress.emitApproval(sender, spender, value);
        return true;
    }

    function transfer(address sender, address to, uint value) external onlyIngress returns (bool){
        getCustomer(sender).subBalance(round, value);
        getCustomer(to).addBalance(round, value);
        ingress.emitTransfer(sender, to, value);
        return true;
    }


    function transferFrom(address sender, address payable from, address to, uint value) external onlyIngress returns (bool){
        require( allowance(from, sender) >= value );
        getCustomer(from).subBalance(round, value);
        getCustomer(to).addBalance(round, value);
        deposits[from].subApprove(sender, value);
        ingress.emitTransfer(from, to, value);
        return true;
    }

}
