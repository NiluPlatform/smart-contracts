pragma solidity ^0.5.0;

import "../Lib/Owned.sol";
import "../Lib/SafeMath.sol";
import "../Lib/AddressUtil.sol";

contract NiluLottery is Owned {

    using SafeMath for uint256;
    using AddressUtil for address;
    using AddressUtil for address payable;

    mapping(address => uint256) balances;

    address payable[] participants;

    uint256 total;

    mapping(address => uint256) winHistory;

    mapping(address => uint256) withdrawHistory;

    uint256 lotteryBlock;

    address lastWinner;

    uint256 lastReward;

    uint256 minimumPay = 1000000000000000000;

    constructor() public{

    }

    function() external payable {
        handlePayment();
    }

    function handlePayment() internal {
        require(!msg.sender.isContract());
        if (msg.sender != owner) {
            if (msg.value > 0) {
                require(lotteryBlock == 0 && msg.value >= minimumPay);
                if (balances[msg.sender] == 0)
                    participants.push(msg.sender);
                balances[msg.sender] = balances[msg.sender].add(msg.value);
                total = total.add(msg.value);
            } else {
                withdraw(balances[msg.sender]);
            }
        } else if (msg.value == 0) {
            require(lotteryBlock == 0);
            owner.transfer(address(this).balance.sub(total));
        }
    }

    function setMinimumPay(uint256 mp) public onlyOwner {
        minimumPay = mp;
    }

    function getMinimumPay() public view returns (uint256){
        return minimumPay;
    }

    function withdraw(uint256 val) public {
        require(lotteryBlock == 0 && balances[msg.sender] >= val && val >= minimumPay);
        balances[msg.sender] = balances[msg.sender].sub(val);
        total = total.sub(val);
        if (balances[msg.sender] == 0) {
            uint i = 0;
            while (i < participants.length) {
                if (participants[i] == msg.sender)
                {
                    delete participants[i];
                    break;
                }
                i++;
            }
            while (i < participants.length - 1) {
                participants[i] = participants[i + 1];
                i++;
            }
            participants.length = i;
        }
        withdrawHistory[msg.sender] = withdrawHistory[msg.sender].add(val);
        msg.sender.transfer(val);
    }

    function resetLottery() public onlyOwner {
        lotteryBlock = 0;
        lastWinner = address(0);
        lastReward = 0;
    }

    function prepareLottery() public onlyOwner {
        require(lotteryBlock == 0);
        uint8 rand = (uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 200));
        lotteryBlock = block.number.add(rand);
        lastWinner = address(0);
        lastReward = 0;
    }

    function _doLottery(address payable[] memory candidates) internal {
        require(lotteryBlock > 0 && block.number > lotteryBlock && candidates.length > 0);
        uint256 reward = address(this).balance.sub(total);
        require(reward > 0);
        uint256 shares = 0;
        uint index = 0;
        while (index < candidates.length) {
            shares = shares.add(balances[candidates[index]]);
            index = index.add(1);
        }
        require(shares <= total);
        if (shares > 0) {
            uint256 hash = uint256(blockhash(lotteryBlock)) % (shares);
            index = 0;
            uint256 hashIndex = 0;
            while (hashIndex <= hash && index < candidates.length) {
                hashIndex = hashIndex.add(balances[candidates[index]]);
                if (hashIndex > hash) {
                    address payable winner = candidates[index];
                    winHistory[winner] = winHistory[winner].add(reward);
                    winner.transfer(reward);
                    lastWinner = winner;
                    lastReward = reward;
                    break;
                }
                index = index.add(1);
            }
        }
        lotteryBlock = 0;
    }

    function isBlockNumberConditionPassed() public view returns (bool){
        return block.number > lotteryBlock;
    }

    function calculateShare(address[] memory candidates) public view returns (uint256){
        uint256 shares = 0;
        uint index = 0;
        while (index < candidates.length) {
            shares = shares.add(balances[candidates[index]]);
            index = index.add(1);
        }
        return shares;
    }

    function calculateHash(address[] memory candidates) public view returns (uint256) {
        uint256 shares = 0;
        uint index = 0;
        while (index < candidates.length) {
            shares = shares.add(balances[candidates[index]]);
            index = index.add(1);
        }
        return uint256(blockhash(lotteryBlock)) % shares;
    }

    function getLottaryBlock() public view returns (uint256){
        return lotteryBlock;
    }

    function getTotal() public view returns (uint256){
        return total;
    }

    function getLastReward() public view returns (uint256){
        return lastReward;
    }

    function getLastWinner() public view returns (address){
        return lastWinner;
    }

    function getParticipants() public view returns (address payable[] memory){
        return participants;
    }

    function getBalance(address addr) public view returns (uint256){
        return balances[addr];
    }

    function getWinHistory(address addr) public view returns (uint256){
        return winHistory[addr];
    }

    function getWithdrawHistory(address addr) public view returns (uint256){
        return withdrawHistory[addr];
    }


}
