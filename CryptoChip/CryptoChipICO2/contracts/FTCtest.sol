pragma solidity ^0.4.11;

import './FundToken.sol';
import '../zeppelin-solidity/contracts/crowdsale/CappedCrowdsale.sol';


contract FCTtest is CappedCrowdsale {

    using SafeMath for uint256;
  
    //operational
    bool LockupTokensWithdrawn = false;
    bool mintingBreak = false;
    bool public isFinalized = false;
    uint256 tokensLeft = 150000000;
    uint256 startRate = 1250;

    address[] airdropWallets;
    mapping (address => bool) public gotAirdrop;


    /* --- Wallets --- */

    address admin = 0x1b4568b6ecc631efecbe6fb606464a2ab341fa6f;

    // Pre ICO wallets
    address presaleInvestor = 0xe0968bbd5f7656b812f58bd3bfdbfa345d1528fa;
    uint256 presaleInvestorSum = 1000000; // 0.5%

    address otherPresaleInvestors = 0x5d28fd5879003433188e71aa5cac040afbcb9f30;
    uint256 otherPresaleInvestorsSum = 5000000; // 2.5%

    address ICOadvisor1 = 0xe002310a5d60b39dbb7c113750d7308c4fb915f1;
    uint256 ICOadvisor1Sum = 3800000; // 1.9%

    address ICOadvisor2 = 0x2fa53919b733d5633e3f110570cd0beb1d3a9ba1;
    uint256 ICOadvisor2Sum = 200000; // 0.1%

    address ICOadvisor3 = 0x45f43dc11a65f4fa52ef992cfdd6e28d8f087bec;
    uint256 ICOadvisor3Sum = 2000000; // 1%

    address bounty = 0x55348e77d25b5beaf71b4e53f35651b0df828394;
    uint256 bountySum = 4000000; // 2%

    address postICOpromotion = 0xde724b264d8e01478394462845fcacd7003dc255;
    uint256 postICOpromotionSum = 10000000; // 5%

    // Lockup wallets
    address founder = 0x8f382754cdc10f8418f8a7be2eea2953ee143f10;
    uint256 founderSum = 10000000; // 5%

    address team = 0x32f416964bba3b45e033f535263a92e3f2742431;
    uint256 teamSum = 10000000; // 5%

    address earlyContributors = 0x51f8e3deb61d12d8b8466c77f10a88ade714b8a8;
    uint256 earlyContributorsSum = 4000000; // 2%


    /* --- Time periods --- */


    // // 1509766155 - start: 5:30
    // uint256 fiveThirtyTimeNumber = 1509766155; /* Testing */
    // uint256 fiveMin = 300;
    // uint256 startTimeNumber = fiveThirtyTimeNumber + 3*fiveMin; //1513339200; // 15/12/17-12:00:00 - 1513339200
    // uint256 endTimeNumber = startTimeNumber + 3*fiveMin; //1516017600; // 15/1/18-12:00:00 - 1516017600
    // uint256 lockupPeriod = 3*fiveMin; //15552000; // lockup period, 180 days - 15552000

    // uint256 firstBonusPeriod = fiveMin;//28800; // 8 hours - 28800
    // uint256 secondBonusPeriod = fiveMin;//86400; // 24 hours - 86400
    // uint256 thirdBonusPeriod = fiveMin;//604800; // 1 weak - 604800


    uint256 startTimeNumber = 1513339200; // 15/12/17-12:00:00 - 1513339200
    uint256 endTimeNumber = 1516017600; // 15/1/18-12:00:00 - 1516017600
    uint256 lockupPeriod = 10; // lockup period, 180 days - 15552000

    uint256 firstBonusPeriod = 10; // 8 hours - 28800
    uint256 secondBonusPeriod = 10; // 24 hours - 86400
    uint256 thirdBonusPeriod = 5; // 1 weak - 604800


    uint256 firstBonusEndTime = firstBonusPeriod + startTimeNumber;
    uint256 secondBonusEndTime = secondBonusPeriod + startTimeNumber;
    uint256 thirdBonusEndTime = thirdBonusPeriod + startTimeNumber;




    event LockedUpTokensWithdrawn();
    event Finalized();

    modifier canMint() {
        require(!mintingBreak);
        require(!token.mintingFinished());
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier canWithdrawLockup() {
        require(block.timestamp > endTime + lockupPeriod);
        require(!LockupTokensWithdrawn);
        _;
    }

    function FCTtest() 
    CappedCrowdsale(
        tokensLeft /* 150,000,000 - 75% of 200,000,000 total supply */
    )
    Crowdsale(
        startTimeNumber /* start date - 15/12/17-12:00:00 */, 
        endTimeNumber /* end date - 15/1/18-12:00:00 */, 
        startRate /* start rate - 1250 */, 
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
        if (block.timestamp > firstBonusEndTime) {
            rate = 1150;
        }
        if (block.timestamp > secondBonusEndTime) {
            rate = 1100;
        }
        if (block.timestamp > thirdBonusEndTime) {
            rate = 1000;
        }
    }

    function buyTokens(address beneficiary) public payable {
        calculateCurrentRate();
        super.buyTokens(beneficiary);
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
        token.finishMinting();
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
        uint256 originalTotalSupply = token.totalSupply();
        if (originalTotalSupply != 0) {
            // allocate pre ICO wallets
            token.mint(presaleInvestor, presaleInvestorSum * rate * (10**8));
            token.mint(otherPresaleInvestors, otherPresaleInvestorsSum * rate * (10**8));
            token.mint(ICOadvisor1, ICOadvisor1Sum * rate * (10**8));
            token.mint(ICOadvisor2, ICOadvisor2Sum * rate * (10**8));
            token.mint(ICOadvisor3, ICOadvisor3Sum * rate * (10**8));
            token.mint(bounty, bountySum * rate * (10**8));
            token.mint(postICOpromotion, postICOpromotionSum * rate * (10**8));
            // add pre ICO wallets to airdrop
            airdropWallets.push(presaleInvestor);
            airdropWallets.push(otherPresaleInvestors);
            airdropWallets.push(ICOadvisor1);
            airdropWallets.push(ICOadvisor2);
            airdropWallets.push(ICOadvisor3);
            airdropWallets.push(bounty);
            airdropWallets.push(postICOpromotion);

            if (block.timestamp < endTime) { // crowdsale ended early
                endTime = block.timestamp; // update to start lockup
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
        uint256 originalTotalSupply = token.totalSupply(); // original supply at the end of the sale
        if (originalTotalSupply != 0) {
            for (uint256 i = 0; i < airdropWallets.length; i++) {
                var relativePart = SafeMath.mul(tokensLeft, token.balanceOf(airdropWallets[i])); // Airdrop​(user)​ ​  = ​Unsold​ ​Tokens​ ​x ​TokenPurchase​(user*)​ ​                              / ​TotalTokensSold
                var tokensToDrop = SafeMath.div(relativePart, originalTotalSupply);             // tokensToDrop    = ((tokensLeft  x token.balances[airdropWallets[i]]) = relativePart) / originalTotalSupply
                if (!gotAirdrop[airdropWallets[i]]) 
                token.mint(airdropWallets[i], tokensToDrop);
            }
        }
    }
}