pragma solidity >=0.5.0 <0.6.0;


contract BetaBankCustomerInterface  {

    function bindIngress(address ingress) external returns(bool);
    function unbindIngress(address ingress)  external returns(bool);
    function receiveProfit(uint256 amount) external returns(bool);

    function setRoundDuration(uint256 rd) external;

    function getRoundDuration() external view returns(uint256);
    function getNextRoundStartBlock() external view returns (uint256);

    function totalSupply() external view returns (uint);
    function balanceOf(address who) external view returns (uint);
    function transfer(address from, address to, uint value) external returns (bool);
    function allowance(address owner, address spender) public view returns (uint);
    function approve(address sender, address spender, uint value) external returns (bool);
    function transferFrom(address sender, address payable from, address to, uint value) external returns (bool);


    function deposit(address depositor, uint256 amount) external returns (bool);
    function requestForBenefit(address depositor) external returns (uint256);

    function isWithdrawAllowed(address depositor, address payable iban, uint256 amount) external view returns (bool);
    function markWithdrawn(address requester, uint256 amount)external returns (bool);
}
