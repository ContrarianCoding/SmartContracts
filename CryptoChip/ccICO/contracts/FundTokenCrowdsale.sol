pragma solidity 0.4.19;

import './FundToken.sol';
import '../zeppelin-solidity/contracts/crowdsale/Crowdsale.sol';
import '../zeppelin-solidity/contracts/ownership/Ownable.sol';


contract FundTokenCrowdsale is Ownable, Crowdsale {

    using SafeMath for uint256;
  
    //operational
    bool public LockupTokensWithdrawn = false;
    uint256 public constant toDec = 10**18;
    uint256 public tokensLeft = 56000000*toDec;
    
    enum State { BeforeSale, FirstBonus, SecondBonus, ThirdBonus, NormalSale, ShouldFinalize, Lockup, SaleOver }
    State public state = State.BeforeSale;
    mapping (address => uint256) public refRecord;
    mapping (address => uint256) public saleRecord;
    mapping (address => bool) public gotAirdrop;


 /* --- Wallets --- */

    address[8] public wallets;
    //address public admin;//0xA279729414b12a8611523d9dEd9DF79d47Ac91AE;

    // Pre ICO wallets

    //address public presaleInvestor;//0x93da612b3DA1eF05c5D80c9B906bf9e7aAdc4a23;
    uint256 public presaleInvestorSum = 2000000*toDec; // 0 - 2.5%

    //address public ICOadvisor1;//0x1EB5cc8E0825dfE322df4CA44ce8522981874d51;
    uint256 public ICOadvisor1Sum = 1360000*toDec; // 1 - 1.7%

    //address public ICOadvisor2;//0xe05416EAD6d997C8bC88A7AE55eC695c06693C58;
    uint256 public ICOadvisor2Sum = 240000*toDec; // 2 - 0.3%

    // Lockup wallets
    //address public VCandEarlyContributors;//0x84Be3A92D9830c876Ad774ADecf86E6f876C405f;
    uint256 public VCandEarlyContributorsSum = 3600000*toDec; // 3 - 4.5%

    //address public founder;//0x43D158140Cd6f371cb4Ba29E98B9bE571Ae673dF;
    uint256 public founderSum = 4000000*toDec + 2; // 4 - 5%

    //address public team;//0xcc3b21c8044254be4428A53D71309B6420307dE6;
    uint256 public teamSum = 5600000*toDec + 1; // 5 - 7%

    // No lockup, no airdrop​

    //address public postICOpromotion;//0xEeaD145AdC3ba320C22Aa2d9c8b3EB018E25c74d;
    uint256 public postICOpromotionSum = 4000000*toDec; // 7 - 5%

    //address public bounty;//0x1a04B0571Aee90052ffCf3A57584b31dEe630727;
    uint256 public bountySum = 3200000*toDec; // 6 - 4%

    uint256 public tokensSold = 3600000*toDec;//0000000000000000;// sum of presale tokens distributed that are considered for airdrop

    // /* --- Time periods --- */

    uint256 public lockupPeriod = 180 * 1 days; // 180 days - 15552000

    uint256 public firstBonusPeriod = 8 * 1 hours;
    uint256 public secondBonusPeriod = 1 * 1 days + firstBonusPeriod;
    uint256 public thirdBonusPeriod = 7 * 1 days + secondBonusPeriod;

    uint256 public firstBonusEndTime = firstBonusPeriod + 1516881600;
    uint256 public secondBonusEndTime = secondBonusPeriod + 1516881600;
    uint256 public thirdBonusEndTime = thirdBonusPeriod + 1516881600;



    event LockedUpTokensWithdrawn();
    event Finalized();

    modifier canWithdrawLockup() {
        require(state == State.Lockup);
        require(endTime.add(lockupPeriod) < block.timestamp);
        _;
    }

    modifier canGetAirdrop(address beneficiary) {
        require(state == State.Lockup || state == State.SaleOver);
        require(!gotAirdrop[beneficiary]);
        require(saleRecord[beneficiary] > 0);  
        _;
    }

    function FundTokenCrowdsale(
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
        1516881600, // 2018-01-25T12:00:00+00:00 - 1516881600
        1519560000,// 2018-02-25T12:00:00+00:00 - 1519560000 
        1250,/* start rate - 1250 */
        _admin
    )  
    public 
    {      
        wallets[0] = _presaleInvestor;
        wallets[1] = _ICOadvisor1;
        wallets[2] = _ICOadvisor2;
        wallets[3] = _VCandEarlyContributors;
        wallets[4] = _founder;
        wallets[5] = _team;
        wallets[6] = _postICOpromotion;
        wallets[7] = _bounty;
        owner = _admin;
    }

    // creates the token to be sold.
    // override this method to have crowdsale of a specific MintableToken token.
    function createTokenContract() internal returns (MintableToken) {
        return new FundToken();
    }

    function forwardFundsAmount(uint256 amount) internal {
        wallet.transfer(amount);
    }

    function refundAmount(uint256 amount) internal {
        msg.sender.transfer(amount);
    }


    function fixAddress(address newAddress, uint256 walletIndex) onlyOwner public {
        wallets[walletIndex] = newAddress;
    }

    function calculateCurrentRate(State stat) internal {
        if (stat == State.SecondBonus) {
            rate = 1150;
        }
        if (stat == State.ThirdBonus) {
            rate = 1100;
        }
        if (stat == State.NormalSale) {
            rate = 1000;
        }
    }

    function buyTokensUpdateState() internal {
        var temp = state;
        if(temp == State.BeforeSale && now >= startTime) { temp = State.FirstBonus; }
        if(temp == State.FirstBonus && now >= firstBonusEndTime) { temp = State.SecondBonus; }
        if(temp == State.SecondBonus && now >= secondBonusEndTime) { temp = State.ThirdBonus; }
        if(temp == State.ThirdBonus && now >= thirdBonusEndTime) { temp = State.NormalSale; }
        calculateCurrentRate(temp);
        require(temp != State.ShouldFinalize && temp != State.Lockup && temp != State.SaleOver);
        if(msg.value.mul(rate) >= tokensLeft) { temp = State.ShouldFinalize; }
        state = temp;
    }

    function buyTokens(address beneficiary) public payable {
        buyTokensUpdateState();
        var numTokens = msg.value.mul(rate);
        if(state == State.ShouldFinalize) {
            lastTokens(beneficiary);
            numTokens = tokensLeft;
        }
        else {
            super.buyTokens(beneficiary);
        }
        tokensLeft = tokensLeft.sub(numTokens);
        tokensSold = tokensSold.add(numTokens);
        saleRecord[beneficiary] = saleRecord[beneficiary].add(numTokens);
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
        token.mint(wallets[3], VCandEarlyContributorsSum);
        token.mint(wallets[4], founderSum);
        token.mint(wallets[5], teamSum);
        
        token.finishMinting();
        LockupTokensWithdrawn = true;
        LockedUpTokensWithdrawn();
        state = State.SaleOver;
    }

    function finalize() public {
        if(now > endTime) { state = State.ShouldFinalize; }
        require (state == State.ShouldFinalize);
        finalization();
        Finalized();
    }

    function finalization() internal {
        endTime = block.timestamp; // update to start lockup
        var tok = token;

        tok.mint(wallets[0], presaleInvestorSum);
        tok.mint(wallets[1], ICOadvisor1Sum);
        tok.mint(wallets[2], ICOadvisor2Sum);
        
        tok.mint(wallets[6], postICOpromotionSum);
        tok.mint(wallets[7], bountySum);

        token = tok;
        saleRecord[wallets[0]] = saleRecord[wallets[0]].add(presaleInvestorSum);//add presale sums for airdrop
        saleRecord[wallets[1]] = saleRecord[wallets[1]].add(ICOadvisor1Sum);
        saleRecord[wallets[2]] = saleRecord[wallets[2]].add(ICOadvisor2Sum);
        state = State.Lockup;
    }
    

    function getAirdrop(address beneficiary) canGetAirdrop(beneficiary) public {
        var relativePart = tokensLeft.mul(saleRecord[beneficiary]); // Airdrop​(user)​ ​  = ​Unsold​ ​Tokens​ ​x ​TokenPurchase​(user*)​ ​                              / ​TotalTokensSold
        var tokensToDrop = relativePart.div(tokensSold);             // tokensToDrop    = ((tokensLeft  x token.balances[airdropWallets[i]]) = relativePart) / originalTotalSupply
        token.mint(beneficiary, tokensToDrop);
        gotAirdrop[beneficiary] = true;
    }
}

