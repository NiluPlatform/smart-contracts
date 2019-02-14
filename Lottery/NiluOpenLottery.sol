pragma solidity ^0.5.0;

import "../Lib/Owned.sol";
import "../Lib/SafeMath.sol";
import "./NiluLottery.sol";

contract NiluOpenLottery is NiluLottery {


    constructor() public{

    }

    function doLottery() public {
       _doLottery(participants);
    }


}
