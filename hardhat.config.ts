require("dotenv").config();
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("solidity-coverage");
require('@openzeppelin/hardhat-upgrades');

const { PRIVATE_KEY, TEST_KEY, FUJI_URL } = process.env;

import { HardhatUserConfig } from "hardhat/config";

const config: HardhatUserConfig = {
  solidity: "0.8.4",
  networks: {
    fuji: {
      url: FUJI_URL || "",
      accounts: [TEST_KEY || ""]
    },
    hardhat: {
      chainId: 43114,
      gasPrice: 225000000000,
      throwOnTransactionFailures: false,
      loggingEnabled: true,
      accounts: [{
        privateKey: TEST_KEY || "",
        balance: "1000000000000000000000",
      }],
      forking: {
        url: "https://api.avax.network/ext/bc/C/rpc",
        enabled: true
      },
    }
  }
};

export default config;
