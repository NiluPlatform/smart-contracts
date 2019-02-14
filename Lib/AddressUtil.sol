pragma solidity >=0.5.0 <0.6.0;

library AddressUtil {

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}
