
const fs = require( 'fs' );
require("solidity-coverage");
require("@nomiclabs/hardhat-truffle5");

//https://hardhat.org/plugins/hardhat-gas-reporter.html
require("hardhat-gas-reporter");

const json = fs.readFileSync( '.env.json' );
const env = JSON.parse( json );


module.exports = {
  //defaultNetwork: "rinkeby",
  etherscan: {
    apiKey: {
      mainnet: env.ETHERSCAN_API_KEY
    }
  },
  networks: {
    hardhat: {
      forking: {
        enabled: false,
        url: `https://mainnet.infura.io/v3/${env.INFURA.PROJECT_ID}`
      }
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${env.INFURA.PROJECT_ID}`,
      accounts: [ env.ACCOUNTS.SQUEEBO_2.PK ]
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${env.INFURA.PROJECT_ID}`,
      accounts: []
    }
  },
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  paths: {
    artifacts: "./artifacts",
    cache: "./cache",
    sources: "./contracts",
    tests: "./test",
  },
  mocha: {
    timeout: 20000
  }
};
