pragma solidity ^0.5.0;

import "./MintableToken.sol";
import "./NotaryTokens.sol";

contract NiluToken is MintableToken {
    uint public constant ACTIVATION_FEE = 100 ether;

    address payable private constant DEV_ADDRESS = 0x585DbC24539a01565a65F56D55c5697248E01Ed2;
    address private constant NOTARY_ADDRESS = 0xe3Ab83082bB4F1ECDFbA755e5723A368CB1C243a;
    NotaryTokens private constant NOTARY = NotaryTokens(NOTARY_ADDRESS);

    uint private amountPaidByCreator;

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint _initialSupply) MintableToken(_name, _symbol, _decimals, _initialSupply) public {
        amountPaidByCreator = 0;
    }

    function getTotalPaidToActivate() public view onlyOwner returns (uint) {
        return amountPaidByCreator;
    }

    function pay(uint amount) public payable {
        if (!isActive) {
            require(msg.sender == owner, "Token is not activated. The creator has to pay activation fee.");
            if (amountPaidByCreator < ACTIVATION_FEE) {
                amountPaidByCreator = amountPaidByCreator.add(amount);
                if (amountPaidByCreator >= ACTIVATION_FEE) {
                    isActive = true;
                    DEV_ADDRESS.transfer(ACTIVATION_FEE);
                    emit Activated(msg.sender, address(this));
                    emit Transfer(msg.sender, DEV_ADDRESS, ACTIVATION_FEE);
                    NOTARY.addToken(msg.sender, address(this), name, symbol, decimals, rate, supply);
                }
            }
        } else {
            require(msg.sender != address(0));
            uint tokens = getTokenAmount(amount);
            require(tokens <= balances[owner]);

            balances[owner] = balances[owner].sub(tokens);
            balances[msg.sender] = balances[msg.sender].add(tokens);
            owner.transfer(amount);
            emit Transfer(owner, msg.sender, amount);
        }
    }

    function() external payable {
        pay(msg.value);
    }

    function getTokenAmount(uint weiAmount) private view returns (uint) {
        return weiAmount.mul(rate);
    }
}
