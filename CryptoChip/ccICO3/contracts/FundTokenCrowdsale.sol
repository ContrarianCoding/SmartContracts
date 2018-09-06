pragma solidity ^0.4.11;

import "./FundToken.sol";
import "../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "../zeppelin-solidity/contracts/crowdsale/Crowdsale.sol";


contract FundTokenCrowdsale is Ownable, Crowdsale {}