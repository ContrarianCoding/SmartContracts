pragma solidity 0.4.11;

import '../zeppelin-solidity/contracts/token/MintableToken.sol';
// This is just a simple example of a coin-like contract.
// It is not standards compatible and cannot be expected to talk to other
// coin/token contracts. If you want to create a standards-compliant
// token, see: https://github.com/ConsenSys/Tokens. Cheers!

/// @title Migration Agent interface
contract MigrationAgent {

    function migrateFrom(address _from, uint256 _value) public;
}

contract UnitedfansToken is MintableToken {
	address public migrationMaster;
    address public migrationAgent;
    address public crowdSaleAddress;
    uint256 public totalMigrated;
    string public name = "UnitedFans";
    string public symbol = "UFN";
    uint256 public decimals = 8;
    var locked = true; // Lock the transfer of tokens during the crowdsale

    event Migrate(address indexed _from, address indexed _to, uint256 _value);

    event Locked();

    event Unlocked();

    modifier onlyUnlocked() {
        if (locked) 
            revert();
        _;
    }

    modifier onlyAuthorized() {
        if (msg.sender != owner && msg.sender != crowdSaleAddress) 
            revert();
        _;
    }


    function UnitedfansToken() public {
        // Lock the transfCrowdsaleer function during the crowdsale
        locked = true; // Lock the transfer of tokens during the crowdsale
        crowdSaleAddress = msg.sender;
        migrationMaster = msg.sender;
    }

    function unlock() public onlyOwner {
        locked = false;
        Unlocked();
    }

    function lock() public onlyOwner {
        locked = true;
        Locked();
    }

    function transferFrom(address _from, address _to, uint256 _value) public onlyUnlocked returns (bool) {
	    return super.transferFrom(_from, _to, _value);
	}

	function transfer(address _to, uint256 _value) public onlyUnlocked returns (bool) {
	    return super.transfer(_from, _to);
	}



    // Token migration support:

    /// @notice Migrate tokens to the new token contract.
    /// @dev Required state: Operational Migration
    /// @param _value The amount of token to be migrated
    function migrate(uint256 _value) external {
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
    function setMigrationAgent(address _agent) external onlyUnlocked() {
        // Abort if not in Operational Normal state.
        
        require(migrationAgent == 0);
        require(msg.sender == migrationMaster);
        migrationAgent = _agent;
    }

    function resetCrowdSaleAddress(address _newCrowdSaleAddress) external onlyAuthorized() {
        crowdSaleAddress = _newCrowdSaleAddress;
    }
    
    function setMigrationMaster(address _master) external {       
        require(msg.sender == migrationMaster);
        require(_master != 0);
        migrationMaster = _master;
    }
}
