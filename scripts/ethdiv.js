//npx hardhat run scripts/issuer.js --network localhost
const addresses = require('../ignition/deployments/chain-1337/deployed_addresses.json');

const hre = require("hardhat");

async function main() {
    const tokenContractAddress = addresses['StockModule#StockContract']
    const ethdividendAddress = addresses['StockModule#ETHDividend']

    const [owner, account1] = await hre.ethers.getSigners();

    const Stock = await hre.ethers.getContractAt("StockContract", tokenContractAddress, owner);
    const Dividend = await hre.ethers.getContractAt("ETHDividend", ethdividendAddress, owner);

    //await Stock.connect(account1).transfer(owner,1);
    await Stock.rename('newname','newsymbol');
    const renametxn = await Stock.rename('newname1','newsymbol2');
    const renamereceipt = await renametxn.wait();
    console.log(renamereceipt.gasUsed);

    await Stock.mint(account1,10);
    await owner.sendTransaction({
        to: ethdividendAddress,
        value: ethers.parseUnits('10', 'ether'),
      });
    await owner.sendTransaction({
      to: account1,
      value: ethers.parseUnits('10', 'ether'),
    });

    const multiplier = hre.ethers.FixedNumber.fromValue(1,1); //how many dividend units per token
    const intbalance = await Stock.balanceOf(account1.address);
    const balance = ethers.FixedNumber.fromValue(intbalance,0);
    const value = ethers.parseEther((balance.mul(multiplier)).toString());

    const domain = {
        name: "ETHDividend",
        version: "1",
        chainId: 1337, 
        verifyingContract: ethdividendAddress
    } 

    const types = {
      Redeem: [
        {name:"messageId",type:"uint256"},
        {name:"holderAddress",type:"address"},
        {name:"value",type:"uint256"},
      ]
    };

    const message = {
      messageId: 0,
      holderAddress: account1.address,
      value: value
    };

    const rawsignature = await owner.signTypedData(domain,types,message);
    const signature = hre.ethers.Signature.from(rawsignature);
    const transaction = await Dividend.connect(account1).redeem(message.messageId,message.value,signature.v,signature.r,signature.s);
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
  