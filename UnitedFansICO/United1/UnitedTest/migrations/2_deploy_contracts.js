
const MoonliteTokenCrowdsale = artifacts.require("./MoonliteTokenCrowdsale.sol")
const MoonliteToken = artifacts.require("./MoonliteToken.sol")

module.exports = function(deployer, network, accounts) {
	var _admin = "0x1dc521277b6954C4D5c7fea4D2292BfA87Db58D7";
	var _PresaleInvestors = "0x11582B40E2A8AB5ac53BC88BDDB925D0909cC332";
	var _Advisers = "0x52f029cdF6C5a64544B454010028aB6c6AF61F14";
	var _Bounty = "0xE1A98368aB2C7761A27ca5a5a422252345fE3f96";
	var _PublicExchangeLiquidity = "0x11EbC3d8C11fe6398509F01EcC78491dEE1E8B63";
	var _Team = "0x4C6131f01c0e34b8D74d66a62AD4B6ab85e2E7c9";
	var _Adviser1 = "0x0662a2F97833B9b120ED40D4E60CeEC39C71ef18";
	var _Adviser2 = "0xDea8e0a4eFa3EBCF9b5e848b8C62CA84b9102F7a";
	var _Adviser3 = "0xa364826CB4D55e520c39A707879F16fdAf79c30B";
	var _Adviser4 = "0xe05416EAD6d997C8bC88A7AE55eC695c06693C58";

    //deploy the MoonliteTokenCrowdsale using the owner account
	return deployer.deploy(MoonliteTokenCrowdsale,
					  	accounts[0], 
					  	accounts[1], 
					  	accounts[2],
					  	accounts[3],
					  	accounts[4],
					  	accounts[5],
					  	accounts[6],
					  	accounts[7],
					  	accounts[8],
					  	accounts[9],
					  	{ from: accounts[1] }).then(function() {
		//log the address of the MoonliteTokenCrowdsale
  		console.log("MoonliteTokenCrowdsale address: " + MoonliteTokenCrowdsale.address);
      return MoonliteTokenCrowdsale.deployed().then(function(cs) {
  			return cs.token.call().then(function(tk) {
          console.log("Moonlite token address: " + tk.address);
  			});
  		});
    });
};