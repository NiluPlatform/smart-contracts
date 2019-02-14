pragma solidity ^0.5.0;

import "../Lib/Owned.sol";
import "../Lib/AddressUtil.sol";

contract Safebox is Owned {


    using AddressUtil for address;
    using AddressUtil for address payable;

    address allowedAddress;

    address voteHandlerAddress;

    function() external payable {
    }


    function setAllowedAddress(address a) public onlyOwner {
        require(a.isContract() && allowedAddress == address(0));
        allowedAddress = a;
        emit SetAllowedAddress(a);
    }

    function changeAllowedAddress(address a) public  {
        require(voteHandlerAddress != address(0)
        && msg.sender == voteHandlerAddress
        && a.isContract());
        allowedAddress = a;
        emit ChangeAllowedAddress(a);
    }

    function setVoteHandler(address a) public onlyOwner {
        require(a.isContract());
        voteHandlerAddress = a;
        emit SetVoteHandler(a);
    }


    function empty() public {
        require(msg.sender == allowedAddress);
        uint256 val = address(this).balance;
        msg.sender.transfer(val);
        emit Empty(msg.sender, val);
    }

    function withdraw(uint256 value) public {
        require(msg.sender == allowedAddress && value <= address(this).balance);
        (bool success, bytes memory returnData) = msg.sender.call.value(value).gas(200000)("");
        require(success);
        emit Withdraw(msg.sender, value);
    }

    function sendTo(address payable a, uint256 value) public {
        require(msg.sender == allowedAddress && value <= address(this).balance && !a.isContract());
        a.transfer(value);
        emit SendTo(msg.sender, a, value);
    }

    function getAllowedAddress() public view returns (address){
        return allowedAddress;
    }

    function getVoteHandlerAddress() public view returns (address){
        return voteHandlerAddress;
    }

    event SetVoteHandler(address voteHandler);
    event ChangeAllowedAddress(address allowedAddress);
    event SetAllowedAddress(address allowedAddress);
    event Empty(address a, uint256 value);
    event Withdraw(address a, uint256 value);
    event SendTo(address a, address to, uint256 value);
}
