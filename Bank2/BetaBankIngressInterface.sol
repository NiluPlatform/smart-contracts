pragma solidity >=0.5.0 <0.6.0;

contract BetaBankIngressInterface {
   function getIngressOwner() external view returns (address payable);
   function getAdminContract() external view returns (address);
   function getCustomerContract() external view returns (address);
   function setAdminContract(address admin) external returns (bool);
   function setCustomerContract(address customer) external returns (bool);

   function requestForBenefit(address depositor) external returns(uint256);

   function emitTransfer(address from, address to, uint256 value) external;

   function emitApproval(address from, address to, uint256 value) external;

   function allowToMarkWithdrawn(address adr) external view returns(bool);
   function isWithdrawAllowed(address depositor, address payable iban, uint256 amount) external view returns (bool);
   function markWithdrawn(address requester, uint256 amount)external returns (bool);
}
