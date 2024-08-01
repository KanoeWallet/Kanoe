require('dotenv').config()
const Stable = artifacts.require("StableCoin");
const NFT = artifacts.require("MyNFT");
const Plans = artifacts.require("Plans");
const Subscriptions = artifacts.require("Subscriptions");
const SubscriptionLogic = artifacts.require("SubscriptionLogic");
const MultiPay = artifacts.require("MultiPay");
const config = require('./config')

const paymentHolder = process.env.PAYMENT_HOLDER;
const serviceWallet = process.env.SERVICE_WALLET;

module.exports = function (deployer, network, accounts) {
	deployer
		.deploy(Plans)
		.then(() => network == 'development' ? deployer.deploy(Stable, 'USDT', 'USDT', '1000000') : true)
		.then(() => network == 'development' ? deployer.deploy(NFT, 'NFT1', 'NFT1', 'https://') : true)
		.then(() => deployer.deploy(Subscriptions))
		.then(() => deployer.deploy(
			SubscriptionLogic,
			Plans.address,
			Subscriptions.address,
			paymentHolder,
			serviceWallet
		))
		.then(() => deployer.deploy(
			MultiPay,
			serviceWallet,
			serviceWallet
		))
		.then( async () => {

			const plansInstance = await Plans.deployed();
			const subscriptionsIntance = await Subscriptions.deployed();
			const subscriptionLogicInstance = await SubscriptionLogic.deployed();

			// set Logic is a manager of Subscription
			await subscriptionsIntance.changeAllowed(subscriptionLogicInstance.address, true);

			// add plans
			if (network == 'development') {
				const stableInstance = await Stable.deployed();
				for (let plan of config.plans) {
					await plansInstance.addPlan(
						plan.title,
						stableInstance.address,
						plan.price,
						plan.limits
					);
				}
			} else {
				for (let plan of config.plans) {
					await plansInstance.addPlan(
						plan.title,
						config.chains[network].stablecoins[0],
						plan.price,
						plan.limits
					);
				}
			}
		})
};