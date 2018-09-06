pragma solidity ^0.4.11;

import "./SafeMath.sol";
import "./MintableToken.sol";

// This is just a simple example of a coin-like contract.
// It is not standards compatible and cannot be expected to talk to other
// coin/token contracts. If you want to create a standards-compliant
// token, see: https://github.com/ConsenSys/Tokens. Cheers!

contract BARToken is MintableToken {
    string public webAddress = "www.bar.io";
    string public name = "BARToken";
    string public symbol = "BAR";
    uint256 public decimals = 18;
}
