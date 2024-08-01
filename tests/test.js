require('dotenv').config();
const Web3 = require('web3');
const BN = Web3.utils.BN;
const chaiBN = require('chai-bignumber')(BN);
const chai = require('chai');
const chaiEvents = require('chai-events');
const {assert} = chai;

chai
    .use(require('chai-as-promised'))
	.use(chaiBN)
	.use(chaiEvents)
    .should()

const Token = artifacts.require("Token");
const Stable = artifacts.require("StableCoin");
const NFT = artifacts.require("MyNFT");
const Plans = artifacts.require("Plans");
const Subs = artifacts.require("Subscriptions");
const SubsLogic = artifacts.require("SubscriptionLogic");
const MultiPay = artifacts.require("MultiPay");

contract("Kanoe", function ([owner, paymentHolder, user, successor1, successor2, successor3, serverAdmin]) {

	let token, token2, token3, stable, nft, nft2, plans, subs, subsLogic, multiPay
	let debug = process.env.DEBUG_TESTS
	console.log(debug)
	let decimals = 18
	let stableDecimals = 6
	let mintAmount = "1000000000"

	it("Deploy contract", async function () {
		token = await Token.new('Doge', 'Doge', mintAmount, {from: owner});
		token2 = await Token.new('Wave', 'Wave', mintAmount, {from: owner});
		token3 = await Token.new('Door', 'Door', mintAmount, {from: owner});
		stable = await Stable.new('USDT', 'USDT', mintAmount, {from: owner});
		nft = await NFT.new('NFT1', 'NFT1', 'https://', {from: owner});
		nft2 = await NFT.new('NFT2', 'NFT2', 'https://', {from: owner});
		plans = await Plans.new({from: owner});
		subs = await Subs.new({from: owner});
		subsLogic = await SubsLogic.new(plans.address, subs.address, paymentHolder, serverAdmin);
		await subs.changeAllowed(subsLogic.address, true, {from: owner});
		multiPay = await MultiPay.new(serverAdmin, paymentHolder, {from: owner});
		debug && console.log('Token address: ', token.address);
		debug && console.log('StableCoin address: ', stable.address);
	});

	it("Add plan", async function () {
		let limits = {
			successorsMaxCount: 2,
			inheritancesMaxCount: 3,
			tokensMaxCount: 10,
			stableMaxSum: 1000,
			maxWalletsCount: 1
		}
		let title = 'basic'
		let price = 10
		let payAddress = stable.address
		await plans.addPlan(title, payAddress, price, limits, {from: owner});

		limits = {
			successorsMaxCount: 5,
			inheritancesMaxCount: 5,
			tokensMaxCount: 20,
			stableMaxSum: 8000,
			maxWalletsCount: 3
		}
		title = 'middle'
		price = 20
		payAddress = stable.address
		await plans.addPlan(title, payAddress, price, limits);
		let plansList = await plans.getPlansList(0, 1);

		debug && console.log('Plans: ', plansList);
	});

	it("User buy subscription", async function () {
		// give some money to user
		await stable.transfer(user, 500, {from: owner})
		let userBalance = await stable.balanceOf(user);
		assert(userBalance.toString() == '500', 'Tokens not transfered to user')

		// get plan info
		let plan1 = await subsLogic.getPlanById(1);
		// debug && console.log('plan1: ', plan1);

		// buy subscription
		let approveRes = await stable.approve(subsLogic.address, plan1.paytokenPrice, {from: user})
		let buyRes = await subsLogic.pay(1, 1, {from: user})
		let usersSubscription = await subsLogic.getUserSubscription(user)

		debug && console.log('User subs: ', usersSubscription);
		assert(usersSubscription.planId == '1', 'User has no subscription')
	});

	it("Change subscription", async function () {
		// get plan info
		let plan2 = await subsLogic.getPlanById(2);
		debug && console.log('plan2: ', plan2);

		// buy subscription
		let approveRes = await stable.approve(subsLogic.address, plan2.paytokenPrice * 4, {from: user})
		let subsCurrent = await subs.getUserSubscription(user);
		debug && console.log('User subsCurrent: ', subsCurrent);
		let buyRes = await subsLogic.pay(2, 1, {from: user})
		let usersSubscription = await subsLogic.getUserSubscription(user)


		debug && console.log('User subs2: ', usersSubscription);
		assert(usersSubscription.planId == '2', 'User not changed subscription')
	});

	it("Change subscription", async function () {
		let sub = await subsLogic.getUserSubscription(user)
		let expiredOld = sub.endTime
		await subsLogic.payExtend(user, {from: serverAdmin})
		sub = await subsLogic.getUserSubscription(user)
		let expiredNew = sub.endTime
		debug && console.log('expired', expiredOld, expiredNew)
		assert(expiredNew > expiredOld, 'Subscription auto-update invalid')
	});

	it("Get updates", async function () {
		// get updates for payed subscriptions
		let newSubs = await subsLogic.getUpdates(1);
		debug && console.log('payed subs: ', newSubs);
	});

	it("Reserve gas", async function () {
		// 1st payment
		let balanceBefore = await web3.eth.getBalance(paymentHolder)
		let amount = web3.utils.toWei("0.5", "ether");

		await multiPay.reserveGas(1, {from: owner, value: amount})
		let balanceAfter = await web3.eth.getBalance(paymentHolder)

		let dif = balanceAfter - balanceBefore

		assert(dif == amount, 'Balance income not equal to amount')
		debug && console.log('Holder balance', balanceAfter.toString());

		// 2nd payment
		amount = web3.utils.toWei("0.2", "ether");
		await multiPay.reserveGas(2, {from: owner, value: amount})

		let maxId = await multiPay.getMaxPaymentId();
		debug && console.log('Max pay id:', maxId.toString());

		let newPayments = await multiPay.getUpdates(0);
		debug && console.log('New payments:', newPayments);
	});

	it("Check approves", async function () {
		// send tokens to users
		await token.transfer(user, 100, {from: owner});
		await token2.transfer(user, 100, {from: owner});
		await token3.transfer(user, 100, {from: owner});

		// set approves to multiPay
		await token.approve(multiPay.address, 1000, {from: user});
		await token2.approve(multiPay.address, 80, {from: user});

		// get info
		let info = await multiPay.checkInfo(
			user,
			[
				token.address,
				token2.address,
				token3.address
			]
		)
		// get balances
		let balanceToken1 = await token.balanceOf(user);
		let balanceToken2 = await token2.balanceOf(user);
		let balanceToken3 = await token3.balanceOf(user);

		debug && console.log('approves:', info);
		assert(info[0].state == '2', "Full approve asserted")
		assert(info[1].state == '1', "Partial approve asserted")
		assert(info[2].state == '0', "None approve asserted")


		assert(info[0].balance == balanceToken1, "Info.balance token1 incorrect")
		assert(info[1].balance == balanceToken2, "Info.balance token2 incorrect")
		assert(info[2].balance == balanceToken3, "Info.balance token3 incorrect")
	});

	it("Send inheritances", async function () {
		// send tokens to users
		let perc1 = 40
		let perc2 = 35
		let perc3 = 25
		await multiPay.sendInheritance(
			user,
			0,
			[token.address, token2.address],
			[successor1, successor2, successor3],
			[perc1, perc2, perc3],
			{from: serverAdmin}
		);

		let token1balanceS1 = await token.balanceOf(successor1);
		let token1balanceS2 = await token.balanceOf(successor2);
		let token1balanceS3 = await token.balanceOf(successor3);
		debug && console.log(token1balanceS1.toString(), token1balanceS2.toString(), token1balanceS3.toString())

		let token2balanceS1 = await token2.balanceOf(successor1);
		let token2balanceS2 = await token2.balanceOf(successor2);

		let token3balanceS1 = await token3.balanceOf(successor1);
		let token3balanceS2 = await token3.balanceOf(successor2);

		assert(token1balanceS1.toString() === (100 * (perc1/100)).toString(), `token1 asserted ${perc1}% for successor1, got ${token1balanceS1} token1`)
		assert(token1balanceS2.toString() === (100 * (perc2/100)).toString(), `token1 asserted ${perc2}% for successor2, got ${token1balanceS2} token1`)
		assert(token1balanceS3.toString() === (100 * (perc3/100)).toString(), `token1 asserted ${perc3}% for successor2, got ${token1balanceS3} token1`)

		assert(token2balanceS1 == 80 * (perc1/100), `token2 asserted ${perc1}% for successor1, got ${token2balanceS1} token2`)
		assert(token2balanceS2 == 80 * (perc2/100), `token2 asserted ${perc2}% for successor2, got ${token2balanceS2} token2`)

		assert(token3balanceS1 == 0 * (perc1/100), `token3 asserted ${perc1}% for successor1, got ${token3balanceS1} token3`)
		assert(token3balanceS2 == 0 * (perc2/100), `token3 asserted ${perc2}% for successor2, got ${token3balanceS2} token3`)
	});

	it("Send inheritances with limit", async function () {
		// give some tokens to user to make 100 and 100
		await token.transfer(user, 10000, {from: owner});
		await token2.transfer(user, 9980, {from: owner});

		// set approves of full balance to multiPay
		await token.approve(multiPay.address, 10000, {from: user});
		await token2.approve(multiPay.address, 10000, {from: user});

		// send with limits
		let perc1 = 40
		let perc2 = 35
		let perc3 = 25
		await multiPay.sendInheritance(
			user,
			12500,
			[token.address, token2.address],
			[successor1, successor2, successor3],
			[perc1, perc2, perc3],
			{from: serverAdmin}
		);

		// shoud be token.balance=0 token2.balance=50 (because of limit of 150)
		let tokenBalance = await token.balanceOf(user);
		let token2Balance = await token2.balanceOf(user);
		assert(tokenBalance.toString() === '0', 'token1 wrong sent')
		assert(token2Balance.toString() === '7500', 'token2 wrong sent')
	});


	it("Send inheritances erc721", async function () {
		// mint tokens
		await nft.mintMany(user, [1,2,3,4,5], ["","","","",""]);
		await nft2.mintMany(user, [1,2,3,4,5], ["","","","",""]);
		let own1 = await nft.ownerOf(1)
		let own2 = await nft2.ownerOf(3)
		assert(own1 = user, 'Not minted NFT')
		assert(own2 = user, 'Not minted NFT2')

		// set approves
		// await nft.setApprovalForAll(multiPay.address, true, {from:user})
		await nft2.setApprovalForAll(multiPay.address, true, {from:user})
		let isApproved1 = await nft.isApprovedForAll(user, multiPay.address);
		let isApproved2 = await nft2.isApprovedForAll(user, multiPay.address);
		assert(isApproved1 == false, 'Err check allowance NFT')
		assert(isApproved2 == true, 'Not approved NFT2')

		// send tokens to users
		const sendNftResult = await multiPay.sendInheritance721(
			user,
			[
				{
					token: nft.address,
					ids: [1,2,3],
					successors: [successor1, successor1, successor2]
				},
				{
					token: nft2.address,
					ids: [3,4,5],
					successors: [successor1, successor1, successor2]
				}
			],
			{from: serverAdmin}
		);
		debug && console.log(sendNftResult);

		own1 = await nft.ownerOf(1)
		own2 = await nft2.ownerOf(5)
		assert(own1 = user, 'Not transferred NFT')
		assert(own2 = successor2, 'Not transferred NFT2')

		const allowancesForAllNFT = await multiPay.checkNftCollectionShortInfo(
			user,
			[nft.address, nft2.address]
		);

		assert(
			allowancesForAllNFT[0].isApproved == false && allowancesForAllNFT[1].isApproved == true,
			'Wrong allowances for all check'
		)
	});


});