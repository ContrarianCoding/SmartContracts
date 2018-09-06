var TigereumCrowdsale = artifacts.require("./TigereumCrowdsale.sol");
var Tigereum = artifacts.require("./Tigereum.sol");

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

const toDec = 10**2;//toDec on the contract must match for test to work.

contract('TigereumCrowdsale', function(accounts) {
  
  it("buy should fail before start", async function() {
    let cs = await TigereumCrowdsale.deployed();
    let tkadr = await cs.token.call();
    let tk = await Tigereum.at(tkadr);
    try {
      await cs.buyTokens(accounts[2], {from:accounts[2], value: 500000*toDec});
    } catch (e) {
      return true;
    }
    throw new Error("I should never see this!")
  });

  it("should have correct start rate", async function() {
    let cs = await TigereumCrowdsale.deployed();
    let tkadr = await cs.token.call();
    let tk = await Tigereum.at(tkadr);
    let state = await cs.state.call();
    await timeTravel(86400 * 2);
    await mineBlock();
    let acc1balb4 = await tk.balanceOf.call(accounts[11]);
    await cs.buyTokens(accounts[11], {from:accounts[11], value: 8500*toDec});
    let acc1balafter = await tk.balanceOf.call(accounts[11]);
    var expected = acc1balb4.c[0] + 8500*1333*toDec;
    assert.equal(acc1balafter.c[0], expected, "bonus wrong");
  });

  it("should have correct no bonus rate", async function() {
    let cs = await TigereumCrowdsale.deployed();
    let tkadr = await cs.token.call();
    let tk = await Tigereum.at(tkadr);
    await timeTravel(12 * 3600);
    await mineBlock();
    acc1balb4 = await tk.balanceOf.call(accounts[10]);
    await cs.buyTokens(accounts[10], {from:accounts[10], value: 13500*toDec});
    acc1balafter = await tk.balanceOf.call(accounts[10]);
    expected = acc1balb4.c[0] + 13500*1000*toDec;
    assert.equal(acc1balafter.c[0], expected, "normal rate wrong");
  });

  it("should not allow withdrawing lockup during sale", async function() {
    let cs = await TigereumCrowdsale.deployed();
    let tkadr = await cs.token.call();
    let tk = await Tigereum.at(tkadr);
    try {
      await cs.withdrawLockupTokens({from:accounts[0]});
    } catch (e) {
      return true;
    }
    throw new Error("I should never see this!")
  });

  it("should not allow finalizing early", async function() {
    let cs = await TigereumCrowdsale.deployed();
    let tkadr = await cs.token.call();
    let tk = await Tigereum.at(tkadr);
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
    let cs = await TigereumCrowdsale.deployed();
    let tkadr = await cs.token.call();
    let tk = await Tigereum.at(tkadr);

    await timeTravel(86400 * 10 + 12 * 3600);
    await mineBlock();

    let acc1balb4 = await tk.balanceOf.call(accounts[1]);
    let acc2balb4 = await tk.balanceOf.call(accounts[2]);
    let acc3balb4 = await tk.balanceOf.call(accounts[3]);
    let acc4balb4 = await tk.balanceOf.call(accounts[4]);
    let acc5balb4 = await tk.balanceOf.call(accounts[5]);
    let acc6balb4 = await tk.balanceOf.call(accounts[6]);
    let acc7balb4 = await tk.balanceOf.call(accounts[7]);

    await cs.finalize({from:accounts[0]});
    
    let acc1balaft = await tk.balanceOf.call(accounts[1]);
    let acc2balaft = await tk.balanceOf.call(accounts[2]);
    let acc3balaft = await tk.balanceOf.call(accounts[3]);
    let acc4balaft = await tk.balanceOf.call(accounts[4]);
    let acc5balaft = await tk.balanceOf.call(accounts[5]);
    let acc6balaft = await tk.balanceOf.call(accounts[6]);
    let acc7balaft = await tk.balanceOf.call(accounts[7]);

    assert.equal(acc1balaft.c[0], acc1balb4.c[0] + 400000*toDec, "1 finalization sent incorrectly");
    assert.equal(acc2balaft.c[0], acc2balb4.c[0] + 3200000*toDec, "2 finalization sent incorrectly");
    assert.equal(acc3balaft.c[0], acc3balb4.c[0] + 1000000*toDec, "3 finalization sent incorrectly");
    assert.equal(acc4balaft.c[0], acc4balb4.c[0] + 2500000*toDec, "4 finalization sent incorrectly");
    assert.equal(acc5balaft.c[0], acc5balb4.c[0] + 100000*toDec, "5 finalization sent incorrectly");
    assert.equal(acc6balaft.c[0], acc6balb4.c[0] + 1820000*toDec, "6 finalization sent incorrectly");
    assert.equal(acc7balaft.c[0], acc7balb4.c[0] + 1000000*toDec, "7 finalization sent incorrectly");
  });

  it("should not allow withdrawing lockup during break", async function() {
    let cs = await TigereumCrowdsale.deployed();
    let tkadr = await cs.token.call();
    let tk = await Tigereum.at(tkadr);
    try {
      await cs.withdrawLockupTokens({from:accounts[0]});
    } catch (e) {
      return true;
    }
    throw new Error("I should never see this!")
  });

  it("should allow withdrawing lockup tokens after period", async function() {
    let cs = await TigereumCrowdsale.deployed();
    let tkadr = await cs.token.call();
    let tk = await Tigereum.at(tkadr);

    await timeTravel(86400 * 90);
    await mineBlock();

    let acc8balb4 = await tk.balanceOf.call(accounts[8]);
    await cs.withdrawLockupTokens({from:accounts[0]});
    
    let acc8balaft = await tk.balanceOf.call(accounts[8]);

    assert.equal(acc8balaft.c[0], acc8balb4.c[0] + 7180000*toDec, "1. lockup withdrawn sent incorrectly");
    
  });

  it("should end up with (total baught + predefined)*toDec total supply", async function() {
    var accountZeroBalance = 0;
    let cs = await TigereumCrowdsale.deployed();
    let tkadr = await cs.token.call();
    let tk = await Tigereum.at(tkadr);

    let acc0balb4 = await tk.balanceOf.call(accounts[0]);
    let acc1balb4 = await tk.balanceOf.call(accounts[1]);
    let acc2balb4 = await tk.balanceOf.call(accounts[2]);
    let acc3balb4 = await tk.balanceOf.call(accounts[3]);
    let acc4balb4 = await tk.balanceOf.call(accounts[4]);
    let acc5balb4 = await tk.balanceOf.call(accounts[5]);
    let acc6balb4 = await tk.balanceOf.call(accounts[6]);
    let acc7balb4 = await tk.balanceOf.call(accounts[7]);
    let acc8balb4 = await tk.balanceOf.call(accounts[8]);
    let acc9balb4 = await tk.balanceOf.call(accounts[9]);
    let acc10balb4 = await tk.balanceOf.call(accounts[10]);
    let acc11balb4 = await tk.balanceOf.call(accounts[11]);
    console.log(acc0balb4);
    console.log(acc1balb4);
    console.log(acc2balb4);
    console.log(acc3balb4);
    console.log(acc4balb4);
    console.log(acc5balb4);
    console.log(acc6balb4);
    console.log(acc7balb4);
    console.log(acc8balb4);
    console.log(acc9balb4);
    console.log(acc10balb4);
    console.log(acc11balb4);
    var totalBaught = 8500*1333 + 13500*1000;
    var predefined = 400000 + 3200000 + 1000000 + 2500000 + 100000 + 1820000 + 1000000 + 7180000;
    var expected = (totalBaught + predefined)*toDec;
    var tot = acc0balb4.c[0] + acc1balb4.c[0] + acc2balb4.c[0] + acc3balb4.c[0]
    tot = tot + acc4balb4.c[0] + acc5balb4.c[0] + acc6balb4.c[0];
    tot = tot + acc7balb4.c[0] + acc8balb4.c[0] + acc9balb4.c[0]
    tot = tot + acc10balb4.c[0] + acc11balb4.c[0];
    assert.equal(tot, expected, "final total supply incorrect");
    
  });
  /* ------ Suite 2 - finish early ------ */
  //  const adminSumStart = web3.eth.getBalance(accounts[0]);
  //  const ICOadv1SumStart = web3.eth.getBalance(accounts[1]);
  //  const firstSum = 1380;
  //  const secondSum = 944;
  //  const lastTokens = 32800000 - (firstSum*1000 + secondSum*1000 + 8500*1333 + 13500*1000);
  //  const lastFinal = (lastTokens*toDec)/1000;
  //  const overflow = 33;

  //  it("should have no problem making two buys with correct ether ratios", async function() {
  //   let cs = await TigereumCrowdsale.deployed();
  //   let tkadr = await cs.token.call();
  //   let tk = await Tigereum.at(tkadr);
  //   let adminSum = web3.eth.getBalance(accounts[0]).c[1];
  //   let ICOadv1Sum = web3.eth.getBalance(accounts[1]).c[1];
  //   await cs.buyTokens(accounts[11], {from:accounts[11], value: firstSum*toDec});
  //   await mineBlock();
  //   await cs.buyTokens(accounts[10], {from:accounts[10], value: secondSum*toDec});
  //   await mineBlock();
  //   let adminSum2 = web3.eth.getBalance(accounts[0]).c[1];
  //   let ICOadv1Sum2 = web3.eth.getBalance(accounts[1]).c[1];
  //   let adiff = adminSum2 - adminSum;
  //   let idiff = ICOadv1Sum2 - ICOadv1Sum;
  //   let ratio = adiff/idiff;
  //   let sup = await tk.totalSupply.call();
  //   console.log(sup); 
  //   assert.equal(ratio, 99, "eth payment ratio wrong");
  // });

  // it("should succeed within limit", async function() {
  //   let cs = await TigereumCrowdsale.deployed();
  //   let tkadr = await cs.token.call();
  //   let tk = await Tigereum.at(tkadr);
  //   let ICOadv1Sum = web3.eth.getBalance(accounts[1]).c[1];
  //   await cs.buyTokens(accounts[8], {from:accounts[8], value: lastFinal});
  //   await mineBlock();
  //   let ICOadv1Sum2 = web3.eth.getBalance(accounts[1]).c[1];
  //   let idiff = ICOadv1Sum2 - ICOadv1Sum;
  //   console.log("total supply:");
  //   let sup = await tk.totalSupply.call();
  //   console.log(sup);
  //   let diffromexpected = lastFinal/100 - idiff;
  //   if(idiff > lastFinal/100) diffromexpected = 0 - diffromexpected;
  //   let result = diffromexpected <= 1;

  //   assert.equal(result, true, "pass limit gave wrong amount");
  // });

  // it("should fail after limit", async function() {
  //   let cs = await TigereumCrowdsale.deployed();
  //   let tkadr = await cs.token.call();
  //   let tk = await Tigereum.at(tkadr);
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
  //   let cs = await TigereumCrowdsale.deployed();
  //   let tkadr = await cs.token.call();
  //   let tk = await Tigereum.at(tkadr);
  //   await mineBlock();
  //   var finalizesCorrectly = await cs.isFinalized.call();
  //   assert.equal(finalizesCorrectly, true, "buy fails after sale");
  // });

  // it("should lock during break for minting and withdrawing lockup", async function() {
  //   let cs = await TigereumCrowdsale.deployed();
  //   let tkadr = await cs.token.call();
  //   let tk = await Tigereum.at(tkadr);
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
  //   await timeTravel(86400 * 90);//lock time should run out
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
  //   let cs = await TigereumCrowdsale.deployed();
  //   let tkadr = await cs.token.call();
  //   let tk = await Tigereum.at(tkadr);
  //   let acc0balb4 = await tk.balanceOf.call(accounts[0]);
  //   let acc1balb4 = await tk.balanceOf.call(accounts[1]);
  //   let acc2balb4 = await tk.balanceOf.call(accounts[2]);
  //   let acc3balb4 = await tk.balanceOf.call(accounts[3]);
  //   let acc4balb4 = await tk.balanceOf.call(accounts[4]);
  //   let acc5balb4 = await tk.balanceOf.call(accounts[5]);
  //   let acc6balb4 = await tk.balanceOf.call(accounts[6]);
  //   let acc7balb4 = await tk.balanceOf.call(accounts[7]);
  //   let acc8balb4 = await tk.balanceOf.call(accounts[8]);
  //   let acc9balb4 = await tk.balanceOf.call(accounts[9]);
  //   let acc10balb4 = await tk.balanceOf.call(accounts[10]);
  //   let acc11balb4 = await tk.balanceOf.call(accounts[11]);
  //   console.log(acc0balb4);
  //   console.log(acc1balb4);
  //   console.log(acc2balb4);
  //   console.log(acc3balb4);
  //   console.log(acc4balb4);
  //   console.log(acc5balb4);
  //   console.log(acc6balb4);
  //   console.log(acc7balb4);
  //   console.log(acc8balb4);
  //   console.log(acc9balb4);
  //   console.log(acc10balb4);
  //   console.log(acc11balb4);
  //   var tot = acc0balb4.c[0] + acc1balb4.c[0] + acc2balb4.c[0] + acc3balb4.c[0]
  //   tot = tot + acc4balb4.c[0] + acc5balb4.c[0] + acc6balb4.c[0];
  //   tot = tot + acc7balb4.c[0] + acc8balb4.c[0] + acc9balb4.c[0]
  //   tot = tot + acc10balb4.c[0] + acc11balb4.c[0];
  //   console.log(tot);
  //   assert.equal(tot, 50000000*toDec, "final total supply incorrect");
  // });
});
