
const FundTokenCrowdsale = artifacts.require("./FundTokenCrowdsale.sol");
const FundToken = artifacts.require("./FundToken.sol");
module.exports = function(deployer, network, accounts) {

	deployer.deploy(FundTokenCrowdsale, accounts[0], accounts[1], accounts[2], accounts[3], accounts[4], accounts[5], accounts[6], accounts[7], accounts[8], {gas:4709181});
};
