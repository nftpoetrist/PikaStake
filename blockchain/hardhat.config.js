require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: { enabled: true, runs: 200 },
    },
  },
  networks: {
    arcTestnet: {
      url: "https://5042002.rpc.thirdweb.com",
      accounts: [process.env.PRIVATE_KEY],
      chainId: 5042002,
    },
  },
};
