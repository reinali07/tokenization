require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-ethers");
require("@nomicfoundation/hardhat-ignition-ethers");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.24",
      },
      {
        version: "0.4.17",
      },
    ],
  },
  networks: {
    hardhat: {
      chainId: 1337
    },
  }
};



