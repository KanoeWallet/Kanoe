module.exports = {
	chains: {
		polygontest: {
			stablecoins: [
				"0x36931d1A16cC2A552544D49723dD933f14B2bDA0",
				"0x364b37D9f51D9B54Ea0178593064F87A6b1566cF"
			]
		},
		ethereumtest: {
			stablecoins: [
				"0x36931d1A16cC2A552544D49723dD933f14B2bDA0"
			]
		},
		bsctest: {
			stablecoins: [
				"0x8e54F9a46b45eBCB18feca3cD9da892884389cA2",
				"0x8d26C4Ec103e0C7E35CDad884eE27F18296fEA12"
			]
		},
		development: {
			stablecoins: []
		},

		// MAINNETS
		polygon: {
			stablecoins: [
				"0xc2132d05d31c914a87c6611c10748aeb04b58e8f"
			]
		},
		bsc: {
			stablecoins: [
				"0x55d398326f99059fF775485246999027B3197955"
			]
		},
		ethereum: {
			stablecoins: [
				"0xdAC17F958D2ee523a2206206994597C13D831ec7"
			]
		},
	},
	plans: [
		{
			title: 'Starter',
			limits: {
				successorsMaxCount: 2,
				inheritancesMaxCount: 1,
				tokensMaxCount: 2,
				stableMaxSum: 5000000000,
				maxWalletsCount: 1
			},
			price: 15000000
		},
		{
			title: 'Basic',
			limits: {
				successorsMaxCount: 3,
				inheritancesMaxCount: 1,
				tokensMaxCount: 0,
				stableMaxSum: 0,
				maxWalletsCount: 1
			},
			price: 25000000
		},
		{
			title: 'Standart',
			limits: {
				successorsMaxCount: 8,
				inheritancesMaxCount: 3,
				tokensMaxCount: 0,
				stableMaxSum: 0,
				maxWalletsCount: 3
			},
			price: 50000000
		}
	]

}