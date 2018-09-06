
const TigereumCrowdsale = artifacts.require("./TigereumCrowdsale.sol")
const Tigereum = artifacts.require("./Tigereum.sol")

module.exports = function(deployer) {
	var _admin = "0x021e366d41cd25209a9f1197f238f10854a0c662";
	var _ICOadvisor1 = "0xBD1b96D30E1a202a601Fa8823Fc83Da94D71E3cc";
	var _hundredKInvestor = "0x93da612b3DA1eF05c5D80c9B906bf9e7aAdc4a23";
	var _additionalPresaleInvestors = "0x095e80F85f3D260bF959Aa524F2f3918f56a2493";
	var _preSaleBotReserve = "0x095e80F85f3D260bF959Aa524F2f3918f56a2493";
	var _ICOadvisor2 = "0xe05416EAD6d997C8bC88A7AE55eC695c06693C58";
	var _team = "0xA919B56D099C12cC8921DF605Df2D696b30526B0";
	var _bounty = "0x20065A723d43c753AD83689C5f9F4786a73Be6e6";
	var _founders = "0x49ddcD8b4B1F54f3E5c4fEf705025C1DaDC753f6";

    //deploy the TigereumCrowdsale using the owner account
  	return deployer.deploy(TigereumCrowdsale,
						  	_admin, 
						  	_ICOadvisor1, 
						  	_hundredKInvestor,
						  	_additionalPresaleInvestors,
						  	_preSaleBotReserve,
						  	_ICOadvisor2,
						  	_team,
						  	_bounty,
						  	_founders,
						  	{ from: _admin }).then(function() {
  		//log the address of the TigereumCrowdsale
  		console.log("TigereumCrowdsale address: " + TigereumCrowdsale.address);
  		return TigereumCrowdsale.deployed().then(function(cs) {
  			return cs.token.call().then(function(tk) {
  				//log the address of the Tigereum token
  				console.log("Tigereum token address: " + tk.address);
  			});
  		});

};