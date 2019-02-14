pragma solidity ^0.5.0;


import "./Safebox.sol";
import "../Lib/SafeMath.sol";
import "../Lib/AddressUtil.sol";

contract Metabank {

    using SafeMath for uint256;
    using AddressUtil for address;
    using AddressUtil for address payable;

    uint256 public duration;

    uint256 public startBlock = 0;

    uint256 public currentRound = 0;

    uint256 public minimumAllowedBalance;

    uint16 public heraldFee = 25;

    uint256 total = 0;

    uint256 totalBalances = 0;

    mapping(address => uint256) balances;

    mapping(address => uint256) paymentHistory;

    mapping(address => uint256) depositRequests;

    mapping(address => uint256) withdrawRequests;

    mapping(address => bool) accumulateInterests;

    address public owner;

    mapping(address => bool) registered;

    address payable[] accounts;

    Safebox safebox;


    constructor(address payable s, uint256 d, uint256 m, uint16 h, uint256 w) public {
        owner = msg.sender;
        safebox = Safebox(s);
        startBlock = block.number.add(w);
        duration = d;
        minimumAllowedBalance = m;
        heraldFee = h;
    }

    function() external payable {
        handlePayment();
    }

    function handlePayment() public payable {
        if (msg.sender != address(safebox)) {
            require(depositRequests[msg.sender].add(balances[msg.sender]).add(msg.value) >= minimumAllowedBalance
                    && !msg.sender.isContract());
            depositRequests[msg.sender] = depositRequests[msg.sender].add(msg.value);
            total = total.add(msg.value);
            if (!registered[msg.sender]) {
                accounts.push(msg.sender);
                registered[msg.sender] = true;
            }
            address(safebox).transfer(msg.value);
        }
    }


    function allowAccumulate() public {
        accumulateInterests[msg.sender] = true;
    }

    function disallowAccumulate() public {
        accumulateInterests[msg.sender] = false;
    }

    function withdraw(uint256 value) public {
        require(value <= balances[msg.sender]
        .add(depositRequests[msg.sender])
        .sub(withdrawRequests[msg.sender]));
        uint256 dr = value > depositRequests[msg.sender] ? depositRequests[msg.sender] : value;
        if (dr > 0)
        {
            depositRequests[msg.sender] = depositRequests[msg.sender].sub(dr);
            total = total.sub(dr);
            safebox.sendTo(msg.sender, dr);
        }
        withdrawRequests[msg.sender] = withdrawRequests[msg.sender].add(value.sub(dr));
    }


    function nextSettlementBlock() public view returns (uint256) {
        return startBlock.add(duration);
    }

    function canSettle() public view returns (bool) {
        return block.number.sub(startBlock) >= duration || (currentRound == 0);
    }

    function calculateRoundTotalBenefit() public view returns (uint256) {
        uint256 totalBenefit = address(safebox).balance > total ? address(safebox).balance.sub(total): 0;
        uint256 heraldShare = totalBenefit.mul(heraldFee).div(10000);
        totalBenefit = totalBenefit.sub(heraldShare);
        return totalBenefit;
    }

    function calculateRoundHeraldBenefit() public view returns (uint256) {
        uint256 totalBenefit = address(safebox).balance > total ? address(safebox).balance.sub(total): 0;
        return totalBenefit.mul(heraldFee).div(10000);
    }

    function settle() public {
        require(block.number.sub(startBlock) >= duration || (currentRound == 0));

        if (currentRound != 0) {
            uint256 totalBenefit = address(safebox).balance > total ? address(safebox).balance.sub(total): 0;
            uint256 heraldShare = totalBenefit.mul(heraldFee).div(10000);
            totalBenefit = totalBenefit > heraldShare? totalBenefit.sub(heraldShare): 0;
            giveShares(totalBenefit);
            giveHeraldShares(msg.sender, heraldShare);
        }
        finalizeWithdraws();
        applyDepositRequest();
        if (block.number.sub(startBlock) >= duration) {
            currentRound = currentRound.add(1);
            startBlock = block.number;
        }
    }

    function giveShares(uint256 totalBenefit) private {
        if (totalBenefit > 0) {
            uint256 depositedInterest = 0;
            uint i = 0;
            while (i < accounts.length) {
                uint256 interest = balances[accounts[i]].mul(totalBenefit).div(totalBalances);
                if (interest > 0) {
                    if (accumulateInterests[accounts[i]]) {
                        balances[accounts[i]] = balances[accounts[i]].add(interest);
                        depositedInterest = depositedInterest.add(interest);
                    } else {
                        paymentHistory[accounts[i]] = paymentHistory[accounts[i]].add(interest);
                        safebox.sendTo(accounts[i], interest);
                    }
                }
                i++;
            }
            total = total.add(depositedInterest);
            totalBalances = totalBalances.add(depositedInterest);
        }

    }

    function finalizeWithdraws() private {
        uint i = 0;
        while (i < accounts.length) {
            uint256 w = withdrawRequests[accounts[i]];
            if (w > 0) {
                balances[accounts[i]] = balances[accounts[i]].sub(w);
                totalBalances = totalBalances.sub(w);
                if (balances[accounts[i]] < minimumAllowedBalance) {
                    depositRequests[accounts[i]] = depositRequests[accounts[i]].add(balances[accounts[i]]);
                    totalBalances = totalBalances.sub(balances[accounts[i]]);
                    balances[accounts[i]] = 0;
                }
                withdrawRequests[accounts[i]] = 0;
                paymentHistory[accounts[i]] = paymentHistory[accounts[i]].add(w);
                safebox.sendTo(accounts[i], w);
                total = total.sub(w);
            }
            i++;
        }
    }

    function applyDepositRequest() private {
        uint i = 0;
        while (i < accounts.length) {
            uint deposit = depositRequests[accounts[i]];
            if (deposit > 0 && balances[accounts[i]].add(deposit) >= minimumAllowedBalance) {
                balances[accounts[i]] = balances[accounts[i]].add(deposit);
                depositRequests[accounts[i]] = 0;
                totalBalances = totalBalances.add(deposit);
            }
            i++;
        }
    }

    function giveHeraldShares(address payable herald, uint256 heraldShare) private {
        if (!registered[herald]) {
            accounts.push(herald);
            registered[herald] = true;
        }
        safebox.sendTo(herald, heraldShare);
        paymentHistory[herald] = paymentHistory[herald].add(heraldShare);
    }

    function getAccounts() public view returns (address payable[] memory) {
        require(msg.sender == owner);
        return accounts;
    }

    function allowedWithdrawAmount(address a, bool immediate) public view returns (uint256){
        return depositRequests[a]
        .add(immediate ? 0 : (balances[a].sub(withdrawRequests[a])));
    }


    function balanceOf(address a) public view returns (uint256){
        return balances[a];
    }

    function paymentHistoryOf(address a) public view returns (uint256){
        return paymentHistory[a];
    }

    function depositRequestsOf(address a) public view returns (uint256){
        return depositRequests[a];
    }

    function withdrawRequestsOf(address a) public view returns (uint256){
        return withdrawRequests[a];
    }

    function isAccumulative(address a) public view returns (bool){
        return accumulateInterests[a];
    }



    function getTotal() public view returns (uint256 val){
        return total;
    }

    function getTotalBalances() public view returns (uint256 val){
        return totalBalances;
    }

    function getSafebox() public view returns (address){
        return address(safebox);
    }


}
