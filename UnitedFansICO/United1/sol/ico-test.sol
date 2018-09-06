pragma solidity ^ 0.4 .13;

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

    function assert(bool assertion) internal {
        if (!assertion) {
            revert();
        }
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
        if (newOwner != address(0)) owner = newOwner;
    }

    function kill() {
        if (msg.sender == owner) selfdestruct(owner);
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
    function withdrawPayments() {
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
    }
}

// Crowdsale Smart Contract
// This smart contract collects ETH and in return sends SOCX tokens to the Backers
contract Crowdsale is SafeMath, Pausable, PullPayment {

    struct Backer {
        uint weiReceived; // amount of ETH contributed
        uint SOCXSent; // amount of tokens  sent        
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

    uint public totalTokensSold;
    uint public tokenPriceWei;

    
    uint multiplier = 10000000000; // to provide 10 decimal values
    // Looping through Backer
    mapping(address => Backer) public backers; //backer list
    address[] public backersIndex ;   // to be able to itarate through backers when distributing the tokens. 

    // @notice to be used when certain account is required to access the function
    // @param a {address}  The address of the authorised individual
    modifier onlyBy(address a) {
        if (msg.sender != a) revert();
        _;
    }

    // @notice to verify if action is not performed out of the campaing range
    modifier respectTimeFrame() {
        if ((block.number < startBlock) || (block.number > endBlock)) revert();
        _;
    }

    modifier minCapNotReached() {
        if (SOCXSentToETH >= minCap) revert();
        _;
    }

    // Events
    event ReceivedETH(address backer, uint amount, uint tokenAmount);

    // Crowdsale  {constructor}
    // @notice fired when contract is crated. Initilizes all constnat variables.
    function Crowdsale() {
       
        multisigETH = 0xAbA916F9EEe18F41FC32C80c8Be957f5E7efE481; //TODO: Replace address with correct one
        team = 0x027127930D9ae133C08AE480A6E6C2caf1e87861; //TODO: Replace address with correct one
        tokensForTeam = 44000000 * multiplier;
        //TODO: replace with amount of presale tokens
        SOCXSentToETH = 1000000 * multiplier;       
        minInvestETH = 1 ether;
        startBlock = 0; // ICO start block
        endBlock = 0; // ICO end block
        //TODO: Reduce this max cap by presale amount
        maxCap = 46000000 * multiplier;
        // Price is 0.0011 eth
        tokenPriceWei = 1000000000000000;
        minCap = 1000000 * multiplier;
    }

    // @notice Specify address of token contract
    // @param _SOCXAddress {address} address of SOCX token contrac
    // @return res {bool}
    function updateTokenAddress(SOCX _SOCXAddress) public onlyBy(owner) returns(bool res) {
        socx = _SOCXAddress;  
        return true;
    }


    // @notice return number of contributors
    // @return  {uint} number of contributors
    function numberOfBackers()constant returns (uint){
        return backersIndex.length;
    }

    // {fallback function}
    // @notice It will call internal function which handels allocation of Ether and calculates SOCX tokens.
    function () payable {
        if (block.number > endBlock) revert();
        handleETH(msg.sender);
    }

    // @notice It will be called by owner to start the sale
    // TODO WARNING REMOVE _block parameter and _block variable in function
    function start(uint _block) onlyBy(owner) {
        startBlock = block.number;
        endBlock = startBlock + _block; //TODO: Replace 20 with 161280 for actual deployment
        // 2 weeks in blocks = 161280 (4 * 60 * 24 * 7 * 2)
        // enable this for live assuming each bloc takes 15 sec .
    }

    // @notice It will be called by fallback function whenever ether is sent to it
    // @param  _backer {address} address of beneficiary
    // @return res {bool} true if transaction was successful
    function handleETH(address _backer) internal stopInEmergency respectTimeFrame returns(bool res) {

        if (msg.value < minInvestETH) revert(); // stop when required minimum is not sent

        uint SOCXToSend = calculateNoOfTokensToSend();

        // Ensure that max cap hasn't been reached
        if (safeAdd(SOCXSentToETH, SOCXToSend) > maxCap) revert();

        Backer storage backer = backers[_backer];

        if (!socx.transfer(_backer, SOCXToSend)) revert(); // Transfer SOCX tokens
        backer.SOCXSent = safeAdd(backer.SOCXSent, SOCXToSend);
        backer.weiReceived = safeAdd(backer.weiReceived, msg.value);
        ETHReceived = safeAdd(ETHReceived, msg.value); // Update the total Ether recived
        SOCXSentToETH = safeAdd(SOCXSentToETH, SOCXToSend);
        backersIndex.push(_backer);
        

        ReceivedETH(_backer, msg.value, SOCXToSend); // Register event
        return true;
    }

   function calculateNoOfTokensToSend() constant internal returns (uint){

        uint tokenAmount = safeDiv(safeMul(msg.value , multiplier) , tokenPriceWei);
        

       if (block.number <= startBlock  + (4* 60 )  )  
           return  tokenAmount +  safeDiv( safeMul(tokenAmount , 25), 100);
        else if (block.number <=  startBlock  + (4* 60 * 24 ))
           return  tokenAmount +  safeDiv( safeMul(tokenAmount , 15), 100); 
        else if (block.number <=  startBlock  + (4* 60 * 24 * 2)) 
            return  tokenAmount + safeDiv( safeMul(tokenAmount , 10), 100); 
        else if (block.number <=  startBlock  + (4* 60 * 24 * 7))  
            return  tokenAmount + safeDiv( safeMul(tokenAmount , 5), 100);
        else return  tokenAmount; 
    
    }

    // @notice This function will finalize the sale.
    // It will only execute if predetermined sale time passed or all tokens are sold.
    function finalize() onlyBy(owner) {

        //TODO uncomment this for live
        //uint daysToRefund = 4*60*24*15;
        uint daysToRefund = 10;

        if (block.number < endBlock && SOCXSentToETH < maxCap) revert();

        if (SOCXSentToETH < minCap && block.number < (endBlock + daysToRefund)) revert();

        uint remainingTokens = maxCap - SOCXSentToETH;

        if (SOCXSentToETH > minCap) {
            if (!multisigETH.send(this.balance)) revert();
            if (!socx.transfer(team, remainingTokens)) revert();
            if (!socx.transfer(team, tokensForTeam)) revert();
        }

        crowdsaleClosed = true;
        socx.unlock();
    }

    // TODO do we want this here?
    // @notice Failsafe drain
    function drain() onlyBy(owner) {
        if (!owner.send(this.balance)) revert();
    }

    // Refund backer if minimum is not reached
    function receiveApproval() minCapNotReached public {
        uint value = backers[msg.sender].SOCXSent;

        if (value == 0) revert();

        socx.failedSaleApproval(msg.sender, value);  // approve transfer of tokens by this contract
        if (!socx.transferFrom(msg.sender, address(this), value)) revert(); // get the token back to the crowdsale contract
        uint ETHToSend = backers[msg.sender].weiReceived;
        backers[msg.sender].weiReceived = 0;
        if (ETHToSend > 0) {
            asyncSend(msg.sender, ETHToSend);
        }
    }
}

// The SOCX token
contract SOCX is ERC20, SafeMath, Ownable {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals; // How many decimals to show.
    string public version = 'v0.1';
    uint public initialSupply;
    uint public totalSupply;
    bool public locked;
    address public crowdSaleAddress;
    uint multiplier = 10000000000;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    // Lock transfer during the ICO
    modifier onlyUnlocked() {
        if (msg.sender != crowdSaleAddress && locked) revert();
        _;
    }

    modifier onlyAuthorized() {
        if (msg.sender != owner && msg.sender != crowdSaleAddress) revert();
        _;
    }

    // The SOCX Token constructor
    function SOCX(address _crowdSaleAddress) {
        // Lock the transfCrowdsaleer function during the crowdsale
        locked = true;
        initialSupply = 90000000 * multiplier;
        totalSupply = initialSupply;
        name = 'SocialX'; // Set the name for display purposes
        symbol = 'SOCX'; // Set the symbol for display purposes
        decimals = 10; // Amount of decimals for display purposes
        crowdSaleAddress = _crowdSaleAddress;

        // TODO: make sure the address in here and the presale amounts are accurate
        // Address to hold tokens for pre-sale customers
        balances[0x6C88e6C76C1Eb3b130612D5686BE9c0A0C78925B] = 100000 * multiplier;

        balances[crowdSaleAddress] = totalSupply - 100000 * multiplier;
    }

    function unlock() onlyAuthorized {
        locked = false;
    }

    function burn(uint256 _value) returns(bool) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        totalSupply = safeSub(totalSupply, _value);
        Transfer(msg.sender, 0x0, _value);
        return true;
    }

    function transfer(address _to, uint _value) onlyUnlocked returns(bool) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns(bool success) {
        if (balances[_from] < _value) revert(); // Check if the sender has enough
        if (safeAdd(balances[_to], _value) < balances[_to]) revert(); // Check for overflows
        if (_value > allowed[_from][msg.sender]) revert(); // Check allowance
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

    function failedSaleApproval(address _backer, uint _value) onlyAuthorized returns(bool) {
        allowed[_backer][crowdSaleAddress] = _value;
        Approval(msg.sender, _backer, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns(uint remaining) {
        return allowed[_owner][_spender];
    }
}
