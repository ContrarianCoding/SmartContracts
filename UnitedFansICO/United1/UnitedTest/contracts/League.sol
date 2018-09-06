pragma solidity 0.4.11;

import './UnitedfansToken.sol';
import './Team.sol';
import '../zeppelin-solidity/contracts/ownership/Ownable.sol';


contract League is Ownable {

    using SafeMath for uint256;
 
    //operational
    Team[20] public teamList;
    uint8[20] public rank;
    uint8[20] public points;

    enum State { BeforeSale, Bonus, NormalSale, ShouldFinalize, Lockup, SaleOver }
    State public state = State.BeforeSale;
//0x0662a2F97833B9b120ED40D4E60CeEC39C71ef18 - 2% Ether
//0xDea8e0a4eFa3EBCF9b5e848b8C62CA84b9102F7a - 1%
//0xa364826CB4D55e520c39A707879F16fdAf79c30B - 0.8%
//0xe05416EAD6d997C8bC88A7AE55eC695c06693C58 - 0.2%
    /* --- Ether wallets --- */
// Admin ETH Wallet: 0x1dc521277b6954C4D5c7fea4D2292BfA87Db58D7

// Presale Investors (25m Tokens): 0x11582B40E2A8AB5ac53BC88BDDB925D0909cC332

// Advisers (3m Tokens): 0x52f029cdF6C5a64544B454010028aB6c6AF61F14

// Bounty (3m Tokens): 0xE1A98368aB2C7761A27ca5a5a422252345fE3f96

// Public Exchange Liquidity (3m):  0x11EbC3d8C11fe6398509F01EcC78491dEE1E8B63

// Team LOCKUP (5m Tokens): 0x4C6131f01c0e34b8D74d66a62AD4B6ab85e2E7c9


    address[9] public wallets;

    uint256 public PresaleInvestorsSum = 25000000*toDec; // 0 - 25%

    uint256 public AdvisersSum = 3000000*toDec; // 1 - 3%

    uint256 public BountySum = 3000000*toDec; // 2 - 3%

    uint256 public PublicExchangeLiquiditySum = 3000000*toDec; // 3 - 3%

    uint256 public TeamSum = 5000000*toDec; // 4 - 5%

    uint256 public Adviser2Sum = 1000000*toDec; // 6 - 1%

    uint256 public Adviser3Sum = 800000*toDec; // 7 - 0.8%

    uint256 public Adviser4Sum = 200000*toDec; // 8 - 0.2%


    // /* --- Time periods --- */

    uint256 public startTimeNumber = 1519819200;// Wed, 28 Feb 2018 12:00:00 +0000

    uint256 public endTimeNumber = 1521633600;// Wed, 21 Mar 2018 12:00:00 +0000

    uint256 public lockupPeriod = 180 * 1 days;

    uint256 public bonusPeriod = 1 * 1 days;

    uint256 public bonusEndTime = bonusPeriod + startTimeNumber;



    event LockedUpTokensWithdrawn();
    event Finalized();

    modifier canWithdrawLockup() {
        require(state == State.Lockup);
        require(endTime.add(lockupPeriod) < block.timestamp);
        _;
    }

    function MoonliteTokenCrowdsale(
        address _admin, /*used as the wallet for collecting funds*/
        address PresaleInvestors,
        address Adviser,
        address Bounty,
        address PublicExchangeLiquidity,
        address Team,
        address adv1,
        address adv2,
        address adv3,
        address adv4)
    Crowdsale(
        startTimeNumber, // 2018-02-01T00:00:00+00:00 - 1517443200
        endTimeNumber, // 2018-08-01T00:00:00+00:00 - 
        1000,/* start rate - 1000 */
        _admin
    )  
    public 
    {      
        wallets[0] = PresaleInvestors;
        wallets[1] = Adviser;
        wallets[2] = Bounty;
        wallets[3] = PublicExchangeLiquidity;
        wallets[4] = Team;
        wallets[5] = adv1;
        wallets[6] = adv2;
        wallets[7] = adv3;
        wallets[8] = adv4;
        token.mint(wallets[0], PresaleInvestorsSum);
        token.mint(wallets[1], AdvisersSum);
        token.mint(wallets[2], BountySum);
        token.mint(wallets[3], PublicExchangeLiquiditySum);
        token.mint(wallets[6], Adviser2Sum);
        token.mint(wallets[7], Adviser3Sum);
        token.mint(wallets[8], Adviser4Sum);
    }


    function updateGame(uint8 teamOneIndex, uint8 teamTwoIndex, uint8 teamOneScore, uint8 teamTwoScore, uint8 teamOneHome) {
        var WinLose = teamOneScore > teamTwoScore;
        var RankDiff = points[teamOneIndex] - points[teamTwoIndex];
        if(RankDiff >= 0 && !WinLose || RankDiff <= 0 && WinLose) RankDiff = 0;
        var GoalDiff = teamOneScore - teamTwoScore;
        var GoalRat = (teamOneScore + 1)/(teamTwoScore + 1);
        points[teamOneIndex] = points[teamOneIndex] + WinLose*winLosePoints + RankDiff*RankDiffPoints + GoalDiff*GoalDiffPoints + GoalRat*GoalRatPoints + (1 - teamOneHome)*teamOneHomePoints;
        points[teamTwoIndex] = points[teamTwoIndex] + (1 - WinLose)*winLosePoints - RankDiff*RankDiffPoints - GoalDiff*GoalDiffPoints - GoalRat*GoalRatPoints + teamOneHome*teamOneHomePoints;
    }
    // creates the token to be sold.
    // override this method to have crowdsale of a specific MintableToken token.
    function createTokenContract() internal returns (MintableToken) {
        return new MoonliteToken();
    }

    function forwardFunds() internal {
        forwardFundsAmount(msg.value);
    }

    function forwardFundsAmount(uint256 amount) internal {
        var twoPercent = amount.div(50);
        var adminAmount = twoPercent.mul(49);
        wallet.transfer(adminAmount);
        wallets[5].transfer(twoPercent);
        var left = amount.sub(adminAmount).sub(twoPercent);
        accumulated = accumulated.add(left);
    }

    function refundAmount(uint256 amount) internal {
        msg.sender.transfer(amount);
    }

    function fixAddress(address newAddress, uint256 walletIndex) onlyOwner public {
        wallets[walletIndex] = newAddress;
    }

    function calculateCurrentRate() internal {
        if (state == State.NormalSale) {
            rate = 500;
        }
    }

    function buyTokensUpdateState() internal {
        if(state == State.BeforeSale && now >= startTimeNumber) { state = State.Bonus; }
        if(state == State.Bonus && now >= bonusEndTime) { state = State.NormalSale; }
        calculateCurrentRate();
        require(state != State.ShouldFinalize && state != State.Lockup && state != State.SaleOver && msg.value >= toDec.div(10));
        if(msg.value.mul(rate) >= tokensLeft) { state = State.ShouldFinalize; }
    }

    function buyTokens(address beneficiary) public payable {
        buyTokensUpdateState();
        var numTokens = msg.value.mul(rate);
        if(state == State.ShouldFinalize) {
            lastTokens(beneficiary);
            numTokens = tokensLeft;
        }
        else {
            tokensLeft = tokensLeft.sub(numTokens); // if negative, should finalize
            super.buyTokens(beneficiary);
        }
    }

    function buyCoinsUpdateState(uint256 amount) internal {
        if(state == State.BeforeSale && now >= startTimeNumber) { state = State.Bonus; }
        if(state == State.Bonus && now >= bonusEndTime) { state = State.NormalSale; }
        calculateCurrentRate();
        require(state != State.ShouldFinalize && state != State.Lockup && state != State.SaleOver && amount >= toDec.div(10));
        if(amount.mul(rate) >= tokensLeft) { state = State.ShouldFinalize; }
    }

    function buyCoins(address beneficiary, uint256 amount) public onlyOwner {
        buyCoinsUpdateState(amount);
        var numTokens = amount.mul(rate);
        if(state == State.ShouldFinalize) {
            lastTokens(beneficiary);
            numTokens = tokensLeft;
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
        token.mint(wallets[4], TeamSum);
        LockupTokensWithdrawn = true;
        LockedUpTokensWithdrawn();
        state = State.SaleOver;
    }

    function finalizeUpdateState() internal {
        if(now > endTime) { state = State.ShouldFinalize; }
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
        forwardFundsAmount(accumulated);
        /* - preICO investors - */
        tokensLeft = 0;
        state = State.Lockup;
    }
}
