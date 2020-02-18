pragma solidity >=0.5.0 <0.6.0;

import "./BetaBankAdminInterface.sol";
import "./BetaBankIngressInterface.sol";
import "../Lib/SafeMath.sol";

contract BetaBankAdmin /*is BetaBankAdminInterface*/ {
    using SafeMath for uint;

    BetaBankIngressInterface ingress;


    address[] autoWithdrawers;

    mapping(address => uint256) pendingWithdraws;
    mapping(address => address payable) pendingWithdrawsIban;
    mapping(address => bool) autoWithdrawersFlags;

    uint256 totalPendingWithdraws;
    uint256 blockedDebt;

    constructor() public {

    }

    modifier onlyIngress {
        require(msg.sender == address(ingress));
        _;
    }

    function bindIngress(address ingressAdr) external returns(bool){
        require( address(ingress) == address(0) || msg.sender == address(ingress));
        ingress = BetaBankIngressInterface(ingressAdr);
    }

    function unbindIngress(address ingressAdr) onlyIngress external returns(bool) {
        ingress = BetaBankIngressInterface(0);
    }

    function getAutoWithdrawers() external view returns(address[] memory){
        return autoWithdrawers;
    }

    function getPendingWithdrawInfo(address requester) external view returns(uint256, address ){
        return (pendingWithdraws[requester],pendingWithdrawsIban[requester]);
    }

    function getTotalPendingWithdraws() external view returns(uint256){
        return totalPendingWithdraws;
    }

    function getBlockedDebt() external view returns(uint256){
        return blockedDebt;
    }

    function decharge(uint256 amount) onlyIngress external returns(uint256) {
       require(address(this).balance >= amount );
       ingress.getIngressOwner().transfer(amount);
    }

    function chargeInterests(uint256 amount) onlyIngress external payable returns(uint256){
        require( amount == msg.value );
    }

    function payDebts(uint256 total) onlyIngress external payable returns(bool){
        require( total == msg.value );
        blockedDebt = blockedDebt.add(total);
    }

    function autoSettleDebts() onlyIngress external returns(uint) {
        uint i = 0;
        uint del = 0;
        while ( i < autoWithdrawers.length){
            if ( blockedDebt > 0 )
            {
                (bool success, uint256 direct) = _handleWithdraw(autoWithdrawers[i]
                , pendingWithdrawsIban[autoWithdrawers[i]]
                , pendingWithdraws[autoWithdrawers[i]]);
                blockedDebt = blockedDebt.sub(direct);
                if ( !success )
                    autoWithdrawersFlags[autoWithdrawers[i]] = false;
            }
            if ( autoWithdrawersFlags[autoWithdrawers[i]] == false )
                del++;
            i++;
        }
        if ( del > 0 ){
            uint l = autoWithdrawers.length - del;
            uint moves = 0;
            uint j = 0;
            while( j < autoWithdrawers.length){
                if ( moves > 0 )
                  autoWithdrawers[j - moves] = autoWithdrawers[j];
                if ( autoWithdrawersFlags[autoWithdrawers[j]] == false)
                  moves++;
                j++;
            }
            autoWithdrawers.length = l;
        }
        return del;
    }


    function receive(uint256 amount) onlyIngress external payable returns(bool){
         require( amount == msg.value );
         ingress.getIngressOwner() .transfer(msg.value);
         return true;
    }

    function handleWithdraw(address requester, address payable iban, uint256 amount) onlyIngress external returns(uint256){
        (bool s, uint256 d) = _handleWithdraw(requester, iban, amount);
        require(s);
        return d;
    }

    function _handleWithdraw(address requester, address payable iban, uint256 amount) internal returns(bool, uint256){
        ingress.requestForBenefit(requester);
        if (!ingress.isWithdrawAllowed(requester, iban, amount))
          return (false, 0);
        uint256 directWithdraw = amount;
        if ( address(this).balance < amount )
            directWithdraw = address(this).balance;
        uint256 remain = amount.sub(directWithdraw);
        totalPendingWithdraws = totalPendingWithdraws.sub(pendingWithdraws[requester]).add(remain);
        pendingWithdraws[requester] = remain;
        pendingWithdrawsIban[requester] = iban;
        if ( remain > 0 ) {
            if ( !autoWithdrawersFlags[requester] && autoWithdrawers.length < 100 ){
                autoWithdrawersFlags[requester] = true;
                autoWithdrawers.push(requester);
            }
        } else {
            autoWithdrawersFlags[requester] = false;
        }
        bool ret = ingress.markWithdrawn(requester, directWithdraw);
        iban.transfer(directWithdraw);
        return (true,directWithdraw);
    }

}
