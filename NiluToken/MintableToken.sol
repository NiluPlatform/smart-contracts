pragma solidity ^0.5.0;

import "./BaseToken.sol";

contract MintableToken is BaseToken {
    event Mint(address indexed to, uint amount);

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint _initialSupply) BaseToken(_name, _symbol, _decimals) public {
        supply = _initialSupply;
        balances[owner] = supply;
        emit Transfer(address(0), owner, supply);
    }

    modifier hasMintPermission() {
        require(msg.sender == owner, "Only owner can mint new coins");
        _;
    }

    function mint(uint amount) public shouldBeActive hasMintPermission returns (bool) {
        supply = supply.add(amount);
        balances[owner] = balances[owner].add(amount);
        emit Mint(owner, amount);
        emit Transfer(address(0), owner, amount);
        return true;
    }
}
