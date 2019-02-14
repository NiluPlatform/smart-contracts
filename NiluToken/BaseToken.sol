pragma solidity ^0.5.0;

import "./DetailedERC20.sol";
import "../Lib/SafeMath.sol";

contract BaseToken is DetailedERC20 {
    using SafeMath for uint;

    uint internal supply;
    mapping(address => uint) internal balances;
    mapping(address => mapping(address => uint)) internal allowed;

    constructor(string memory _name, string memory  _symbol, uint8 _decimals) DetailedERC20(_name, _symbol, _decimals) public {

    }

    modifier shouldBeActive() {
        require(isActive);
        _;
    }

    function totalSupply() external view returns (uint) {
        return supply;
    }

    function balance() public view returns (uint) {
        return balances[msg.sender];
    }

    function balanceOf(address who) external view returns (uint) {
        return balances[who];
    }

    function transfer(address to, uint value) external shouldBeActive returns (bool) {
        require(to != address(0), "Can not transfer to blackhole");
        require(value <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint) {
        return allowed[owner][spender];
    }

    function approve(address spender, uint value) public shouldBeActive returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public shouldBeActive returns (bool) {
        require(to != address(0), "Can not transfer to blackhole");
        require(value <= balances[from], "Insufficient balance");
        require(value <= allowed[from][msg.sender], "Not allowed");

        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

    function transferAnyERC20Token(address tokenAddress, uint value) public shouldBeActive onlyOwner returns (bool) {
        return ERC20(tokenAddress).transfer(owner, value);
    }
}
