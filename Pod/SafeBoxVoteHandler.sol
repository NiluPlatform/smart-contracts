pragma solidity ^0.5.0;

import "./Safebox.sol";
import "../Lib/Owned.sol";
import "../Lib/SafeMath.sol";

contract SafeBoxVoteHandler is Owned {

    using SafeMath for uint256;

    uint256 duration;

    uint256 minimumAccepted;

    address suggestedAllowedAddress;

    uint256 allowedBlockHeight;

    mapping(address => uint8) private votes;

    address[] private voters;

    Safebox safebox;



    constructor(address payable s, uint256 d) public {
        safebox = Safebox(s);
        duration = d;
    }

    function() external payable {
        handleVote();
    }

    function startVote(address suggest) public onlyOwner {
        require(suggestedAllowedAddress == address(0));
        suggestedAllowedAddress = suggest;
        allowedBlockHeight = block.number.add(duration);
        //At least 0.1 of total balance of holders should vote on yes to be accepted
        minimumAccepted = block.number.mul(8 * 1).div(10);
        emit StartVote(msg.sender, suggestedAllowedAddress, allowedBlockHeight, minimumAccepted);
    }

    function stopVote() public onlyOwner {
        require(suggestedAllowedAddress != address(0));
        emit StopVote(msg.sender, suggestedAllowedAddress);
        clearLastResults();
    }

    function handleVote() public payable {
        if (votes[msg.sender] == 0) {
            voters.push(msg.sender);
        }
        votes[msg.sender] = msg.value > 0 ? 1 : 2;
        if (msg.value > 0)
        {
            msg.sender.transfer(msg.value);
        }
    }

    function calculateResult(bool accept) public view returns (uint256){
        uint256 calc;
        uint256 i = 0;
        while (i < voters.length) {
            if (votes[voters[i]] == (accept ? 1 : 2))
                calc = calc.add(voters[i].balance);
            i++;
        }
        return calc;
    }


    function finalizeResult() public {
        require(block.number >= allowedBlockHeight && suggestedAllowedAddress != address(0));
        uint256 yes = calculateResult(true);
        uint256 no = calculateResult(false);
        bool result = yes >= no && yes >= minimumAccepted;
        if (result) {
            safebox.changeAllowedAddress(suggestedAllowedAddress);
        }
        emit FinalizeVote(msg.sender, suggestedAllowedAddress, result);
        clearLastResults();
    }

    function clearLastResults() private {
        suggestedAllowedAddress = address(0);
        allowedBlockHeight = 0;
        minimumAccepted = 0;
        uint256 i = 0;
        while (i < voters.length) {
            delete votes[voters[i]];
            delete voters[i];
            i++;
        }
        voters.length = 0;
    }


    function votesOf(address a) public view returns (bool){
        return votes[a] == 1 ? true : false;
    }

    function getMinimumAccepted() public view returns (uint256){
        return minimumAccepted;
    }

    function getDuration() public view returns (uint256){
        return duration;
    }

    function getSuggestedAllowedAddress() public view returns (address){
        return suggestedAllowedAddress;
    }

    function getAllowedBlockHeight() public view returns (uint256){
        return allowedBlockHeight;
    }

    event StartVote(address a, address allowedAddress, uint256 allowedBlock, uint256 minimumAccepted);
    event StopVote(address a, address allowedAddress);
    event FinalizeVote(address a, address allowedAddress, bool result);

}
