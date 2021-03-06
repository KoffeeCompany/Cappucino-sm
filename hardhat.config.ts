import { HardhatUserConfig } from "hardhat/config";

// PLUGINS
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers";
import "@typechain/hardhat";
import "hardhat-deploy";

// Process Env Variables
import * as dotenv from "dotenv";
import { ethers, utils } from "ethers";
dotenv.config({ path: __dirname + "/.env" });

const PK = process.env.PK;
const PK_MAINNET = process.env.PK_MAINNET;
const PK_ARBITRUM = process.env.PK_ARBITRUM;
const ALCHEMY_ID = process.env.ALCHEMY_ID;
const ARBITRUM_ALCHEMY_ID = process.env.ARBITRUM_ALCHEMY_ID;
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",

  // hardhat-deploy
  namedAccounts: {
    deployer: {
      default: 0,
    },
    gelatoMultiSig: {
      arbitrum: "0xa2BC74F8C81b46BADbD8C20bF9Bd31DAd2CEDba8",
      mainnet: "0xeD5cF41b0fD6A3C564c17eE34d9D26Eafc30619b",
    },
  },

  networks: {
    hardhat: {
      forking: {
        url: `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_ID}`,
        blockNumber: 13476568, // ether price $4,168.96
      },
      accounts: {
        accountsBalance: ethers.utils.parseEther("10000").toString(),
      },
    },
    goerli: {
      accounts: PK ? [PK] : [],
      chainId: 5,
      url: `https://eth-goerli.alchemyapi.io/v2/${ALCHEMY_ID}`,
      gasPrice: parseInt(utils.parseUnits("60", "gwei").toString()),
    },
    arbitrum: {
      accounts: PK_ARBITRUM ? [PK_ARBITRUM] : [],
      chainId: 42161,
      url: `https://arb-mainnet.g.alchemy.com/v2/${ARBITRUM_ALCHEMY_ID}`,
      gasPrice: parseInt(utils.parseUnits("2", "gwei").toString()),
    },
    mainnet: {
      accounts: PK_MAINNET ? [PK_MAINNET] : [],
      chainId: 1,
      url: `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_ID}`,
    },
  },

  etherscan: {
    apiKey: ETHERSCAN_API_KEY ? ETHERSCAN_API_KEY : "",
  },

  solidity: {
    compilers: [
      {
        version: "0.8.10",
        settings: {
          optimizer: { enabled: true, runs: 200000 },
          modelChecker: {
            targets: [
              "balance",
              "popEmptyArray",
              "constantCondition",
              "divByZero",
              "assert",
            ],
            showUnproved: true,
            engine: "none",
            contracts: {
              "contracts/OptionPool.sol": ["OptionPool"],
              "contracts/OptionPoolFactory.sol": ["OptionPoolFactory"],
              "contracts/PokeMeResolver.sol": ["PokeMeResolver"],
            },
          },
        },
      },
    ],
  },

  typechain: {
    outDir: "typechain",
    target: "ethers-v5",
  },
};

export default config;
