pragma solidity ^0.4.11;

import './BARToken.sol';
import './Crowdsale.sol';
import './Ownable.sol';


contract BARTokenCrowdsale is Ownable, Crowdsale {

    using SafeMath for uint256;

    uint256 public startTimeNumber = 1516881600 + 1; // 15/12/17-12:00:00 - 1516881600
    uint256 public endTimeNumber = 1519560000; // 15/1/18-12:00:00 - 1519560000
    uint256 public startRate = 1250;

    function BARTokenCrowdsale(
        address _admin, /*used as the wallet for collecting funds*/
        address _presaleInvestor,
        address _ICOadvisor1,
        address _ICOadvisor2,
        address _VCandEarlyContributors,
        address _founder,
        address _team,
        address _postICOpromotion,
        address _bounty)
    Crowdsale(
        startTimeNumber /* start date - 15/12/17-12:00:00 */, 
        endTimeNumber /* end date - 15/1/18-12:00:00 */, 
        startRate /* start rate - 1250 */, 
        _admin
    )  
    public 
    {}

    // // creates the token to be sold.
    // // override this method to have crowdsale of a specific MintableToken token.
    function createTokenContract() internal returns (MintableToken) {
        return new BARToken();
    }
}
