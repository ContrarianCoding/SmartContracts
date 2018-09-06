var RoyalCoinCrowdsale = artifacts.require("./RoyalCoinCrowdsale.sol");
var RoyalCoin = artifacts.require("./RoyalCoin.sol");

const timeTravel = function (time) {
  return new Promise((resolve, reject) => {
    web3.currentProvider.sendAsync({
      jsonrpc: "2.0",
      method: "evm_increaseTime",
      params: [time], // 86400 is num seconds in day
      id: new Date().getTime()
    }, (err, result) => {
      if(err){ return reject(err) }
      return resolve(result)
    });
  })
}

const mineBlock = function () {
  return new Promise((resolve, reject) => {
    web3.currentProvider.sendAsync({
      jsonrpc: "2.0",
      method: "evm_mine"
    }, (err, result) => {
      if(err){ return reject(err) }
      return resolve(result)
    });
  })
}

const toDec = 10**3;//toDec on the contract must match for test to work.

contract('RoyalCoinCrowdsale', function(accounts) {

  it("should check start sums", async function() {
    var accountZeroBalance = 0;
    let cs = await RoyalCoinCrowdsale.deployed();
    let tkadr = await cs.token.call();
    let tk = await RoyalCoin.at(tkadr);

    let acc1balaft = await tk.balanceOf.call(accounts[1]);
    let acc2balaft = await tk.balanceOf.call(accounts[2]);
    let acc3balaft = await tk.balanceOf.call(accounts[3]);
    let acc4balaft = await tk.balanceOf.call(accounts[4]);

    assert.equal(acc1balaft.c[0], 1100000*toDec, "1 initial sum sent incorrectly");
    assert.equal(acc2balaft.c[0], 400000*toDec, "2 initial sum sent incorrectly");
    assert.equal(acc3balaft.c[0], 500000*toDec, "3 initial sum sent incorrectly");
    assert.equal(acc4balaft.c[0], 5000000*toDec, "4 initial sum sent incorrectly");
    
  });
  it("should have correct no bonus rate", async function() {
    let cs = await RoyalCoinCrowdsale.deployed();
    let tkadr = await cs.token.call();
    let tk = await RoyalCoin.at(tkadr);
    await timeTravel(12 * 3600);
    await mineBlock();
    acc1balb4 = await tk.balanceOf.call(accounts[6]);
    await cs.buyTokens(accounts[6], {from:accounts[6], value: 13500*toDec});
    acc1balafter = await tk.balanceOf.call(accounts[6]);
    expected = acc1balb4.c[0] + 13500*500*toDec;
    assert.equal(acc1balafter.c[0], expected, "normal rate wrong");
  });

  it("should not allow withdrawing lockup during sale", async function() {
    let cs = await RoyalCoinCrowdsale.deployed();
    let tkadr = await cs.token.call();
    let tk = await RoyalCoin.at(tkadr);
    try {
      await cs.withdrawLockupTokens({from:accounts[0]});
    } catch (e) {
      return true;
    }
    throw new Error("I should never see this!")
  });

  it("should not allow finalizing early", async function() {
    let cs = await RoyalCoinCrowdsale.deployed();
    let tkadr = await cs.token.call();
    let tk = await RoyalCoin.at(tkadr);
    try {
      await cs.finalize({from:accounts[0]});
    } catch (e) {
      return true;
    }
    throw new Error("I should never see this!")
  });

  /* ------ Suite 1 - on time ------ */

  it("should allow finalizing after sale to admin and check sums", async function() {
    var accountZeroBalance = 0;
    let cs = await RoyalCoinCrowdsale.deployed();
    let tkadr = await cs.token.call();
    let tk = await RoyalCoin.at(tkadr);

    await timeTravel(86400 * 68);
    await mineBlock();

    await cs.finalize({from:accounts[0]});
    
  });

  it("should not allow withdrawing lockup during break", async function() {
    let cs = await RoyalCoinCrowdsale.deployed();
    let tkadr = await cs.token.call();
    let tk = await RoyalCoin.at(tkadr);
    try {
      await cs.withdrawLockupTokens({from:accounts[0]});
    } catch (e) {
      return true;
    }
    throw new Error("I should never see this!")
  });

  it("should allow withdrawing lockup tokens after period", async function() {
    let cs = await RoyalCoinCrowdsale.deployed();
    let tkadr = await cs.token.call();
    let tk = await RoyalCoin.at(tkadr);

    await timeTravel(86400 * 180);
    await mineBlock();

    let acc8balb4 = await tk.balanceOf.call(accounts[5]);
    await cs.withdrawLockupTokens({from:accounts[0]});
    
    let acc8balaft = await tk.balanceOf.call(accounts[5]);

    assert.equal(acc8balaft.c[0], acc8balb4.c[0] + 5000000*toDec, "1. lockup withdrawn sent incorrectly");
    
  });

  it("should end up with (total baught + predefined)*toDec total supply", async function() {
    var accountZeroBalance = 0;
    let cs = await RoyalCoinCrowdsale.deployed();
    let tkadr = await cs.token.call();
    let tk = await RoyalCoin.at(tkadr);

    let acc0balb4 = await tk.balanceOf.call(accounts[0]);
    let acc1balb4 = await tk.balanceOf.call(accounts[1]);
    let acc2balb4 = await tk.balanceOf.call(accounts[2]);
    let acc3balb4 = await tk.balanceOf.call(accounts[3]);
    let acc4balb4 = await tk.balanceOf.call(accounts[4]);
    let acc5balb4 = await tk.balanceOf.call(accounts[5]);
    let acc6balb4 = await tk.balanceOf.call(accounts[6]);
    let acc7balb4 = await tk.balanceOf.call(accounts[7]);
    let acc8balb4 = await tk.balanceOf.call(accounts[8]);
    console.log(acc0balb4);
    console.log(acc1balb4);
    console.log(acc2balb4);
    console.log(acc3balb4);
    console.log(acc4balb4);
    console.log(acc5balb4);
    console.log(acc6balb4);
    console.log(acc7balb4);
    console.log(acc8balb4);
    var totalBaught = 13500*500;
    var predefined = 1100000 + 400000 + 500000 + 5000000 + 5000000;
    var expected = (totalBaught + predefined)*toDec;
    var tot = acc0balb4.c[0] + acc1balb4.c[0] + acc2balb4.c[0] + acc3balb4.c[0]
    tot = tot + acc4balb4.c[0] + acc5balb4.c[0] + acc6balb4.c[0];
    tot = tot + acc7balb4.c[0] + acc8balb4.c[0];
    assert.equal(tot, expected, "final total supply incorrect");
    
  });
  /* ------ Suite 2 - finish early ------ */
  //  const adminSumStart = web3.eth.getBalance(accounts[0]);
  //  const ICOadv1SumStart = web3.eth.getBalance(accounts[1]);
  //  const firstSum = 1480;
  //  const secondSum = 714;
  //  const lastTokens = 38000000 - (firstSum*500 + secondSum*500 + 13500*500);
  //  const lastFinal = (lastTokens*toDec)/500;
  //  const overflow = 37;

  //  it("should have no problem making two buys with correct ether ratios", async function() {
  //   let cs = await RoyalCoinCrowdsale.deployed();
  //   let tkadr = await cs.token.call();
  //   let tk = await RoyalCoin.at(tkadr);
  //   let adminSum = web3.eth.getBalance(accounts[0]).c[1];
  //   let ICOadv1Sum = web3.eth.getBalance(accounts[1]).c[1];
  //   let ICOadv2Sum = web3.eth.getBalance(accounts[2]).c[1];
  //   await cs.buyTokens(accounts[8], {from:accounts[8], value: firstSum*toDec});
  //   await mineBlock();
  //   await cs.buyTokens(accounts[7], {from:accounts[7], value: secondSum*toDec});
  //   await mineBlock();
  //   let adminSum2 = web3.eth.getBalance(accounts[0]).c[1];
  //   let ICOadv1Sum2 = web3.eth.getBalance(accounts[1]).c[1];
  //   let ICOadv2Sum2 = web3.eth.getBalance(accounts[2]).c[1];
  //   let adiff = adminSum2 - adminSum;
  //   let idiff = ICOadv1Sum2 - ICOadv1Sum;
  //   let jdiff = ICOadv2Sum2 - ICOadv2Sum;
  //   let ratio1 = adiff/idiff;
  //   let ratio2 = idiff/jdiff;
  //   let sup = await tk.totalSupply.call();
  //   console.log(sup); 
  //   assert.equal(ratio1, 30, "eth payment 1 ratio wrong");
  //   assert.equal(ratio2, 4, "eth payment 2 ratio wrong");
  // });

  // it("should succeed within limit", async function() {
  //   let cs = await RoyalCoinCrowdsale.deployed();
  //   let tkadr = await cs.token.call();
  //   let tk = await RoyalCoin.at(tkadr);
  //   let adminSum = web3.eth.getBalance(accounts[0]).c[1];
  //   let ICOadv1Sum = web3.eth.getBalance(accounts[1]).c[1];
  //   let ICOadv2Sum = web3.eth.getBalance(accounts[2]).c[1];
  //   await cs.buyTokens(accounts[6], {from:accounts[6], value: lastFinal});
  //   await mineBlock();
  //   let adminSum2 = web3.eth.getBalance(accounts[0]).c[1];
  //   let ICOadv1Sum2 = web3.eth.getBalance(accounts[1]).c[1];
  //   let ICOadv2Sum2 = web3.eth.getBalance(accounts[2]).c[1];
  //   let adiff = adminSum2 - adminSum;
  //   let odiff = ICOadv1Sum2 - ICOadv1Sum;
  //   let tdiff = ICOadv2Sum2 - ICOadv2Sum;
  //   console.log("total supply:");
  //   let sup = await tk.totalSupply.call();
  //   console.log(sup);
  //   console.log(lastFinal);
  //   console.log(adiff);
  //   console.log(odiff);
  //   console.log(tdiff);
  //   let diffromexpected1 = lastFinal*960/1000 - adiff;
  //   let diffromexpected2 = lastFinal*32/1000 - odiff;
  //   let diffromexpected3 = lastFinal*8/1000 - tdiff;
  //   console.log(diffromexpected1);
  //   console.log(diffromexpected2);
  //   console.log(diffromexpected3);
  //   if(adiff > lastFinal*960/1000) diffromexpected1 = 0 - diffromexpected1;
  //   if(odiff > lastFinal*32/1000) diffromexpected2 = 0 - diffromexpected2;
  //   if(tdiff > lastFinal*8/1000) diffromexpected3 = 0 - diffromexpected3;
  //   console.log(diffromexpected1);
  //   console.log(diffromexpected2);
  //   console.log(diffromexpected3);
  //   let result1 = diffromexpected1 <= 1;
  //   let result2 = diffromexpected2 <= 1;
  //   let result3 = diffromexpected3 <= 1;
  //   assert.equal(result1, true, "pass limit gave wrong amount 1");
  //   assert.equal(result2, true, "pass limit gave wrong amount 2");
  //   assert.equal(result3, true, "pass limit gave wrong amount 3");
  // });

  // it("should fail after limit", async function() {
  //   let cs = await RoyalCoinCrowdsale.deployed();
  //   let tkadr = await cs.token.call();
  //   let tk = await RoyalCoin.at(tkadr);
  //   var buyFailsAfterSale = false;
  //   var amount = 1;
  //   let acc1balb4 = await tk.balanceOf.call(accounts[7]);
  //   let supb4 = await tk.totalSupply.call();
  //   await mineBlock();
  //   try {
  //     await cs.buyTokens(accounts[7], {from:accounts[7], value: amount});
  //   } catch (e) {
  //     buyFailsAfterSale = true;
  //     console.log("buy fails after limit");
  //   }
  //   await mineBlock();
  //   let acc1balafter = await tk.balanceOf.call(accounts[7]);
  //   console.log("total supply:");
  //   let sup = await tk.totalSupply.call();
  //   console.log(sup);
  //   assert.equal(buyFailsAfterSale, true, "buy fails after sale");
  // });

  // it("should finalize after limit", async function() {
  //   let cs = await RoyalCoinCrowdsale.deployed();
  //   let tkadr = await cs.token.call();
  //   let tk = await RoyalCoin.at(tkadr);
  //   await mineBlock();
  //   var finalizesCorrectly = await cs.state.call();
  //   assert.equal(finalizesCorrectly, 3, "buy fails after sale");
  // });

  // it("should lock during break for minting and withdrawing lockup", async function() {
  //   let cs = await RoyalCoinCrowdsale.deployed();
  //   let tkadr = await cs.token.call();
  //   let tk = await RoyalCoin.at(tkadr);
  //   var withdrawFailsDuringBreak = false;
  //   var mintFailsDuringBreak = false;
    
  //   try {
  //     await cs.withdrawLockupTokens({from:accounts[0]});
  //   } catch (e) {
  //     withdrawFailsDuringBreak = true;
  //   }
  //   try {
  //     await tk.mint.call(accounts[0], 10, {from:accounts[0]});
  //   } catch (e) {
  //     mintFailsDuringBreak = true;
  //   }
  //   await timeTravel(86400 * 180);//lock time should run out
  //   await mineBlock();
    
  //   try {
  //     await cs.withdrawLockupTokens({from:accounts[0]});
  //   } catch (e) {
  //     console.log("withdrawing failed on time");
  //   }
  //   assert.equal(withdrawFailsDuringBreak, true, "withdraw lockup succeeds during break");
  //   assert.equal(mintFailsDuringBreak, true, "minting succeeds during break");
  // });

  // it("should end up with 50000000*toDec total supply", async function() {
  //   var accountZeroBalance = 0;
  //   let cs = await RoyalCoinCrowdsale.deployed();
  //   let tkadr = await cs.token.call();
  //   let tk = await RoyalCoin.at(tkadr);
  //   let acc0balb4 = await tk.balanceOf.call(accounts[0]);
  //   let acc1balb4 = await tk.balanceOf.call(accounts[1]);
  //   let acc2balb4 = await tk.balanceOf.call(accounts[2]);
  //   let acc3balb4 = await tk.balanceOf.call(accounts[3]);
  //   let acc4balb4 = await tk.balanceOf.call(accounts[4]);
  //   let acc5balb4 = await tk.balanceOf.call(accounts[5]);
  //   let acc6balb4 = await tk.balanceOf.call(accounts[6]);
  //   let acc7balb4 = await tk.balanceOf.call(accounts[7]);
  //   let acc8balb4 = await tk.balanceOf.call(accounts[8]);
  //   console.log(acc0balb4);
  //   console.log(acc1balb4);
  //   console.log(acc2balb4);
  //   console.log(acc3balb4);
  //   console.log(acc4balb4);
  //   console.log(acc5balb4);
  //   console.log(acc6balb4);
  //   console.log(acc7balb4);
  //   console.log(acc8balb4);
  //   var tot = acc0balb4.c[0] + acc1balb4.c[0] + acc2balb4.c[0] + acc3balb4.c[0]
  //   tot = tot + acc4balb4.c[0] + acc5balb4.c[0] + acc6balb4.c[0];
  //   tot = tot + acc7balb4.c[0] + acc8balb4.c[0];
  //   console.log(tot);
  //   assert.equal(tot, 50000000*toDec, "final total supply incorrect");
  // });
});
