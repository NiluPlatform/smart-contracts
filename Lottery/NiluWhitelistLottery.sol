pragma solidity ^0.5.0;

import "../Lib/Owned.sol";
import "../Lib/SafeMath.sol";
import "./NiluLottery.sol";

contract NiluWhitelistLottery is NiluLottery {


    address payable[] whitelist;

    constructor() public{

    }

    function setWhitelist(address payable[] memory list) public onlyOwner{
        require(lotteryBlock == 0);
        uint256 i = 0;
        while (i < whitelist.length) {
            delete whitelist[i];
            i++;
        }
        whitelist.length = 0;
        i = 0;
        while (i < list.length) {
            whitelist.push(list[i]);
            i++;
        }
    }

    function addToWhitelist(address payable[] memory list) public onlyOwner{
        require(lotteryBlock == 0);
        uint i = 0;
        while (i < list.length) {
            whitelist.push(list[i]);
            i++;
        }
    }

    function removeFromWhitelist(address payable[] memory list) public onlyOwner{
        require(lotteryBlock == 0);
        uint j = 0;
        while (j < list.length) {
            uint i = 0;
            while (i < whitelist.length) {
                if (whitelist[i] == list[j])
                {
                    delete whitelist[i];
                    break;
                }
                i++;
            }
            while (i < whitelist.length - 1) {
                whitelist[i] = whitelist[i + 1];
                i++;
            }
            j++;
        }
    }

    function getWhitelist() public view returns (address payable[] memory){
        return whitelist;
    }


    function doLottery() public  {
       _doLottery(whitelist);
    }


}
