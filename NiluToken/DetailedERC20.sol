pragma solidity ^0.5.0;

import "./ERC20.sol";
import "../Lib/Owned.sol";

contract DetailedERC20 is ERC20, Owned {
    bool public isActive;
    bool public isPayable;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public rate;

    event Activated(address indexed creator, address indexed tokenAddr);

    constructor(string memory _name, string memory _symbol, uint8 _decimals) public {
        isActive = false;
        isPayable = true;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        rate = 1;
    }

    function setName(string memory _name) public onlyOwner {
        name = _name;
    }

    function setSymbol(string memory _symbol) public onlyOwner {
        symbol = _symbol;
    }

    function setRate(uint _rate) public onlyOwner {
        rate = _rate;
    }
}
