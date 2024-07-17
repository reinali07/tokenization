//npx hardhat run scripts/issuer.js --network localhost
const addresses = require('../ignition/deployments/chain-1337/deployed_addresses.json');

const hre = require("hardhat");

async function main() {
    const tokenContractAddress = addresses['StockModule#StockContract']
    const votingAddress = addresses['StockModule#VotingRights']

    const [owner, account1] = await hre.ethers.getSigners();

    const Stock = await hre.ethers.getContractAt("StockContract", tokenContractAddress, owner);
    const Voting = await hre.ethers.getContractAt("VotingRights", votingAddress, owner);

    await Stock.mint(account1,10);

    const multiplier = hre.ethers.FixedNumber.fromValue(5,1); //how many dividend units per token
    const intbalance = await Stock.balanceOf(account1.address); //user balance
    const decimals = Number(await Voting.decimals()); //decimals in dividend token contract
    const balance = hre.ethers.FixedNumber.fromValue(intbalance,decimals); //user balance in decimal
    const smallvalue = balance.mul(multiplier); //dividends to send in decimal
    const value = hre.ethers.parseUnits(smallvalue.toString(),decimals);

    const domain = {
        name: "VotingRights",
        version: "1",
        chainId: 1337, 
        verifyingContract: votingAddress
    } 

    const types = {
      Redeem: [
        {name:"messageId",type:"uint256"},
        {name:"holderAddress",type:"address"},
        {name:"value",type:"uint256"},
        {name:"nftdata",type:"uint256"},
      ]
    };

    const message0 = {
      messageId: 0,
      holderAddress: account1.address,
      value: value,
      nftdata: 0
    };
    const rawsignature0 = await owner.signTypedData(domain,types,message0);
    const signature0 = hre.ethers.Signature.from(rawsignature0);
    await Voting.connect(account1).redeem(message0.messageId,message0.value,message0.nftdata,signature0.v,signature0.r,signature0.s);

  
    const message = {
      messageId: 1,
      holderAddress: account1.address,
      value: value,
      nftdata: 0
    };

    const rawsignature = await owner.signTypedData(domain,types,message);
    const signature = hre.ethers.Signature.from(rawsignature);
    const transaction = await Voting.connect(account1).redeem(message.messageId,message.value,message.nftdata,signature.v,signature.r,signature.s);
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
  