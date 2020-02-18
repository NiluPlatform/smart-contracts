pragma solidity >=0.5.0 <0.6.0;

contract BetaBankAdminInterface {
    function bindIngress(address ingress) external returns(bool);
    function unbindIngress(address ingress)  external returns(bool);
    function decharge(uint256 amount) external returns(uint256);
    function chargeInterests(uint256 amount) external payable returns(bool);
    function payDebts(uint256 amount) external payable returns(bool);
    function autoSettleDebts() external payable returns(uint);
    function receive(uint256 amount) external payable returns(bool);
    function handleWithdraw(address requester, address payable iban, uint256 amount) external returns(uint256);
}
