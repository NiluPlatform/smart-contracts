pragma solidity >=0.5.0 <0.6.0;

contract Owned {
    constructor() public {
        owner = msg.sender;
    }

    address payable owner;

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner has access to do this function");
        _;
    }
}
