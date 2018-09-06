pragma solidity 0.4.11;

import './UnitedfansToken.sol';
//import '../zeppelin-solidity/contracts/crowdsale/Crowdsale.sol';
//import '../zeppelin-solidity/contracts/ownership/Ownable.sol';


contract UnitedfansTokenCrowdsale/* is Ownable, Crowdsale */{

    // using SafeMath for uint256;
 
    // //operational
    // bool public LockupTokensWithdrawn = false;
    // uint256 public constant toDec = 10**2;
    // uint256 public tokensLeft = 30303030*toDec;
    // uint256 public constant cap = 30303030*toDec;
    // uint256 public constant startRate = 12000*toDec;

    // enum State { BeforeSale, NormalSale, ShouldFinalize, SaleOver }
    // State public state = State.BeforeSale;


    // // /* --- Time periods --- */

    // uint256 public startTimeNumber = now;

    // uint256 public endTimeNumber = 1527724800;// Wed, 31 May 2018 12:00:00 +0000

    // event Finalized();

    // modifier canWithdrawLockup() {
    //     require(state == State.Lockup);
    //     require(endTime.add(lockupPeriod) < block.timestamp);
    //     _;
    // }

    // function UnitedfansTokenCrowdsale(address _admin)
    // Crowdsale(
    //     startTimeNumber, // 2018-02-01T00:00:00+00:00 - 1517443200
    //     endTimeNumber, // 2018-08-01T00:00:00+00:00 - 
    //     12000,/* start rate - 1000 */
    //     _admin
    // )  
    // public 
    // {}

    // // creates the token to be sold.
    // // override this method to have crowdsale of a specific MintableToken token.
    // function createTokenContract() internal returns (MintableToken) {
    //     return new UnitedfansToken();
    // }

    // function forwardFunds() internal {
    //     forwardFundsAmount(msg.value);
    // }

    // function forwardFundsAmount(uint256 amount) internal {
    //     wallet.transfer(amount);
    // }

    // function refundAmount(uint256 amount) internal {
    //     msg.sender.transfer(amount);
    // }

    // function buyTokensUpdateState() internal {
    //     if(state == State.BeforeSale && now >= startTimeNumber) { state = State.NormalSale; }
    //     require(state != State.ShouldFinalize && state != State.Lockup && state != State.SaleOver && msg.value >= 25 * 1 ether);
    //     if(msg.value.mul(rate).mul(toDec).div(ether) >= tokensLeft) { state = State.ShouldFinalize; }
    // }

    // function buyTokens(address beneficiary) public payable {
    //     buyTokensUpdateState();
    //     var numTokens = msg.value.mul(rate).mul(toDec).div(ether);
    //     if(state == State.ShouldFinalize) {
    //         lastTokens(beneficiary);
    //         numTokens = tokensLeft;
    //     }
    //     else {
    //         tokensLeft = tokensLeft.sub(numTokens); // if negative, should finalize
    //         super.buyTokens(beneficiary);
    //     }
    // }

    // // function buyCoinsUpdateState(uint256 amount) internal {
    // //     if(state == State.BeforeSale && now >= startTimeNumber) { state = State.NormalSale; }
    // //     require(state != State.ShouldFinalize && state != State.Lockup && state != State.SaleOver && amount >= toDec.div(10));
    // //     if(amount.mul(rate) >= tokensLeft) { state = State.ShouldFinalize; }
    // // }

    // // function buyCoins(address beneficiary, uint256 amount) public onlyOwner {
    // //     buyCoinsUpdateState(amount);
    // //     var numTokens = amount.mul(rate);
    // //     if(state == State.ShouldFinalize) {
    // //         lastTokens(beneficiary);
    // //         numTokens = tokensLeft;
    // //     }
    // //     else {
    // //         tokensLeft = tokensLeft.sub(numTokens); // if negative, should finalize
    // //         super.buyTokens(beneficiary);
    // //     }
    // // }

    // function lastTokens(address beneficiary) internal {
    //     require(beneficiary != 0x0);
    //     require(validPurchase());

    //     uint256 weiAmount = msg.value;

    //     // calculate token amount to be created
    //     uint256 tokensForFullBuy = weiAmount.mul(rate);// must be bigger or equal to tokensLeft to get here
    //     uint256 tokensToRefundFor = tokensForFullBuy.sub(tokensLeft);
    //     uint256 tokensRemaining = tokensForFullBuy.sub(tokensToRefundFor);
    //     uint256 weiAmountToRefund = tokensToRefundFor.div(rate);
    //     uint256 weiRemaining = weiAmount.sub(weiAmountToRefund);
        
    //     // update state
    //     weiRaised = weiRaised.add(weiRemaining);

    //     token.mint(beneficiary, tokensRemaining);
    //     TokenPurchase(msg.sender, beneficiary, weiRemaining, tokensRemaining);

    //     forwardFundsAmount(weiRemaining);
    //     refundAmount(weiAmountToRefund);
    // }

    // function finalizeUpdateState() internal {
    //     if(now > endTime) { state = State.ShouldFinalize; }
    //     if(tokensLeft == 0) { state = State.ShouldFinalize; }
    // }

    // function finalize() public {
    //     finalizeUpdateState();
    //     require (state == State.ShouldFinalize);

    //     finalization();
    //     Finalized();
    // }

    // function finalization() internal {
    //     endTime = block.timestamp;
    //     state = State.SaleOver;
    // }
}
