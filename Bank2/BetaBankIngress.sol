pragma solidity >=0.5.0 <0.6.0;

import "../Lib/Owned.sol";
import "./BetaBankCustomerInterface.sol";
import "./BetaBankAdminInterface.sol";
import "./BetaBankIngressInterface.sol";
import "../Lib/SafeMath.sol";

contract BetaBankIngress is Owned  {

    using SafeMath for uint;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    BetaBankCustomerInterface customerInterface;
    BetaBankAdminInterface adminInterface;

    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint public rate = 1;

    constructor(string memory n, string memory s) public {
       name = n;
       symbol = s;
    }

    function getIngressOwner() external view returns (address payable){
        return owner;
    }


    function getAdminContract() external view returns (address) {
        return address(adminInterface);
    }

    function getCustomerContract() external view returns (address){
        return address(customerInterface);
    }

    function setAdminContract(address admin) onlyOwner external returns (bool){
        if ( address(adminInterface) != address(0) ){
            adminInterface.unbindIngress(address(this));
        }
        adminInterface = BetaBankAdminInterface(admin);
        adminInterface.bindIngress(address(this));
        return true;
    }

    function setCustomerContract(address customer) onlyOwner external returns (bool) {
        if ( address(customerInterface) != address(0) ){
          customerInterface.unbindIngress(address(this));
        }
        customerInterface = BetaBankCustomerInterface(customer);
        customerInterface.bindIngress(address(this));
        return true;
    }

    function deposit(address depositor) public payable returns(bool) {
        adminInterface.receive.value(msg.value)(msg.value);
        require(customerInterface.deposit(depositor, msg.value));
        return true;
    }

    function withdraw(address payable iban, uint256 amount) external returns(uint256) {
        return adminInterface.handleWithdraw(msg.sender, iban, amount);
    }

    function requestForMyBenefit() public returns(uint256) {
        return customerInterface.requestForBenefit(msg.sender);
    }

    function requestForBenefit(address depositor) public returns(uint256) {
        return customerInterface.requestForBenefit(depositor);
    }

    function decharge(uint256 amount) onlyOwner external returns(uint256) {
        return adminInterface.decharge(amount);
    }

    function chargeInterests() onlyOwner external payable returns(bool)  {
        adminInterface.chargeInterests.value(msg.value)(msg.value);
        return customerInterface.receiveProfit(msg.value);
    }

    function payDebts() onlyOwner external payable returns(bool)  {
        return adminInterface.payDebts.value(msg.value)(msg.value);
    }

    function autoSettleDebts() onlyOwner external returns(uint)  {
        return adminInterface.autoSettleDebts();
    }

    function allowToMarkWithdrawn(address adr) external view returns(bool){
        return adr == address(this) || adr == address(adminInterface);
    }

    function isWithdrawAllowed(address depositor, address payable iban, uint256 amount) external view returns (bool) {
        return customerInterface.isWithdrawAllowed(depositor, iban, amount);
    }

    function markWithdrawn(address depositor, uint256 paid) external returns (bool) {
        require( msg.sender == address(adminInterface));
        return customerInterface.markWithdrawn(depositor, paid);
    }


    function setName(string calldata n) onlyOwner external {
        name = n;
    }

    function setSymbol(string calldata s) onlyOwner external {
        symbol = s;
    }

    function setRoundDuration(uint256 rd) onlyOwner external {
       customerInterface.setRoundDuration(rd);
    }

    function getRoundDuration() external view returns(uint256){
        return customerInterface.getRoundDuration();
    }

    function getNextRoundStartBlock() external view returns (uint256){
        return customerInterface.getNextRoundStartBlock();
    }

    function totalSupply() external view returns (uint){
        return customerInterface.totalSupply();
    }


    function balanceOf(address who) external view returns (uint){
        return customerInterface.balanceOf(who);
    }


    function allowance(address owner, address spender) public view returns (uint) {
        return customerInterface.allowance(owner, spender);
    }

    function approve(address spender, uint value) public returns (bool) {
        return customerInterface.approve(msg.sender, spender, value);
    }

    function transfer(address to, uint value) external returns (bool){
        return customerInterface.transfer(msg.sender, to, value);
    }


    function transferFrom(address payable from, address to, uint value) public returns (bool){
        return customerInterface.transferFrom(msg.sender, from, to, value);
    }

    function () external payable {
        require(msg.sender != owner);
        if ( msg.value > 0 ){
            deposit(msg.sender);
        } else {
            requestForBenefit(msg.sender);
        }
    }

    function emitTransfer(address from, address to, uint256 value) external {
        require(msg.sender == address(customerInterface));
        emit Transfer(from , to, value);
    }


    function emitApproval(address from, address to, uint256 value) external {
        require(msg.sender == address(customerInterface));
        emit Approval(from , to, value);
    }
}
