
const FCTtest = artifacts.require("./FCTtest.sol")

module.exports = function(deployer, network, accounts) {
	
    deployer.deploy(FCTtest);
};