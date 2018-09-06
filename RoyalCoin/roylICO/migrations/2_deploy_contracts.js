
const RoyalCoinCrowdsale = artifacts.require("./RoyalCoinCrowdsale.sol")
const RoyalCoin = artifacts.require("./RoyalCoin.sol")
// --- 0 - admin - 0xa9b48e5013Ee279388555bC6edf8cD2075A842d1
// --- 1 - advisor1 - 0x646CE0c5fd9e091888b5B9306a5A572BE0225a76
// --- 2 - advisor2 - 0xaBFD45dd1DF4715eA22f1e1FAA8CEdB5Ffc51C1F
// --- 3 - advisor3 - 0xe5bf5f3b4b873ab610f37c82c4e28b774dc5dfc9
// --- 4 - investor - 0x54C2B0e4D50D6602c7afFf26A2bAe602Eb6e6CBf
// --- 5 - team - 0xa9b48e5013Ee279388555bC6edf8cD2075A842d1
module.exports = function(deployer, network, accounts) {
	var _admin = "0xa9b48e5013Ee279388555bC6edf8cD2075A842d1";
	var _advisor1 = "0x646CE0c5fd9e091888b5B9306a5A572BE0225a76";
	var _advisor2 = "0xaBFD45dd1DF4715eA22f1e1FAA8CEdB5Ffc51C1F";
	var _advisor3 = "0xe5bf5f3b4b873ab610f37c82c4e28b774dc5dfc9";
	var _investor = "0x54C2B0e4D50D6602c7afFf26A2bAe602Eb6e6CBf";
	var _team = "0xa9b48e5013Ee279388555bC6edf8cD2075A842d1";

    //deploy the RoyalCoinCrowdsale using the owner account
  	return deployer.deploy(RoyalCoinCrowdsale,
						  	accounts[0], 
						  	accounts[1], 
						  	accounts[2],
						  	accounts[3],
						  	accounts[4],
						  	accounts[5],
						  	{ from: accounts[6] }).then(function() {
  		//log the address of the RoyalCoinCrowdsale
  		console.log("RoyalCoinCrowdsale address: " + RoyalCoinCrowdsale.address);
  		return RoyalCoinCrowdsale.deployed().then(function(cs) {
  			return cs.token.call().then(function(tk) {
  				//log the address of the RoyalCoin token
  				console.log("RoyalCoin token address: " + tk.address);
  			});
  		});

	});
}