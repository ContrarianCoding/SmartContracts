pragma solidity ^0.4.11;

import './RoyalCoin.sol';
import '../zeppelin-solidity/contracts/crowdsale/Crowdsale.sol';
import '../zeppelin-solidity/contracts/ownership/Ownable.sol';


contract RoyalCoinCrowdsale is Ownable, Crowdsale {

    using SafeMath for uint256;
  
    //operational
    bool public LockupTokensWithdrawn = false;
    uint256 public constant toDec = 10**18;
    uint256 public tokensLeft = 38000000*toDec;
    uint256 public constant cap = 38000000*toDec;
    uint256 public constant startRate = 500;
    uint256 private accumulated = 0;

    enum State { BeforeSale, NormalSale, ShouldFinalize, Lockup, SaleOver }
    State public state = State.BeforeSale;

    /* --- wallets --- */
// --- 0 - admin - 0xa9b48e5013Ee279388555bC6edf8cD2075A842d1
// --- 1 - advisor1 - 0x646CE0c5fd9e091888b5B9306a5A572BE0225a76
// --- 2 - advisor2 - 0xaBFD45dd1DF4715eA22f1e1FAA8CEdB5Ffc51C1F
// --- 3 - advisor3 - 0xe5bf5f3b4b873ab610f37c82c4e28b774dc5dfc9
// --- 4 - investor - 0x54C2B0e4D50D6602c7afFf26A2bAe602Eb6e6CBf
// --- 5 - team - 0xa9b48e5013Ee279388555bC6edf8cD2075A842d1

    address[6] public wallets;

    uint256 public advisor1Sum = 1100000*toDec;

    uint256 public advisor2Sum = 400000*toDec;

    uint256 public advisor3Sum = 500000*toDec;

    uint256 public investorSum = 5000000*toDec;

    uint256 public teamSum = 5000000*toDec;


    /* --- Time periods --- */

    uint256 public constant endTimeNumber = 1527811200; // 06/01/2018 @ 12:00am (UTC)

    uint256 public constant lockupPeriod = 180 * 1 days;




    event LockedUpTokensWithdrawn();
    event Finalized();

    modifier canWithdrawLockup() {
        require(state == State.Lockup);
        require(endTime.add(lockupPeriod) < block.timestamp);
        _;
    }

    function RoyalCoinCrowdsale(
        address admin,
        address advisor1,
        address advisor2,
        address advisor3,
        address investor,
        address team)
    Crowdsale(
        now + 5, 
        endTimeNumber /* end date - 06/01/2018 @ 12:00am (UTC) */, 
        startRate /* start rate - 500 */, 
        admin
    )  
    public 
    {      
        wallets[0] = admin;
        wallets[1] = advisor1;
        wallets[2] = advisor2;
        wallets[3] = advisor3;
        wallets[4] = investor;
        wallets[5] = team;
        owner = admin;

        token.mint(wallets[1], advisor1Sum);
        token.mint(wallets[2], advisor2Sum);
        token.mint(wallets[3], advisor3Sum);
        token.mint(wallets[4], investorSum);
    }

    // creates the token to be sold.
    // override this method to have crowdsale of a specific MintableToken token.
    function createTokenContract() internal returns (MintableToken) {
        return new RoyalCoin();
    }

    function forwardFunds() internal {
        forwardFundsAmount(msg.value);
    }

    function forwardFundsAmount(uint256 amount) internal {
        var oneMili = amount / 1000;
        var adminAmount = oneMili.mul(960);
        var advisor1Amount = oneMili.mul(32);
        var advisor2Amount = oneMili.mul(8);
        wallets[0].transfer(adminAmount);
        wallets[1].transfer(advisor1Amount);
        wallets[2].transfer(advisor2Amount);
        var left = amount.sub(adminAmount).sub(advisor1Amount).sub(advisor2Amount);
        accumulated = accumulated.add(left);
    }

    function refundAmount(uint256 amount) internal {
        msg.sender.transfer(amount);
    }


    function fixAddress(address newAddress, uint256 walletIndex) onlyOwner public {
        wallets[walletIndex] = newAddress;
    }

    function buyTokensUpdateState() internal {
        if(state == State.BeforeSale) { state = State.NormalSale; }
        require(state != State.ShouldFinalize && state != State.Lockup && state != State.SaleOver);
        if(msg.value.mul(rate) >= tokensLeft) { state = State.ShouldFinalize; }
    }

    function buyTokens(address beneficiary) public payable {
        buyTokensUpdateState();
        var numTokens = msg.value.mul(rate);
        if(state == State.ShouldFinalize) {
            lastTokens(beneficiary);
            finalize();
        }
        else {
            tokensLeft = tokensLeft.sub(numTokens); // if negative, should finalize
            super.buyTokens(beneficiary);
        }
    }

    function lastTokens(address beneficiary) internal {
        require(beneficiary != 0x0);
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokensForFullBuy = weiAmount.mul(rate);// must be bigger or equal to tokensLeft to get here
        uint256 tokensToRefundFor = tokensForFullBuy.sub(tokensLeft);
        uint256 tokensRemaining = tokensForFullBuy.sub(tokensToRefundFor);
        uint256 weiAmountToRefund = tokensToRefundFor.div(rate);
        uint256 weiRemaining = weiAmount.sub(weiAmountToRefund);
        
        // update state
        weiRaised = weiRaised.add(weiRemaining);

        token.mint(beneficiary, tokensRemaining);
        TokenPurchase(msg.sender, beneficiary, weiRemaining, tokensRemaining);

        forwardFundsAmount(weiRemaining);
        refundAmount(weiAmountToRefund);
    }

    function withdrawLockupTokens() canWithdrawLockup public {
        token.mint(wallets[5], teamSum);
        token.finishMinting();
        LockupTokensWithdrawn = true;
        LockedUpTokensWithdrawn();
        state = State.SaleOver;
    }

    function finalizeUpdateState() internal {
        if(now > endTimeNumber) { state = State.ShouldFinalize; }
        if(tokensLeft == 0) { state = State.ShouldFinalize; }
    }

    function finalize() public {
        finalizeUpdateState();
        require (state == State.ShouldFinalize);

        finalization();
        Finalized();
    }

    function finalization() internal {
        endTime = block.timestamp;
        /* - preICO investors - */
        forwardFundsAmount(accumulated);
        tokensLeft = 0;
        state = State.Lockup;
    }
}
