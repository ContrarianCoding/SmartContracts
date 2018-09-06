pragma solidity ^ 0.4.11;

contract SafeMath {
    function safeMul(uint a, uint b) internal returns(uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal returns(uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns(uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }


}

contract ERC20 {
    uint public totalSupply;

    function balanceOf(address who) constant returns(uint);

    function allowance(address owner, address spender) constant returns(uint);

    function transfer(address to, uint value) returns(bool ok);

    function transferFrom(address from, address to, uint value) returns(bool ok);

    function approve(address spender, uint value) returns(bool ok);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


contract Ownable {
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) 
            owner = newOwner;
    }

    function kill() {
        if (msg.sender == owner) 
            selfdestruct(owner);
    }

    modifier onlyOwner() {
        if (msg.sender == owner)
        _;
    }
}

contract Pausable is Ownable {
    bool public stopped;

    modifier stopInEmergency {
        if (stopped) {
            revert();
        }
        _;
    }

    modifier onlyInEmergency {
        if (!stopped) {
            revert();
        }
        _;
    }

    // Called by the owner in emergency, triggers stopped state
    function emergencyStop() external onlyOwner {
        stopped = true;
    }

    // Called by the owner to end of emergency, returns to normal state
    function release() external onlyOwner onlyInEmergency {
        stopped = false;
    }
}



// Base contract supporting async send for pull payments.
// Inherit from this contract and use asyncSend instead of send.
contract PullPayment {
    mapping(address => uint) public payments;

    event RefundETH(address to, uint value);

    // Store sent amount as credit to be pulled, called by payer
    function asyncSend(address dest, uint amount) internal {
        payments[dest] += amount;
    }
    // TODO: check
    // Withdraw accumulated balance, called by payee
    function withdrawPayments() internal returns (bool) {
        address payee = msg.sender;
        uint payment = payments[payee];

        if (payment == 0) {
            revert();
        }

        if (this.balance < payment) {
            revert();
        }

        payments[payee] = 0;

        if (!payee.send(payment)) {
            revert();
        }
        RefundETH(payee, payment);
        return true;
    }
}

/// @title Migration Agent interface
contract MigrationAgent {
    function migrateFrom(address _from, uint256 _value);
}

// Crowdsale Smart Contract
// This smart contract collects ETH and in return sends SOCX tokens to the Backers
contract Crowdsale is SafeMath, Pausable, PullPayment {

    struct Backer {
        uint weiReceived; // amount of ETH contributed
        uint SOCXSent; // amount of tokens  sent   
        bool refunded; // in case campaing has failed marke this true when money has been returned 
        }

    SOCX public socx; // SOCX contract reference   
    address public multisigETH; // Multisig contract that will receive the ETH    
    address public team; // Address at which the team SOCX will be sent       
    uint public tokensForTeam; // Amount of tokens to be allocated to team if campaign succeeds
    uint public ETHReceived; // Number of ETH received
    uint public SOCXSentToETH; // Number of SOCX sent to ETH contributors
    uint public startBlock; // Crowdsale start block
    uint public endBlock; // Crowdsale end block
    uint public maxCap; // Maximum number of SOCX to sell
    uint public minCap; // Minimum number of ETH to raise
    uint public minInvestETH; // Minimum amount to invest
    bool public crowdsaleClosed; // Is crowdsale still on going
    uint public tokenPriceWei;
    Step public currentStep;  // to allow for controled steps of the campaign 
    uint public refundCount;  // number of refunds
    uint public totalRefunded; // total amount of refunds
    uint public totalWhiteListed; //white listed users number


    
    uint multiplier = 10000000000; // to provide 10 decimal values
    // Looping through Backer
    mapping(address => Backer) public backers; //backer list
    mapping(address => bool) public whiteList;
    address[] public backersIndex ;   // to be able to itarate through backers when distributing the tokens. 

        // @notice to set and determine steps of crowdsale
    enum Step {
        Unknown,
        Funding,   // time when contributions are in progress
        Refunding  // in case campaign failed during this step contributors will be able to receive refunds
    }


    // @notice to verify if action is not performed out of the campaing range
    modifier respectTimeFrame() {
        if ((block.number < startBlock) || (block.number > endBlock)) 
            revert();
        _;
    }

    modifier minCapNotReached() {
        if (SOCXSentToETH >= minCap) 
            revert();
        _;
    }

    // Events
    event LogReceivedETH(address backer, uint amount, uint tokenAmount);
    event LogWhiteListed(address user, uint whiteListedNum);
    event LogWhiteListedMultiple(uint whiteListedNum);

    // Crowdsale  {constructor}
    // @notice fired when contract is crated. Initilizes all constnat variables.
    function Crowdsale() {
    
        multisigETH = 0x51526cc0b856e77630F5ae17117F5C04fcE8ba06; //TODO: Replace address with correct one
        team = 0x51526cc0b856e77630F5ae17117F5C04fcE8ba06; //TODO: Replace address with correct one
        tokensForTeam = 45000000 * multiplier;              
        SOCXSentToETH = 260653 * multiplier;       
        minInvestETH = 100000000000000000; // 0.1 eth
        startBlock = 0; // ICO start block
        endBlock = 0; // ICO end block            

        maxCap = 45000000 * multiplier;
        // Price is 0.001 eth
        tokenPriceWei = 1000000000000000;
        minCap = 100000 * multiplier;
        currentStep = Step.Funding;
    }

    // @notice Specify address of token contract
    // @param _SOCXAddress {address} address of SOCX token contrac
    // @return res {bool}
    function updateTokenAddress(SOCX _SOCXAddress) public onlyOwner() returns(bool res) {
        socx = _SOCXAddress;  
        return true;    
    }

    function addToWhiteList(address _user) onlyOwner() external returns (bool) {

        if (whiteList[_user] != true) {
            whiteList[_user] = true;
            totalWhiteListed++;
            LogWhiteListed(_user, totalWhiteListed);            
        }
        return true;
    }

    function addToWhiteListMultiple(address[] _users) onlyOwner() external returns (bool) {

         for (uint i = 0; i < _users.length; ++i) {

            if (whiteList[_users[i]] != true) {
                whiteList[_users[i]] = true;
                totalWhiteListed++;                          
            }           
        }
         LogWhiteListedMultiple(totalWhiteListed); 
         return true;
    }

    // @notice Move funds from pre ICO sale
    function transferPreICOFunds() payable  onlyOwner() returns (bool) {
            ETHReceived = safeAdd(ETHReceived, msg.value);
            return true;
    }

    // @notice return number of contributors
    // @return  {uint} number of contributors
    function numberOfBackers()constant returns (uint) {
        return backersIndex.length;
    }

    // @notice set the step of the campaign. 
    // @param _step {Step}
    function setStep(Step _step) external onlyOwner() {
        currentStep = _step;
    }

    // {fallback function}
    // @notice It will call internal function which handels allocation of Ether and calculates SOCX tokens.
    function () payable {         
        contribute(msg.sender);
    }

    // @notice It will be called by owner to start the sale
    // TODO WARNING REMOVE _block parameter and _block variable in function
    function start(uint _block) onlyOwner() {
        startBlock = block.number;
        endBlock = startBlock + _block; //TODO: Replace _block with 25200 for 7 days
        // 1 week in blocks = 25200 (25 * 60 * 24 * 7)/10
        // enable this for live assuming each bloc takes 15 sec .
        crowdsaleClosed = false;
    }

    // @notice It will be called by fallback function whenever ether is sent to it
    // @param  _backer {address} address of beneficiary
    // @return res {bool} true if transaction was successful
    function contribute(address _backer) internal stopInEmergency respectTimeFrame returns(bool res) {

        if (currentStep != Step.Funding)
            revert();    

        if (msg.value < minInvestETH) 
            revert(); // stop when required minimum is not sent

        if (!whiteList[_backer])
            revert();

        uint SOCXToSend = calculateNoOfTokensToSend(msg.value);

        // Ensure that max cap hasn't been reached
        if (safeAdd(SOCXSentToETH, SOCXToSend) > maxCap) 
            revert();

        Backer storage backer = backers[_backer];

        if ( backer.weiReceived == 0)
            backersIndex.push(_backer);

        if (!socx.transfer(_backer, SOCXToSend)) 
            revert(); // Transfer SOCX tokens
        backer.SOCXSent = safeAdd(backer.SOCXSent, SOCXToSend);
        backer.weiReceived = safeAdd(backer.weiReceived, msg.value);
        ETHReceived = safeAdd(ETHReceived, msg.value); // Update the total Ether recived
        SOCXSentToETH = safeAdd(SOCXSentToETH, SOCXToSend);
        
        

        LogReceivedETH(_backer, msg.value, SOCXToSend); // Register event
        return true;
    }

    /* -------------================ Bars fixes ================------------- */

    event LogReceivedCoin(address backer, uint amount, string coin, uint tokenAmount, string txHash);
    event LogCoinRefund(address backer, uint amountCoin, uint amountEth, string coin, string refundWallet, string err, string txHash);
    // --- TODO --- 
    // Preperation code should, calculate the current rate, preform whitelist checks, whitelist and call contributeOffchain
    // Each token should have a collection wallet which may be multisig (for complience)
    // Finalization code should review LogCoinRefund events and sign a transaction from the multisig wallet to the refund address of that amount
    // For credit card contribution refunds would probably have to be manually reviewed in any case for complience
    function contributeOffchain(address _backer, /* token sending address */
                                uint amountCoin, /* amount of the coin sent */
                                uint amount, /* current eth value of amountCoin */
                                string coin, /* name of coin used for payment */
                                string refundWallet, /* coin address of sender used for refund */
                                string txHash
                                ) public stopInEmergency respectTimeFrame onlyOwner /* added - public, only owner */ returns(bool res) {

        if (currentStep != Step.Funding){
            LogCoinRefund(backer, amountCoin, amount, coin, refundWallet, "wrong step", txHash); 
            return false;  
        }

        if (amount < minInvestETH){
            LogCoinRefund(backer, amountCoin, amount, coin, refundWallet, "below minimum", txHash); 
            return false;  
        }

        if (!whiteList[_backer]){
            LogCoinRefund(backer, amountCoin, amount, coin, refundWallet, "not whitelisted", txHash); 
            return false;  
        }

        uint SOCXToSend = calculateNoOfTokensToSend(amount); //need to update function and send msg.value everywhere else.

        // Ensure that max cap hasn't been reached
        if (safeAdd(SOCXSentToETH, SOCXToSend) > maxCap) {
            LogCoinRefund(backer, amountCoin, amount, coin, "over cap", refundWallet);
            return false;
        }

        Backer storage backer = backers[_backer];

        if ( backer.weiReceived == 0)
            backersIndex.push(_backer);

        if (!socx.transfer(_backer, SOCXToSend)) {
            LogCoinRefund(backer, amountCoin, amount, coin, "transfer failed", refundWallet); // may not work!!!!!!!!!!!!!!!
            revert(); // Transfer SOCX tokens
        }
        backer.SOCXSent = safeAdd(backer.SOCXSent, SOCXToSend);
        backer.weiReceived = safeAdd(backer.weiReceived, amount);
        ETHReceived = safeAdd(ETHReceived, amount); // Can be left as it is, because events are registered, 
        SOCXSentToETH = safeAdd(SOCXSentToETH, SOCXToSend); // can become a mapping or add extra variables
        
        LogReceivedCoin(_backer, amountCoin, coin, SOCXToSend, txHash);
        return true;

    }

    // @notice This function will return number of tokens based on time intervals in the campaign
    function calculateNoOfTokensToSend(uint val) constant internal returns (uint) {

        uint tokenAmount = safeDiv(safeMul(val, multiplier), tokenPriceWei);
        

        if (block.number <= startBlock + (25*60)/10)  
            return  tokenAmount + safeDiv(safeMul(tokenAmount, 50), 100);
        else if (block.number <= startBlock + (25*60*24 )/10)
            return  tokenAmount + safeDiv(safeMul(tokenAmount, 25), 100); 
        else if (block.number <= startBlock + (25*60*48)/10) 
                return  tokenAmount + safeDiv(safeMul(tokenAmount, 10), 100); 
        else if (block.number <= startBlock + (25*60*24*3)/10)  
                return  tokenAmount + safeDiv(safeMul(tokenAmount, 5), 100);
        else         
                return  tokenAmount;     
    }

    // @notice This function will finalize the sale.
    // It will only execute if predetermined sale time passed or all tokens are sold.
    function finalize() onlyOwner() {

        if (crowdsaleClosed) 
            revert();

        //TODO uncomment this for live
        uint daysToRefund = (25*60*24*15)/10;
        //uint daysToRefund = 15;  

        if (block.number < endBlock && SOCXSentToETH < maxCap - 100) 
            revert();                                                           // -100 is used to allow closing of the campaing when contribution is near 
                                                                                 // finished as exact amount of maxCap might be not feasible e.g. you can't easily buy few tokens 
                                                                                 // when min contribution is 0.1 Eth

        if (SOCXSentToETH < minCap && block.number < safeAdd(endBlock, daysToRefund)) 
            revert();   
             
        if (SOCXSentToETH >= minCap) {
            if (!multisigETH.send(this.balance)) 
                revert();  // transfer balance to multisig wallet
            if (!socx.transfer(team, tokensForTeam)) 
                revert(); // transfer tokens to admin account or multisig wallet                                
            socx.unlock();    // release lock from transfering tokens. 
        }else {
            if (!socx.burn(this, socx.balanceOf(this))) 
                revert();  // burn all the tokens remaining in the contract                           
        }

        crowdsaleClosed = true;
        
    }

    // @notice
    // This function will allow to transfer unsold tokens to a new
    // contract/wallet address to start new ICO in the future

    function transferRemainingTokens(address _newAddress) onlyOwner() returns (bool) {

        assert(block.number > endBlock + (25*60*24*180)/10); // 180 days after ICO end assuming 24 sec for block       

        if (!socx.transfer(_newAddress, socx.balanceOf(this))) 
            revert(); // transfer tokens to admin account or multisig wallet
        return true;
    }

    // TODO do we want this here?
    // @notice Failsafe drain
    function drain() onlyOwner() {
        if (!owner.send(this.balance)) 
            revert();
    }

    // @notice Prepare refund of the backer if minimum is not reached
    // burn the tokens
    function prepareRefund()  minCapNotReached internal returns (bool) {
        Backer storage backer = backers[msg.sender];

        if (backer.refunded ) 
            revert();        

        if (backer.SOCXSent == 0) 
            revert();           
        if (!socx.burn(msg.sender, backer.SOCXSent)) 
            revert();

        backer.refunded = true;        
        if (backer.weiReceived > 0) {
            asyncSend(msg.sender, backer.weiReceived);
            refundCount ++;
            totalRefunded = safeAdd(totalRefunded, backer.weiReceived);
            return true;
        }
        else 
            return false;        
    }

    // @notice refund the backer
    function refund() public returns (bool) {

        if (currentStep != Step.Refunding)
        revert();

        if (!prepareRefund()) 
            revert();
        if (!withdrawPayments()) 
            revert();
        return true;

    }

 
}

// The SOCX token
contract SOCX is ERC20, SafeMath, Ownable {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals; // How many decimals to show.
    string public version = "v0.1";
    uint public initialSupply;
    uint public totalSupply;
    bool public locked;
    address public crowdSaleAddress;
    uint multiplier = 10000000000;        
    address public migrationMaster;
    address public migrationAgent;
    uint256 public totalMigrated;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    

    // Lock transfer during the ICO
    modifier onlyUnlocked() {
        if (msg.sender != crowdSaleAddress && locked && msg.sender != owner) 
            revert();
        _;
    }

    modifier onlyAuthorized() {
        if ( msg.sender != crowdSaleAddress && msg.sender != owner) 
            revert();
        _;
    }

    // The SOCX Token constructor
    function SOCX(address _crowdSaleAddress, address _migrationMaster ) {
        
        locked = true; // Lock the transfer of tokens during the crowdsale
        initialSupply = 90000000 * multiplier;
        totalSupply = initialSupply;
        name = "SocialX"; // Set the name for display purposes
        symbol = "SOCX"; // Set the symbol for display purposes
        decimals = 10; // Amount of decimals for display purposes
        crowdSaleAddress = _crowdSaleAddress;              
        balances[crowdSaleAddress] = totalSupply;
        migrationMaster = _migrationMaster;
    }


    event Migrate(address indexed _from, address indexed _to, uint256 _value);

    // Token migration support:

    /// @notice Migrate tokens to the new token contract.
    /// @dev Required state: Operational Migration
    /// @param _value The amount of token to be migrated
    function migrate(uint256 _value) onlyUnlocked() external {
        // Abort if not in Operational Migration state.
        
        if (migrationAgent == 0) 
            revert();
        
        // Validate input value.
        if (_value == 0) 
            revert();
        if (_value > balances[msg.sender]) 
            revert();

        balances[msg.sender] -= _value;
        totalSupply -= _value;
        totalMigrated += _value;
        MigrationAgent(migrationAgent).migrateFrom(msg.sender, _value);
        Migrate(msg.sender, migrationAgent, _value);
    }

    /// @notice Set address of migration target contract and enable migration
    /// process.
    /// @dev Required state: Operational Normal
    /// @dev State transition: -> Operational Migration
    /// @param _agent The address of the MigrationAgent contract
    function setMigrationAgent(address _agent) onlyUnlocked() external {
        // Abort if not in Operational Normal state.
        
        if (migrationAgent != 0) 
            revert();
        if (msg.sender != migrationMaster) 
            revert();
        migrationAgent = _agent;
    }

    function resetCrowdSaleAddress(address _newCrowdSaleAddress) onlyAuthorized() {
            crowdSaleAddress = _newCrowdSaleAddress;
    }

    
    function setMigrationMaster(address _master) external {
        if (msg.sender != migrationMaster) 
            revert();
        if (_master == 0) 
            revert();
        migrationMaster = _master;
    }

    function unlock() onlyAuthorized {
        locked = false;
    }

      function lock() onlyAuthorized {
        locked = true;
    }

    function burn( address _member, uint256 _value) onlyAuthorized returns(bool) {
        balances[_member] = safeSub(balances[_member], _value);
        totalSupply = safeSub(totalSupply, _value);
        Transfer(_member, 0x0, _value);
        return true;
    }

    function transfer(address _to, uint _value) onlyUnlocked returns(bool) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) onlyUnlocked returns(bool success) {
        if (balances[_from] < _value) 
            revert(); // Check if the sender has enough
        if (_value > allowed[_from][msg.sender]) 
            revert(); // Check allowance
        balances[_from] = safeSub(balances[_from], _value); // Subtract from the sender
        balances[_to] = safeAdd(balances[_to], _value); // Add the same to the recipient
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns(uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) returns(bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) constant returns(uint remaining) {
        return allowed[_owner][_spender];
    }
}
