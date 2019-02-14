pragma solidity >= 0.5.0;

interface Bank {
    function totalSupply() external view returns (uint);
    function settle(address depositor) external;
    function balanceOf(address who) external view returns (uint);
    function closeAccount(address who) external view returns (uint);
    function withdraw(address depositor, address payable iban, uint256 amount) external returns (uint);
    function deposit(address depositor, uint256 amount)  payable external returns (uint);
    function transfer(address to, uint value) external returns (bool);
}
