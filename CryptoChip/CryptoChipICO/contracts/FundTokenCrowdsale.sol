pragma solidity ^0.4.11;

import './FundToken.sol';
import '../zeppelin-solidity/contracts/crowdsale/CappedCrowdsale.sol';


contract FundTokenCrowdsale is CappedCrowdsale {

    using SafeMath for uint256;
  
    //operational
    bool LockupTokensWithdrawn = false;
    bool mintingBreak = false;
    bool public isFinalized = false;
    uint256 tokensLeft = 150000000;

    address[] airdropWallets;
    mapping (address => bool) public gotAirdrop;


    /* --- Wallets --- */

    address admin = 0x7EA52dd5f19cC000896654b4d922eaBdFA001eEd;

    // Pre ICO wallets
    address presaleInvestor = 0x93da612b3DA1eF05c5D80c9B906bf9e7aAdc4a23;
    uint256 presaleInvestorSum = 1000000; // 0.5%

    address otherPresaleInvestors = 0x9f30266B32Da9bF800346402FaAB930aF9f5696F;
    uint256 otherPresaleInvestorsSum = 5000000; // 2.5%

    address ICOadvisor1 = 0xBD1b96D30E1a202a601Fa8823Fc83Da94D71E3cc;
    uint256 ICOadvisor1Sum = 3800000; // 1.9%

    address ICOadvisor2 = 0xe05416EAD6d997C8bC88A7AE55eC695c06693C58;
    uint256 ICOadvisor2Sum = 200000; // 0.1%

    address ICOadvisor3 = 0xc07B35c30ed0f587409B95a7b8B6022aF4dBa808;
    uint256 ICOadvisor3Sum = 2000000; // 1%

    address bounty = 0x1a04B0571Aee90052ffCf3A57584b31dEe630727;
    uint256 bountySum = 4000000; // 2%

    address postICOpromotion = 0xEeaD145AdC3ba320C22Aa2d9c8b3EB018E25c74d;
    uint256 postICOpromotionSum = 10000000; // 5%

    // Lockup wallets
    address founder = 0x43D158140Cd6f371cb4Ba29E98B9bE571Ae673dF;
    uint256 founderSum = 10000000; // 5%

    address team = 0xcc3b21c8044254be4428A53D71309B6420307dE6;
    uint256 teamSum = 10000000; // 5%

    address earlyContributors = 0x84Be3A92D9830c876Ad774ADecf86E6f876C405f;
    uint256 earlyContributorsSum = 4000000; // 2%


    /* --- Time periods --- */

    uint256 startTimeNumber = 1513339200; // 15/12/17-12:00:00 - 1513339200
    uint256 endTimeNumber = 1516017600; // 15/1/18-12:00:00 - 1516017600
    uint256 lockupPeriod = 15552000; // lockup period, 180 days - 15552000

    uint256 firstBonusPeriod = 28800; // 8 hours - 28800
    uint256 secondBonusPeriod = 86400; // 24 hours - 86400
    uint256 thirdBonusPeriod = 604800; // 1 weak - 604800


    uint256 firstBonusEndTime = firstBonusPeriod + startTimeNumber;
    uint256 secondBonusEndTime = secondBonusPeriod + startTimeNumber;
    uint256 thirdBonusEndTime = thirdBonusPeriod + startTimeNumber;




    event LockedUpTokensWithdrawn();
    event Finalized();

    modifier canMint() {
        require(!mintingBreak);
        require(!token.mintingFinished);
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier canWithdrawLockup() {
        require(block.number > endTime + lockupPeriod);
        require(!LockupTokensWithdrawn);
        _;
    }

    function FundTokenCrowdsale() 
    CappedCrowdsale(
        150000000 /* 75% of 200000000 total supply */
    )
    Crowdsale(
        startTimeNumber /* start date - 15/12/17-12:00:00 */, 
        endTimeNumber /* end date - 15/1/18-12:00:00 */, 
        1250 /* start rate */, 
        admin
    )  
    public 
    {          
    }

    // creates the token to be sold.
    // override this method to have crowdsale of a specific MintableToken token.
    function createTokenContract() internal returns (MintableToken) {
        return new FundToken();
    }

    function calculateCurrentRate() internal {
        if (block.number > firstBonusEndTime) {
            rate = 1150;
        }
        if (block.number > secondBonusEndTime) {
            rate = 1100;
        }
        if (block.number > thirdBonusEndTime) {
            rate = 1000;
        }
    }

    function buyTokens(address beneficiary) public payable {
        calculateCurrentRate();
        super(beneficiary);
        var numTokens = SafeMath.mul(msg.value, rate);
        tokensLeft = SafeMath.sub(tokensLeft, numTokens);
        airdropWallets.push(beneficiary);
        if (hasEnded()) {
            finalize();
        }
    }

    function withdrawLockupTokens() onlyAdmin canWithdrawLockup public {
        endMintingBreak();
        calculateCurrentRate();
        token.mint(founder, founderSum);
        token.mint(team, teamSum);
        token.mint(earlyContributors, earlyContributorsSum);
        LockupTokensWithdrawn = true;
        LockedUpTokensWithdrawn();// toAsk - announce lockup withdrawn?
    }

    function finalize() onlyAdmin public {
        require (!isFinalized);
        require (hasEnded());

        finalization();
        Finalized();

        isFinalized = true;
    }

    function finalization() internal {
        calculateCurrentRate();
        var originalTotalSupply = token.totalSupply;
        if (originalTotalSupply != 0) {
            // allocate pre ICO wallets
            token.mint(presaleInvestor, presaleInvestorSum * rate);
            token.mint(otherPresaleInvestors, otherPresaleInvestors * rate);
            token.mint(ICOadvisor1, ICOadvisor1Sum * rate);
            token.mint(ICOadvisor2, ICOadvisor2Sum * rate);
            token.mint(ICOadvisor3, ICOadvisor3Sum * rate);
            token.mint(bounty, bountySum * rate);
            token.mint(postICOpromotion, postICOpromotionSum * rate);
            // add pre ICO wallets to airdrop
            airdropWallets.push(presaleInvestor);
            airdropWallets.push(otherPresaleInvestors);
            airdropWallets.push(ICOadvisor1);
            airdropWallets.push(ICOadvisor2);
            airdropWallets.push(ICOadvisor3);
            airdropWallets.push(bounty);
            airdropWallets.push(postICOpromotion);

            if (block.number < endTime) { // crowdsale ended early
                endTime = block.number; // update to start lockup
            } else {
                doAirdrop();// ended on time, tokens left unsold...
            }
        }
        startMintingBreak();
    }

    function startMintingBreak() internal {
        mintingBreak = true;
    }

    function endMintingBreak() internal {
        mintingBreak = false;
    }

    function doAirdrop() internal {
        var originalTotalSupply = token.totalSupply; // original supply at the end of the sale
        if (originalTotalSupply != 0) {
            for (uint256 i = 0; i < airdropWallets.length; i++) {
                var relativePart = SafeMath.mul(tokensLeft, token.balanceOf(airdropWallets[i])); // Airdrop​(user)​ ​  = ​Unsold​ ​Tokens​ ​x ​TokenPurchase​(user*)​ ​                              / ​TotalTokensSold
                var tokensToDrop = SafeMath.div(relativePart, originalTotalSupply);				// tokensToDrop    = ((tokensLeft  x token.balances[airdropWallets[i]]) = relativePart) / originalTotalSupply
                if (!gotAirdrop[airdropWallets[i]]) 
                token.mint(airdropWallets[i], tokensToDrop);
            }
        }
        delete airdropWallets;
        delete gotAirdrop;
    }
}