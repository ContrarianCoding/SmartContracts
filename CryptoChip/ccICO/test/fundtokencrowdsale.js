var FundTokenCrowdsale = artifacts.require("./FundTokenCrowdsale.sol");
var FundToken = artifacts.require("./FundToken.sol");

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

contract('FundTokenCrowdsale', function(accounts) {
  /* ------ Suite 1 - main ------ */
  it("buy should fail before start", async function() {
    let fct = await FundTokenCrowdsale.deployed();
    await mineBlock();
    let tkadr = await fct.token.call();
    await mineBlock();
    let tk = await FundToken.at(tkadr);
    await mineBlock();
    try {
      await fct.buyTokens(accounts[8], {from:accounts[8], value: 5000*toDec});
    } catch (e) {
      return true;
    }
    throw new Error("I should never see this!");
  });

  it("should have correct start rate", async function() {
    let fct = await FundTokenCrowdsale.deployed();
    await mineBlock();
    let tkadr = await fct.token.call();
    await mineBlock();
    let tk = await FundToken.at(tkadr);
    await timeTravel(86400 * 3 + 8 * 3600);
    await mineBlock();
    let acc1balb4 = await tk.balanceOf.call(accounts[9]);
    await fct.buyTokens(accounts[9], {from:accounts[9], value: 5000*toDec});
    let acc1balafter = await tk.balanceOf.call(accounts[9]);
    var expected = acc1balb4.c[0] + 5000*1250*toDec;
    assert.equal(acc1balafter.c[0], expected, "first bonus wrong");
  });

  it("should have correct second bonus rate", async function() {
    let fct = await FundTokenCrowdsale.deployed();
    await mineBlock();
    let tkadr = await fct.token.call();
    await mineBlock();
    let tk = await FundToken.at(tkadr);
    await timeTravel(86400/3);
    await mineBlock();
    acc1balb4 = await tk.balanceOf.call(accounts[11]);
    await fct.buyTokens(accounts[11], {from:accounts[11], value: 5000*toDec});

    acc1balafter = await tk.balanceOf.call(accounts[11]);
    expected = acc1balb4.c[0] + 5000*1150*toDec;
    var rate = await fct.rate.call();
    console.log(rate.toString());
    assert.equal(acc1balafter.c[0], expected, "second bonus wrong");
  });

  it("should have correct third bonus rate", async function() {
    let fct = await FundTokenCrowdsale.deployed();
    await mineBlock();
    let tkadr = await fct.token.call();
    await mineBlock();
    let tk = await FundToken.at(tkadr);
    await timeTravel(86400 + 1);
    await mineBlock();
    acc1balb4 = await tk.balanceOf.call(accounts[10]);
    await fct.buyTokens(accounts[10], {from:accounts[10], value: 1500*toDec});
    acc1balafter = await tk.balanceOf.call(accounts[10]);
    expected = acc1balb4.c[0] + 1500*1100*toDec;
    var rate = await fct.rate.call();
    console.log(rate.toString());
    assert.equal(acc1balafter.c[0], expected, "third bonus wrong");
  });

  it("should have correct no bonus rate", async function() {
    let fct = await FundTokenCrowdsale.deployed();
    await mineBlock();
    let tkadr = await fct.token.call();
    await mineBlock();
    let tk = await FundToken.at(tkadr);
    await timeTravel(86400*7 + 1);
    await mineBlock();
    acc1balb4 = await tk.balanceOf.call(accounts[9]); 
    await fct.buyTokens(accounts[9], {from:accounts[9], value: 1350*toDec});
    acc1balafter = await tk.balanceOf.call(accounts[9]);
    expected = acc1balb4.c[0] + 1350*1000*toDec;
    var rate = await fct.rate.call();
    console.log(rate.toString());
    assert.equal(acc1balafter.c[0], expected, "no bonus wrong");
  });

  it("should not allow withdrawing lockup during sale", async function() {
    let fct = await FundTokenCrowdsale.deployed();
    await mineBlock();
    let tkadr = await fct.token.call();
    await mineBlock();
    let tk = await FundToken.at(tkadr);
    await mineBlock();
    try {
      await fct.withdrawLockupTokens({from:accounts[10]});
    } catch (e) {
      return true;
    }
    throw new Error("I should never see this!")
  });

  it("should not allow finalizing early", async function() {
    let fct = await FundTokenCrowdsale.deployed();
    await mineBlock();
    let tkadr = await fct.token.call();
    await mineBlock();
    let tk = await FundToken.at(tkadr);
    await mineBlock();
    try {
      await fct.finalize({from:accounts[10]});
    } catch (e) {
      return true;
    }
    throw new Error("I should never see this!")
  });

  it("should have correct last sale refund", async function() {
    let fct = await FundTokenCrowdsale.deployed();
    await mineBlock();
    let tkadr = await fct.token.call();
    await mineBlock();
    let tk = await FundToken.at(tkadr);
    await mineBlock();
    acc1balb4 = await tk.balanceOf.call(accounts[9]); 
    var amountleft = (56000*1000 - 1350*1000 - 1500*1100 - 5000*1150 - 5000*1250)*toDec
    var buying = amountleft/1000 + 13;
    console.log(buying);
    console.log(amountleft);
    await fct.buyTokens(accounts[9], {from:accounts[9], value: buying});
    acc1balafter = await tk.balanceOf.call(accounts[9]);
    expected = amountleft;
    assert.equal(acc1balafter.c[0] - acc1balb4.c[0], expected, "refund amount wrong");
  });


  it("should have correct premine ", async function() {
    let fct = await FundTokenCrowdsale.deployed();
    await mineBlock();
    let tkadr = await fct.token.call();
    await mineBlock();
    let tk = await FundToken.at(tkadr);
    await fct.finalize({from:accounts[10]});
    await mineBlock();
    let acc1balaft = await tk.balanceOf.call(accounts[1]);
    let acc2balaft = await tk.balanceOf.call(accounts[2]);
    let acc3balaft = await tk.balanceOf.call(accounts[3]);
    let acc7balaft = await tk.balanceOf.call(accounts[7]);
    let acc8balaft = await tk.balanceOf.call(accounts[8]);

    assert.equal(acc1balaft.c[0], 2000000*toDec, "1 finalization sent incorrectly");
    assert.equal(acc2balaft.c[0], 1360000*toDec, "2 finalization sent incorrectly");
    assert.equal(acc3balaft.c[0], 240000*toDec, "3 finalization sent incorrectly");
    assert.equal(acc7balaft.c[0], 4000000*toDec, "4 finalization sent incorrectly");
    assert.equal(acc8balaft.c[0], 3200000*toDec, "5 finalization sent incorrectly");
    
  });

  it("should not allow withdrawing lockup during break", async function() {
    let fct = await FundTokenCrowdsale.deployed();
    await mineBlock();
    let tkadr = await fct.token.call();
    await mineBlock();
    let tk = await FundToken.at(tkadr);
    await mineBlock();
    try {
      await fct.withdrawLockupTokens({from:accounts[10]});
    } catch (e) {
      return true;
    }
    throw new Error("I should never see this!")
  });


  it("should allow withdrawing lockup tokens after period", async function() {
    let fct = await FundTokenCrowdsale.deployed();
    await mineBlock();
    let tkadr = await fct.token.call();
    await mineBlock();
    let tk = await FundToken.at(tkadr);
    await mineBlock();

    await timeTravel(86400*180);
    await mineBlock();

    let acc4balb4 = await tk.balanceOf.call(accounts[4]);
    let acc5balb4 = await tk.balanceOf.call(accounts[5]);
    let acc6balb4 = await tk.balanceOf.call(accounts[6]);

    await fct.withdrawLockupTokens({from:accounts[10]});
    
    let acc4balaft = await tk.balanceOf.call(accounts[4]);
    let acc5balaft = await tk.balanceOf.call(accounts[5]);
    let acc6balaft = await tk.balanceOf.call(accounts[6]);

    assert.equal(acc4balaft.c[0], acc4balb4.c[0] + 3600000*toDec, "1. lockup withdrawn sent incorrectly");
    assert.equal(acc5balaft.c[0], acc5balb4.c[0] + 4000000*toDec, "2. lockup withdrawn incorrectly");
    assert.equal(acc6balaft.c[0], acc6balb4.c[0] + 5600000*toDec, "3. lockup withdrawn incorrectly");
    
  });
  /* ------ Suite 2 - finish on time ------ */
  // it("should airdrop with the correct ratios", async function() {
  //   let fct = await FundTokenCrowdsale.deployed();

  //   let tkadr = await fct.token.call();
  //   let tk = await FundToken.at(tkadr);
  //   var nonAirdropWallet1Works = false;
  //   var nonAirdropWallet2Works = false;
  //   await timeTravel(86400 * 34);//start sale no bonus
  //   await mineBlock();
  //   await fct.buyTokens(accounts[9], {from:accounts[9], value: 6894*toDec});
  //   await fct.buyTokens(accounts[10], {from:accounts[10], value: 1236*toDec});
  //   await fct.buyTokens(accounts[11], {from:accounts[11], value: 2964*toDec});
  //   await fct.buyTokens(accounts[9], {from:accounts[9], value: 3062*toDec});
    
  //   await timeTravel(86400 * 3);//sale time should run out
  //   await mineBlock();
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
  //   await fct.finalize();
  //   let acc81 = await tk.balanceOf.call(accounts[9]);
  //   let acc91 = await tk.balanceOf.call(accounts[10]);
  //   let acc101 = await tk.balanceOf.call(accounts[11]);
  //   let acc11 = await tk.balanceOf.call(accounts[1]);
  //   let acc21 = await tk.balanceOf.call(accounts[2]);
  //   let acc31 = await tk.balanceOf.call(accounts[3]);
  //   let acc8 = acc81.toNumber();
  //   let acc9 = acc91.toNumber();
  //   let acc10 = acc101.toNumber();
  //   let acc1 = acc11.toNumber();
  //   let acc2 = acc21.toNumber();
  //   let acc3 = acc31.toNumber();
  //   acc0balb4 = await tk.balanceOf.call(accounts[0]);
  //   acc1balb4 = await tk.balanceOf.call(accounts[1]);
  //   acc2balb4 = await tk.balanceOf.call(accounts[2]);
  //   acc3balb4 = await tk.balanceOf.call(accounts[3]);
  //   acc4balb4 = await tk.balanceOf.call(accounts[4]);
  //   acc5balb4 = await tk.balanceOf.call(accounts[5]);
  //   acc6balb4 = await tk.balanceOf.call(accounts[6]);
  //   acc7balb4 = await tk.balanceOf.call(accounts[7]);
  //   acc8balb4 = await tk.balanceOf.call(accounts[8]);
  //   acc9balb4 = await tk.balanceOf.call(accounts[9]);
  //   acc10balb4 = await tk.balanceOf.call(accounts[10]);
  //   acc11balb4 = await tk.balanceOf.call(accounts[11]);
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
  //   await fct.getAirdrop(accounts[1]);
  //   await fct.getAirdrop(accounts[2]);
  //   await fct.getAirdrop(accounts[3]);
  //   await fct.getAirdrop(accounts[9]);
  //   await fct.getAirdrop(accounts[10]);
  //   await fct.getAirdrop(accounts[11]);
  //   try {
  //     await fct.getAirdrop(accounts[7]);
  //   } catch (e) {
  //     nonAirdropWallet1Works = true;
  //   }
  //   try {
  //     await fct.getAirdrop(accounts[8]);
  //   } catch (e) {
  //     nonAirdropWallet2Works = true;
  //   }
  //   acc0balb4 = await tk.balanceOf.call(accounts[0]);
  //   acc1balb4 = await tk.balanceOf.call(accounts[1]);
  //   acc2balb4 = await tk.balanceOf.call(accounts[2]);
  //   acc3balb4 = await tk.balanceOf.call(accounts[3]);
  //   acc4balb4 = await tk.balanceOf.call(accounts[4]);
  //   acc5balb4 = await tk.balanceOf.call(accounts[5]);
  //   acc6balb4 = await tk.balanceOf.call(accounts[6]);
  //   acc7balb4 = await tk.balanceOf.call(accounts[7]);
  //   acc8balb4 = await tk.balanceOf.call(accounts[8]);
  //   acc9balb4 = await tk.balanceOf.call(accounts[9]);
  //   acc10balb4 = await tk.balanceOf.call(accounts[10]);
  //   acc11balb4 = await tk.balanceOf.call(accounts[11]);
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

  //   let acc8n1 = await tk.balanceOf.call(accounts[9]);
  //   let acc9n1 = await tk.balanceOf.call(accounts[10]);
  //   let acc10n1 = await tk.balanceOf.call(accounts[11]);
  //   let acc1n1 = await tk.balanceOf.call(accounts[1]);
  //   let acc2n1 = await tk.balanceOf.call(accounts[2]);
  //   let acc3n1 = await tk.balanceOf.call(accounts[3]);

  //   let acc1n = acc1n1.toNumber();
  //   let acc2n = acc2n1.toNumber();
  //   let acc3n = acc3n1.toNumber();
  //   let acc8n = acc8n1.toNumber();
  //   let acc9n = acc9n1.toNumber();
  //   let acc10n = acc10n1.toNumber();
  //   var drop1 = acc1n - acc1;
  //   var drop2 = acc2n - acc2;
  //   var drop3 = acc3n - acc3;
  //   var drop8 = acc1n - acc8;
  //   var drop9 = acc2n - acc9;
  //   var drop10 = acc3n - acc10;

  //   var rat1 = (acc1/drop1)/(acc2/drop2) < 1.1 && (acc1/drop1)/(acc2/drop2) > 0.9;
  //   var rat2 = (acc1/drop1)/(acc3/drop3) < 1.1 && (acc1/drop1)/(acc3/drop3) > 0.9;
  //   var rat3 = (drop1/drop2)/(acc1/acc2) < 1.1 && (drop1/drop2)/(acc1/acc2) > 0.9;
  //   var rat4 = (drop1/drop3)/(acc1/acc3) < 1.1 && (drop1/drop3)/(acc1/acc3) > 0.9;
  //   var rat5 = (drop1/drop8)/(acc1/acc8) < 1.1 && (drop1/drop3)/(acc1/acc3) > 0.9;
  //   var rat6 = (drop1/drop8)/(acc1/acc8) < 1.1 && (drop1/drop3)/(acc1/acc3) > 0.9;
  //   var rat7 = (drop2/drop9)/(acc2/acc9) < 1.1 && (drop1/drop3)/(acc1/acc3) > 0.9;
  //   var rat8 = (drop3/drop10)/(acc3/acc10) < 1.1 && (drop1/drop3)/(acc1/acc3) > 0.9;
  //   console.log("drops");
  //   console.log(drop1);
  //   console.log(drop2);
  //   console.log(drop3);
  //   console.log(drop8);
  //   console.log(drop9);
  //   console.log(drop10);
  //   assert.equal(rat1, true, "ration 1 isnt preserved");
  //   assert.equal(rat2, true, "ration 2 isnt preserved");
  //   assert.equal(rat3, true, "ration 3 isnt preserved");
  //   assert.equal(rat4, true, "ration 4 isnt preserved");
  //   assert.equal(rat5, true, "ration 5 isnt preserved");
  //   assert.equal(rat6, true, "ration 6 isnt preserved");
  //   assert.equal(rat7, true, "ration 7 isnt preserved");
  //   assert.equal(rat8, true, "ration 8 isnt preserved");
  //   assert.equal(nonAirdropWallet1Works, true, "post ICO getting airdrop");
  //   assert.equal(nonAirdropWallet2Works, true, "bounty getting airdrop");
  // });

  // it("should lock during break for minting and withdrawing lockup", async function() {
  //   let fct = await FundTokenCrowdsale.deployed();
  //   let tkadr = await fct.token.call();
  //   let tk = await FundToken.at(tkadr);
  //   var withdrawFailsDuringBreak = false;
  //   var mintFailsDuringBreak = false;
  //   try {
  //     await fct.withdrawLockupTokens({from:accounts[10]});
  //   } catch (e) {
  //     withdrawFailsDuringBreak = true;
  //   }
  //   try {
  //     await tk.mint.call(accounts[10], 10, {from:accounts[10]});
  //   } catch (e) {
  //     mintFailsDuringBreak = true;
  //   }
  //   await timeTravel(86400 * 180);//sale time should run out
  //   await mineBlock();
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
  //   await fct.withdrawLockupTokens({from:accounts[10]});
  //   assert.equal(withdrawFailsDuringBreak, true, "withdraw lockup succeeds during break");
  //   assert.equal(mintFailsDuringBreak, true, "minting succeeds during break");
  // });

  /* ------ Both ------ */
  it("should end up with 80000000*toDec total supply", async function() {
    let fct = await FundTokenCrowdsale.deployed();
    await mineBlock();
    let tkadr = await fct.token.call();
    await mineBlock();
    let tk = await FundToken.at(tkadr);
    await mineBlock();
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
    var tot = acc0balb4.c[0] + acc1balb4.c[0] + acc2balb4.c[0] + acc3balb4.c[0];
    tot = tot + acc4balb4.c[0] + acc5balb4.c[0] + acc6balb4.c[0] + acc11balb4.c[0];
    tot = tot + acc7balb4.c[0] + acc8balb4.c[0] + acc9balb4.c[0] + acc10balb4.c[0];
    console.log(tot);
    assert.equal(tot, 80000000*toDec, "final total supply incorrect");
    
  });
  /* To be run on it's own */
 
});
