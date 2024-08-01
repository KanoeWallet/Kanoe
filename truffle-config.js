require('dotenv').config();
const {
	MNEMONIC,
	POLYGON_MAINNET_HOST,
	POLYGON_MAINNET_ID,
	POLYGON_TESTNET_HOST,
	POLYGON_TESTNET_ID,
	BASE_MAINNET_HOST,
	BASE_MAINNET_ID,
	BASE_TESTNET_HOST,
	BASE_TESTNET_ID,
	BSC_MAINNET_HOST,
	BSC_MAINNET_ID,
	BSC_TESTNET_HOST,
	BSC_TESTNET_ID,
	ETHEREUM_MAINNET_HOST,
	ETHEREUM_MAINNET_ID,
	ETHEREUM_TESTNET_HOST,
	ETHEREUM_TESTNET_ID,
	ADMIN_ADDRESS,
	BASESCAN_KEY,
	POLYGONSCAN_KEY
} = process.env;

const HDWalletProvider = require('@truffle/hdwallet-provider');

module.exports = {

  networks: {
	base: {
		provider: () => new HDWalletProvider(
			MNEMONIC,
			BASE_MAINNET_HOST
		),
		networkCheckTimeoutnetworkCheckTimeout: 10000,
		network_id: BASE_MAINNET_ID,
		confirmations: 2,
		timeoutBlocks: 200,
		gasPrice: 42871250,
		from: ADMIN_ADDRESS,
		verify: {
			apiUrl: 'https://api.basescan.org/api',
			apiKey: BASESCAN_KEY,
			explorerUrl: 'https://basescan.org/',
		  },
	},

	basetest: {
		provider: () => new HDWalletProvider(
			MNEMONIC,
			BASE_TESTNET_HOST
		),
		networkCheckTimeoutnetworkCheckTimeout: 10000,
		network_id: BASE_TESTNET_ID,
		confirmations: 2,
		timeoutBlocks: 200,
		gasPrice: 1050109609,
		from: ADMIN_ADDRESS
	},

	polygon: {
		provider: () => new HDWalletProvider(
			MNEMONIC,
			POLYGON_MAINNET_HOST
		),
		networkCheckTimeoutnetworkCheckTimeout: 10000,
		network_id: POLYGON_MAINNET_ID,
		confirmations: 2,
		timeoutBlocks: 200,

		gasPrice: 37000000000,
		from: ADMIN_ADDRESS
	},

	polygontest: {
		provider: () => new HDWalletProvider(
			MNEMONIC,
			POLYGON_TESTNET_HOST
		),
		networkCheckTimeoutnetworkCheckTimeout: 10000,
		network_id: POLYGON_TESTNET_ID,
		confirmations: 2,
		timeoutBlocks: 200,
		gasPrice: 1550109609,
		from: ADMIN_ADDRESS
	},

	ethereum: {
		provider: () => new HDWalletProvider(
			MNEMONIC,
			ETHEREUM_MAINNET_HOST
		),
		networkCheckTimeoutnetworkCheckTimeout: 10000,
		network_id: ETHEREUM_MAINNET_ID,
		confirmations: 1,
		timeoutBlocks: 200,
		gasPrice: 13000000000,
		from: ADMIN_ADDRESS
	},

	ethereumtest: {
		provider: () => new HDWalletProvider(
			MNEMONIC,
			ETHEREUM_TESTNET_HOST
		),
		networkCheckTimeoutnetworkCheckTimeout: 10000,
		network_id: ETHEREUM_TESTNET_ID,
		confirmations: 2,
		timeoutBlocks: 200,
		// gas: 5000000,
		// gasPrice: 21000000000,
		skipDryRun: true,
		from: ADMIN_ADDRESS
	},

	bsc: {
		provider: () => new HDWalletProvider(
			MNEMONIC,
			BSC_MAINNET_HOST
		),
		networkCheckTimeoutnetworkCheckTimeout: 10000,
		network_id: BSC_MAINNET_ID,
		confirmations: 2,
		timeoutBlocks: 200,
		gasPrice: 1000000000,
		from: ADMIN_ADDRESS
	},

	bsctest: {
		provider: () => new HDWalletProvider(
			MNEMONIC,
			BSC_TESTNET_HOST
		),
		networkCheckTimeoutnetworkCheckTimeout: 10000,
		network_id: BSC_TESTNET_ID,
		confirmations: 2,
		timeoutBlocks: 200,
		gasPrice: 5550109609,
		from: ADMIN_ADDRESS
	},


    development: {
		host: "127.0.0.1",     // Localhost (default: none)
		port: 7545,            // Standard Ethereum port
		network_id: "5777",       // Any network
		gasPrice: 12000000000,
	},


  },

  // Set default mocha options here, use special reporters, etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.8.19", // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      settings: {          // See the solidity docs for advice about optimization and evmVersion
       optimizer: {
         enabled: true,
         runs: 200,
		 details: {
			yul: false
		  }
       },
    //    evmVersion: "byzantium"
      }
    }
  },

  plugins: [
	'truffle-contract-size',
	'truffle-plugin-verify'
  ],

  api_keys: {
	  base: BASESCAN_KEY,
	  polygon: POLYGONSCAN_KEY
  }

};
