//npx hardhat run scripts/issuer.js --network localhost
const addresses = require('../ignition/deployments/chain-1337/deployed_addresses.json');

const hre = require("hardhat");

async function main() {
    const nftaddress = addresses['StockModule#MyNFT']
    const erc20address = addresses['StockModule#MyERC20']

    const [owner, account1] = await hre.ethers.getSigners();

    const erc20 = await hre.ethers.getContractAt("MyERC20", erc20address, owner);
    const nft = await hre.ethers.getContractAt("MyNFT", nftaddress, owner);

    await nft.safeMint(account1,0);
    const txn1 = await nft.safeMint(account1,1);
    const receipt1 = await txn1.wait();
    console.log(receipt1.gasUsed);

    erc20.mint(owner,2);
    await erc20.transfer(account1,1);
    const txn2 = await erc20.transfer(account1,1);
    const receipt2 = await txn2.wait();
    console.log(receipt2.gasUsed);

    const txn3 = await owner.sendTransaction({
      to: account1,
      value: ethers.parseUnits('1', 'ether'),
    });
    const receipt3 = await txn3.wait();
    console.log(receipt3.gasUsed);
  }
  
  // We recommend this pattern to be able to use async/await everywhere
  // and properly handle errors.
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  