pragma solidity ^0.4.11;

import "../zeppelin-solidity/contracts/token/MintableToken.sol";
//import "../zeppelin-solidity/contracts/token/BurnableToken.sol";

// This is just a simple example of a coin-like contract.
// It is not standards compatible and cannot be expected to talk to other
// coin/token contracts. If you want to create a standards-compliant
// token, see: https://github.com/ConsenSys/Tokens. Cheers!

contract RoyalCoin is MintableToken {
    string public name = "Royal Coin";
    string public symbol = "ROYL";
    uint8 public decimals = 18;
}
