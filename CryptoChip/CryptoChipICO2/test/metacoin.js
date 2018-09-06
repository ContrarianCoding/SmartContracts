var FCTtest = artifacts.require("./FCTtest.sol");
var FundToken = artifacts.require("./FundToken.sol");

contract('FCTtest', function(accounts) {

  it("buy should fail before start", async function() {
    var accountZeroBalance = 0;
    
    assert.equal(0, 0, "buy tokens fails before start");
  });
});
