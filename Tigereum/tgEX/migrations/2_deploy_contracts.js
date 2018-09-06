var Tigereum = artifacts.require("./Tigereum.sol");
var TigereumCrowdsale = artifacts.require("./TigereumCrowdsale.sol");

module.exports = function(deployer) {
	deployer.deploy(TigereumCrowdsale, accounts[0], accounts[1], accounts[2], accounts[3], accounts[4], accounts[5], accounts[6], accounts[7], accounts[8]);
};
