pragma solidity ^0.5.0;


import "../Lib/SafeMath.sol";
import "../Lib/AddressUtil.sol";
import "../Lib/IntegerUtil.sol";
import "../Lib/StringUtil.sol";
import "../Lib/Owned.sol";

contract NotaryTokens is Owned {
    using SafeMath for uint;
    using StringUtil for *;
    using IntegerUtil for uint;
    using AddressUtil for address;

    struct TokenInfo {
        address creator;
        address addr;
        string name;
        string symbol;
        uint8 decimals;
        uint rate;
        uint supply;
    }

    address[] private addresses;
    mapping(address => TokenInfo) private tokensList;

    function addToken(address creator, address tokenAddr, string memory name, string memory symbol, uint8 decimals, uint rate, uint supply) public {
        require(tokenAddr.isContract());
        require(tokensList[tokenAddr].addr == address(0));
        addresses.push(tokenAddr);
        tokensList[tokenAddr] = TokenInfo(creator, tokenAddr, name, symbol, decimals, rate, supply);
    }

    function removeToken(address tokenAddr) public onlyOwner {
        require(tokensList[tokenAddr].addr != address(0));
        delete tokensList[tokenAddr];
        for (uint i = 0; i < addresses.length; i++)
            if (addresses[i] == tokenAddr) {
                delete addresses[i];
                break;
            }
    }

    function count() public view returns (uint) {
        uint result = 0;
        for (uint i = 0; i < addresses.length; i++)
            if (addresses[i] != address(0))
                result = result.add(1);
        return result;
    }

    function countTokensOf(address addr) public view returns (uint) {
        uint result = 0;
        for (uint i = 0; i < addresses.length; i++)
            if (addresses[i] != address(0) && tokensList[addresses[i]].creator == addr)
                result = result.add(1);
        return result;
    }

    function getToken(address addr) public view returns (string memory) {
        string memory result = "";
        TokenInfo memory c = tokensList[addr];
        result = result.toSlice().concat("{\"address\":\"".toSlice());
        result = result.toSlice().concat(addr.toString().toSlice());
        result = result.toSlice().concat("\",\"creator\":\"".toSlice());
        result = result.toSlice().concat(c.creator.toString().toSlice());
        result = result.toSlice().concat("\",\"name\":\"".toSlice());
        result = result.toSlice().concat(c.name.toSlice());
        result = result.toSlice().concat("\",\"symbol\":\"".toSlice());
        result = result.toSlice().concat(c.symbol.toSlice());
        result = result.toSlice().concat("\",\"decimals\":\"".toSlice());
        result = result.toSlice().concat(bytes32(uint(c.decimals)).toString().toSlice());
        result = result.toSlice().concat("\",\"rate\":\"".toSlice());
        result = result.toSlice().concat(bytes32(c.rate).toString().toSlice());
        result = result.toSlice().concat("\",\"totalSupply\":\"".toSlice());
        result = result.toSlice().concat(bytes32(c.supply).toString().toSlice());
        result = result.toSlice().concat("\"}".toSlice());
        return result;
    }

    function tokensOf(address addr) public view returns (string memory) {
        bool s = false;
        string memory result = "[";
        for (uint i = 0; i < addresses.length; i++) {
            if (addresses[i] != address(0) && tokensList[addresses[i]].creator == addr) {
                if (s)
                    result = result.toSlice().concat(",".toSlice());
                TokenInfo memory c = tokensList[addresses[i]];
                result = result.toSlice().concat("{\"address\":\"".toSlice());
                result = result.toSlice().concat(addresses[i].toString().toSlice());
                result = result.toSlice().concat("\",\"creator\":\"".toSlice());
                result = result.toSlice().concat(c.creator.toString().toSlice());
                result = result.toSlice().concat("\",\"name\":\"".toSlice());
                result = result.toSlice().concat(c.name.toSlice());
                result = result.toSlice().concat("\",\"symbol\":\"".toSlice());
                result = result.toSlice().concat(c.symbol.toSlice());
                result = result.toSlice().concat("\",\"decimals\":\"".toSlice());
                result = result.toSlice().concat(bytes32(uint(c.decimals)).toString().toSlice());
                result = result.toSlice().concat("\",\"rate\":\"".toSlice());
                result = result.toSlice().concat(bytes32(c.rate).toString().toSlice());
                result = result.toSlice().concat("\",\"totalSupply\":\"".toSlice());
                result = result.toSlice().concat(bytes32(c.supply).toString().toSlice());
                result = result.toSlice().concat("\"}".toSlice());
                s = true;
            }
        }
        result = result.toSlice().concat("]".toSlice());
        return result;
    }

    function getTokens(uint from, uint size) public view returns (string memory) {
        bool s = false;
        string memory result = "[";
        for (uint i = from; i < from + size && i < addresses.length; i++) {
            if (addresses[i] != address(0)) {
                if (s)
                    result = result.toSlice().concat(",".toSlice());
                TokenInfo memory c = tokensList[addresses[i]];
                result = result.toSlice().concat("{\"address\":\"".toSlice());
                result = result.toSlice().concat(addresses[i].toString().toSlice());
                result = result.toSlice().concat("\",\"creator\":\"".toSlice());
                result = result.toSlice().concat(c.creator.toString().toSlice());
                result = result.toSlice().concat("\",\"name\":\"".toSlice());
                result = result.toSlice().concat(c.name.toSlice());
                result = result.toSlice().concat("\",\"symbol\":\"".toSlice());
                result = result.toSlice().concat(c.symbol.toSlice());
                result = result.toSlice().concat("\",\"decimals\":\"".toSlice());
                result = result.toSlice().concat(bytes32(uint(c.decimals)).toString().toSlice());
                result = result.toSlice().concat("\",\"rate\":\"".toSlice());
                result = result.toSlice().concat(bytes32(c.rate).toString().toSlice());
                result = result.toSlice().concat("\",\"totalSupply\":\"".toSlice());
                result = result.toSlice().concat(bytes32(c.supply).toString().toSlice());
                result = result.toSlice().concat("\"}".toSlice());
                s = true;
            }
        }
        result = result.toSlice().concat("]".toSlice());
        return result;
    }
}
