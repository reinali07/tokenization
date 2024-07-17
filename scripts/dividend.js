//npx hardhat run scripts/dividend.js --network localhost
const addresses = require('../ignition/deployments/chain-1337/deployed_addresses.json');

const hre = require("hardhat");

async function main() {
    const tokenContractAddress = addresses['StockModule#StockContract']
    const dividendContractAddress = addresses['StockModule#ERC20Dividend']
    const coinAddress = addresses['StockModule#Coin']

    const [owner, account1] = await hre.ethers.getSigners();

    const Stock = await hre.ethers.getContractAt("StockContract", tokenContractAddress, owner);
    const Dividend = await hre.ethers.getContractAt("ERC20Dividend", dividendContractAddress, owner);
    const Coin = await hre.ethers.getContractAt("Coin", coinAddress, owner);

    await Stock.mint(account1,10);
    await Coin.mint(account1,10000000);
    await Coin.mint(dividendContractAddress,10000000);

    const multiplier = hre.ethers.FixedNumber.fromValue(1,0); //how many dividend units per token
    const intbalance = await Stock.balanceOf(account1.address); //user balance
    const decimals = Number(await Coin.decimals()); //decimals in dividend token contract
    const balance = hre.ethers.FixedNumber.fromValue(intbalance,decimals); //user balance in decimal
    const smallvalue = balance.mul(multiplier); //dividends to send in decimal
    const value = hre.ethers.parseUnits(smallvalue.toString(),decimals);

    const domain = {
        name: "ERC20Dividend",
        version: "1",
        chainId: 1337, 
        verifyingContract: dividendContractAddress
    } 

    const types = {
      Redeem: [
        {name:"messageId",type:"uint256"},
        {name:"holderAddress",type:"address"},
        {name:"value",type:"uint256"},
        {name:"dividendTokenAddress", type:"address"}
      ]
    };

      const message = {
        messageId: 0,
        holderAddress: account1.address,
        value: value,
        dividendTokenAddress: coinAddress
      };

    const rawsignature = await owner.signTypedData(domain,types,message);
    const signature = hre.ethers.Signature.from(rawsignature);
    const transaction = await Dividend.connect(account1).redeem(message.messageId,message.value,message.dividendTokenAddress,signature.v,signature.r,signature.s);
    const receipt = await transaction.wait();
    const gasUsed = receipt.gasUsed;
    console.log(gasUsed);
    
  }
  
  // We recommend this pattern to be able to use async/await everywhere
  // and properly handle errors.
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  
