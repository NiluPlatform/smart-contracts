pragma solidity >=0.5.0 <0.6.0;

contract ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address who) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function allowance(address owner, address spender) public view returns (uint);
    function approve(address spender, uint value) public returns (bool);
    function transferFrom(address from, address to, uint value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
