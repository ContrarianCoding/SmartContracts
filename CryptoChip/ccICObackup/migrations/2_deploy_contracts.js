
const FundTokenCrowdsale = artifacts.require("./FundTokenCrowdsale.sol")

module.exports = function(deployer, network, accounts) {

	deployer.deploy(FundTokenCrowdsale);
};
