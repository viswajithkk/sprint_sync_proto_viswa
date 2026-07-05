require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const localhostPrivateKey = process.env.LOCALHOST_PRIVATE_KEY;

module.exports = {
  solidity: "0.8.20",
  networks: {
    hardhat: {},
    localhost: {
      url: "http://127.0.0.1:8545",
      accounts: localhostPrivateKey ? [localhostPrivateKey] : undefined
    }
  }
};
