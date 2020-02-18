pragma solidity >=0.5.0 <0.6.0;

import "../Lib/SafeMath.sol";
import "../Lib/Owned.sol";

contract BankDeposit is Owned {

    using SafeMath for uint;

    uint256 _balance;
    uint256 _paidBenefits;
    uint256 _lastPaidBenefitPeriod;
    uint256 _currentRound;

    mapping(uint256 => uint256) _roundBalances;
    mapping(uint256 => bool) _roundBalanceSets;
    mapping(address => uint256) _allowance;

    constructor() public {

    }


    function balance() external view returns (uint){
        return _balance;
    }

    function balanceAtRound(uint256 round)external view returns (uint256){
        return _roundBalances[round];
    }

    function allowance(address spender) public view returns (uint) {
        return _allowance[spender];
    }

    function approve(address spender, uint value) onlyOwner public returns (bool)  {
        _allowance[spender] = value;
        return true;
    }

    function subApprove(address spender, uint value) onlyOwner public returns (bool) {
        _allowance[spender] = _allowance[spender].sub(value);
        return true;
    }

    function addBalance(uint256 round, uint256 amount) onlyOwner external {
        _addBalance(round, amount);
    }

    function _addBalance(uint256 round, uint256 amount) internal {
        _balance = _balance.add(amount);
        _fillUnsetRoundsBalance(round);
        _currentRound = round;
        _roundBalances[round] = _roundBalances[round].add(amount);
        _roundBalanceSets[round] = true;
    }

    function subBalance(uint256 round, uint256 amount) onlyOwner external  {
        _subBalance(round, amount);
    }

    function _subBalance(uint256 round, uint256 amount) internal  {
        require(amount <= _balance);
        _fillUnsetRoundsBalance(round);
        _balance = _balance.sub(amount);
        _currentRound = round;
        _roundBalances[round] = _roundBalances[round].sub(amount);
        _roundBalanceSets[round] = true;
    }

    function _fillUnsetRoundsBalance(uint256 round) internal returns (uint256) {
        uint256 lastRound = _lastPaidBenefitPeriod;
        if ( !_roundBalanceSets[round]){
            uint256 i = lastRound;
            while ( i <= round ){
                if ( i > 1 && !_roundBalanceSets[i] ){
                    _roundBalances[i] = _roundBalances[i.sub(1)];
                    _roundBalanceSets[i] = true;
                }
                i++;
            }
        }
        return lastRound;
    }


    function fillUnsetRoundsBalance(uint256 round) onlyOwner external returns (uint256) {
        return _fillUnsetRoundsBalance(round);
    }

    function applyBenefitPayment(uint256 round, uint256 benefit) onlyOwner external  {
        if (benefit > 0) {
            _paidBenefits = _paidBenefits.add(benefit);
            uint i = _lastPaidBenefitPeriod;
            while( i <= round ) {
                _roundBalances[i] = _roundBalances[i].add(benefit);
                _roundBalanceSets[i] = true;
                i++;
            }
        }
        _currentRound = round;
        _balance = _roundBalances[_currentRound];
        _lastPaidBenefitPeriod = round.sub(1);
    }

    function lastPaidBenefitPeriod() external view returns (uint256){
        return _lastPaidBenefitPeriod;
    }

    function paidBenefits() external view returns (uint256){
        return  _paidBenefits;
    }

}
