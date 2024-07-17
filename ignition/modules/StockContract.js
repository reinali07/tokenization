//npx hardhat ignition deploy ./ignition/modules/StockContract.js --network localhost

const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const StockModule = buildModule("StockModule", (m) => {
  const stock = m.contract("StockContract",["Stock","STK"]);
  const dividend = m.contract("ERC20Dividend");
  const coin = m.contract("Coin");
  const ethdiv = m.contract("ETHDividend");
  const votenft = m.contract("VotingRights");
  //const acquisition = m.contract("Acquisition");
  //const test = m.contract("Test");
  const myerc20 = m.contract("MyERC20");
  const mynft = m.contract("MyNFT");

  return { stock, dividend, coin, ethdiv, votenft, myerc20, mynft };
});

module.exports = StockModule;