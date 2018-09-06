pragma solidity ^0.4.4;

//import "./std.sol";

contract Lokd {

	struct Deposit {
        uint256 amount;
        address depositor;
        address inheritor;
        uint256 outTime;
        uint256 lastDepositIndex;
    }

    uint256 fee;

	mapping (address => uint256) private lastIndex;

	Deposit[] private depositHistory;

	event Deposited(address indexed _depositor, uint256 _value, uint256 _time);
	event Withdrawn(address indexed _depositor, uint256 _amount);

	function Lokd(uint256 _fee) { // 1000 is 100 percent
		depositHistory.push(
        Deposit({
                amount: 0,
                depositor: msg.sender,
                inheritor: msg.sender,
                outTime: now,
                lastDepositIndex: 0
            })
        );
        fee = _fee;
	}

	function findLastLockedIndex(uint256 index) private returns(uint256) {
		uint256 nextindex = depositHistory[index].lastDepositIndex;
		while(nextindex != 0 && depositHistory[nextindex].outTime > now){
			index = nextindex;
			nextindex = depositHistory[nextindex].lastDepositIndex;
		}
		return index;
	}

	function findLastAvailableIndex(uint256 index) private returns(uint256) {
		while(index != 0 && depositHistory[index].outTime > now){
			index = depositHistory[index].lastDepositIndex;
		}
		return index;
	}

	function withdrawOwner(uint256 _amount) public {
		uint256 index = lastIndex[msg.sender];
		uint256 left = _amount;
		index = findLastAvailableIndex(index);
		if(index == 0) throw;
		while(index != 0 && left != 0){
			if(left < depositHistory[index].amount){
				depositHistory[index].amount -= left;
				left = 0;
			}
			else{
				left -= depositHistory[index].amount;
				depositHistory[index].amount = 0;
				index = depositHistory[index].lastDepositIndex;
			}
		}
		if(index == 0 && left != 0) {
			throw;
		}
		if (!(msg.sender.send(_amount))) throw;
		depositHistory[findLastLockedIndex(lastIndex[msg.sender])].lastDepositIndex = index;
		Withdrawn(msg.sender, _amount);
	}

	function withdrawInheritence(uint256 _amount, address from) public {
		uint256 index = lastIndex[from];
		uint256 left = _amount;
		index = findLastAvailableIndex(index);
		if(index == 0) throw;
		while(index != 0 && left != 0){
			if(depositHistory[index].inheritor == msg.sender){
				if(left < depositHistory[index].amount){
					depositHistory[index].amount -= left;
					left = 0;
				}
				else{
					left -= depositHistory[index].amount;
					depositHistory[index].amount = 0;
				}
			}
			index = depositHistory[index].lastDepositIndex;
		}
		if(index == 0 && left != 0) {
			throw;
		}
		if (!(msg.sender.send(_amount))) throw;
		depositHistory[findLastLockedIndex(lastIndex[msg.sender])].lastDepositIndex = index;
		Withdrawn(msg.sender, _amount);
	}

	function getInheritenceBalance(uint256 index) public returns(uint256) {
		uint256 sum = 0;
		while(index != 0){
			if(depositHistory[index].inheritor == msg.sender) sum = sum + depositHistory[index].amount;
			index = depositHistory[index].lastDepositIndex;
		}
		return sum;
	}

	function getMyInheritenceBalance(address from) public returns(uint256) {
		uint256 index = lastIndex[from];
		return getInheritenceBalance(index);
	}

	function getMyAvailableInheritenceBalance(address from) public returns(uint256) {
		uint256 index = findLastAvailableIndex(lastIndex[from]);
		return getInheritenceBalance(index);
	}

	function getBalance(uint256 index) public returns(uint256) {
		uint256 sum = 0;
		while(index != 0){
			sum = sum + depositHistory[index].amount;
			index = depositHistory[index].lastDepositIndex;
		}
		return sum;
	}

	function getMyBalance() public returns(uint256) {
		uint256 index = lastIndex[msg.sender];
		return getBalance(index);
	}

	function getMyAvailableBalance() public returns(uint256) {
		uint256 index = findLastAvailableIndex(lastIndex[msg.sender]);
		return getBalance(index);
	}

	function withdrawAvailableInheritence(address from) public {
		uint256 sum = 0;
		uint256 index = findLastAvailableIndex(lastIndex[from]);
		while(index != 0){
			if(depositHistory[index].inheritor == msg.sender){
				sum = sum + depositHistory[index].amount;
				depositHistory[index].amount = 0;
			}
			index = depositHistory[index].lastDepositIndex;
		}
		if(sum != 0){
			if (!(msg.sender.send(sum))) throw;
			Withdrawn(msg.sender, sum);
		}
		lastIndex[from] = 0;
	}

	function withdrawAvailable() public {
		uint256 sum = 0;
		uint256 index = findLastAvailableIndex(lastIndex[msg.sender]);
		while(index != 0){
			sum = sum + depositHistory[index].amount;
			depositHistory[index].amount = 0;
			index = depositHistory[index].lastDepositIndex;
		}
		if(sum != 0){
			if (!(msg.sender.send(sum))) throw;
			Withdrawn(msg.sender, sum);
		}
		lastIndex[msg.sender] = 0;
	}

	function depos(address inheritor, uint256 depTimeDays) public payable {
		uint256 depFee = (msg.value / 1000) * fee;
		depositHistory.push(
        Deposit({
                amount: msg.value - depFee,
                depositor: msg.sender,
                inheritor: inheritor,
                outTime: now + depTimeDays * 1 days,
                lastDepositIndex: lastIndex[msg.sender]
            })
        );
        depositHistory[0].amount = depositHistory[0].amount + depFee;
        lastIndex[msg.sender] = depositHistory.length;
        Deposited(msg.sender, msg.value - depFee, depTimeDays);
	}

	function getFees() {
		if(!(msg.sender.send(depositHistory[0].amount))) throw;
		depositHistory[0].amount = 0;
	}

	function() {
      throw;
    }
}
