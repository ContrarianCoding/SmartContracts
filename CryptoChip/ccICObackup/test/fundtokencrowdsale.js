var FundTokenCrowdsale = artifacts.require("./FundTokenCrowdsale.sol");
var FundToken = artifacts.require("./FundToken.sol");

contract('FundTokenCrowdsale', function(accounts) {

  it("buy should fail before start", async function() {
    var accountZeroBalance = 0;
    let fct = await FundTokenCrowdsale.deployed();
    let tkadr = await fct.token.call();
    let tk = await FundToken.at(tkadr);
    // let acc1balb4 = await tk.balanceOf.call(accounts[1]);
    // console.log(acc1balb4);
    try {
      await fct.buyTokens(accounts[1], {from:accounts[1], value: 50});
    } catch (e) {
      return true;
    }
    throw new Error("I should never see this!")
    
    // let acc1balafter = await tk.balanceOf.call(accounts[1]);
    // console.log(acc1balafter);
    // assert.equal(0, 0, "buy tokens fails before start");
  });
});
