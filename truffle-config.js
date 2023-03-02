
const fs = require( 'fs' );
const HDWalletProvider = require("@truffle/hdwallet-provider");

const json = fs.readFileSync( '.env.json' );
const env = JSON.parse( json );

//https://www.trufflesuite.com/docs/truffle/reference/configuration
module.exports = {
  //https://github.com/rkalis/truffle-plugin-verify#usage-with-other-chains
  api_keys: {
    //ethereum
    etherscan: env.ETHERSCAN_API_KEY,

    //polygon
    polygonscan: env.POLYSCAN_API_KEY
  },
  compilers: {
    solc: {
      version: '0.8.17', // A version or constraint - Ex. "^0.5.0"
                         // Can also be set to "native" to use a native solc
      //docker: <boolean>, // Use a version obtained through docker
      parser: "solcjs",  // Leverages solc-js purely for speedy parsing
      settings: {
        optimizer: {
          enabled: true,
          runs:     200   // Optimize for how many times you intend to run the code
        },
        //</number>evmVersion: <string> // Default: "istanbul"
      },
      // contains options for SMTChecker
      //modelCheckerSettings: {}
    }
  },
  networks: {
    mainnet: {
      provider: function() {
        return new HDWalletProvider({
          //providerOrUrl: `https://mainnet.infura.io/v3/${env.INFURA.PROJECT_ID}`,
          providerOrUrl: `wss://mainnet.infura.io/ws/v3/${env.INFURA.PROJECT_ID}`,
          privateKeys: [ env.ACCOUNTS.POOBS.PK ]
        });
      },
      network_id:  1,
      gas:                       3_500_000,
      //gasPrice:             17_000_000_000,
      maxPriorityFeePerGas:  1_000_000_000,
      maxFeePerGas:         20_000_000_000,
      //                   100    gwei
      //                       000_000_000
      skipDryRun: true
    },

    goerli: {
      provider: function() {
        return new HDWalletProvider({
          providerOrUrl: `wss://goerli.infura.io/ws/v3/${env.INFURA.PROJECT_ID}`,

          //Squeebo(2): 0x282D35Ee1b589F003db896b988fc59e2665Fa6a1
          privateKeys: [ env.ACCOUNTS.SQUEEBO_2.PK ]
        });
      },
      gas:            5_000_000,
      gasPrice:   2_500_000_000,
      //        100    gwei
      //            000_000_000
      network_id: 5,
      skipDryRun: true
    },

    sepolia: {
      provider: function() {
        return new HDWalletProvider({
          providerOrUrl: `wss://sepolia.infura.io/ws/v3/${env.INFURA.PROJECT_ID}`,

          //Squeebo(2): 0x282D35Ee1b589F003db896b988fc59e2665Fa6a1
          privateKeys: [ env.ACCOUNTS.SQUEEBO_2.PK ]
        });
      },
      //gas:            5_000_000,
      //gasPrice:   2_500_000_000,
      //        100    gwei
      //            000_000_000
      network_id: 11155111,
      skipDryRun: true
    },

    polygon: {
      provider: function() {
        return new HDWalletProvider({
          providerOrUrl: `https://polygon-mainnet.infura.io/v3/${env.INFURA.PROJECT_ID}`,
          //providerOrUrl: "https://polygon-mainnet.infura.io/v3/12e19319ef004c5f86f503f33b3c1c37",
          //providerOrUrl: "https://polygon-mainnet.g.alchemy.com/v2/LmSv29yVEkJyxWAe0lc48Iy-yaQwN0A4",
          privateKeys: [ env.ACCOUNTS.SQUEEBO_2.PK ]
        });
      },
      network_id:                       137,
      gas:                        5_000_000,
      //gasPrice:           100_000_000_000,
      //                    100    gwei
      //                        000_000_000
      maxPriorityFeePerGas:  35_000_000_000,
      maxFeePerGas:         100_000_000_000,
      //                    100    gwei
      //                        000_000_000
      skipDryRun: true
    },

    mumbai: {
      provider: function() {
        //wss://ws-matic-mumbai.chainstacklabs.com
        return new HDWalletProvider({
          providerOrUrl: `https://polygon-mumbai.infura.io/v3/${env.INFURA.PROJECT_ID}`,
        });
      },
      network_id: 80001,
    },

    //LOCAL
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*"
    },
    localfork: {
      provider: function() {
        return new HDWalletProvider({
          providerOrUrl: "http://192.168.1.31:8545",
        });
      },
      network_id: 1
    },
  },
  mocha: {
    timeout: 20000
  },
  plugins: [
    'truffle-plugin-verify'
  ]
};
