var ConvertLib = artifacts.require("./ConvertLib.sol");
var MetaCoin = artifacts.require("./MetaCoin.sol");
var FundToken = artifacts.require("./FundToken.sol");
var FundTokenCrowdsale = artifacts.require("./FundTokenCrowdsale.sol");
module.exports = function(deployer) {
  deployer.deploy(ConvertLib);
  deployer.link(ConvertLib, MetaCoin);
  deployer.deploy(MetaCoin);
  deployer.deploy(FundTokenCrowdsale);
};
