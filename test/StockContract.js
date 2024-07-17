const {
    time,
    loadFixture,
  } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
  const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
  const { expect } = require("chai");
  
  describe("StockContract", function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    async function deployStock(){
      const [owner, account1, account2] = await ethers.getSigners();
      const Stock = await ethers.getContractFactory("StockContract");
      const stock = await Stock.deploy("Stock","STK");

      return { stock, owner, account1, account2 };
    }
    async function deployDividend(){
      const Dividend = await ethers.getContractFactory("ERC20Dividend");
      const dividend = await Dividend.deploy();
      return dividend;
    }
    async function deployETHDividend(){
      const ETHDividend = await ethers.getContractFactory("ETHDividend");
      const ethdividend = await ETHDividend.deploy();
      return ethdividend;
    }
    async function deployVotingRights(){
      const VotingRights = await ethers.getContractFactory("VotingRights");
      const voting = await VotingRights.deploy();
      return voting;
    }
    async function deployCoin(){
      const Coin = await ethers.getContractFactory("Coin");
      const coin = await Coin.deploy();
      return coin;
    }
    async function getUtils() {
      const abi = ethers.AbiCoder.defaultAbiCoder();
      const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
      const chainId = network.config.chainId;
      const provider = ethers.provider;
      return {abi, ZERO_ADDRESS, chainId, provider};
    }

    describe("Deployment", function() {
        it("Should set the right owners", async function () {
          const {stock, owner} = await loadFixture(deployStock);
          const dividend = await loadFixture(deployDividend);
          const ethdiv = await loadFixture(deployETHDividend);
          const voting = await loadFixture(deployVotingRights);
          const coin = await loadFixture(deployCoin);

          await expect(await stock.owner()).to.equal(owner.address);
          await expect(await coin.owner()).to.equal(owner.address);
          await expect(await dividend.owner()).to.equal(owner.address);
          await expect(await voting.owner()).to.equal(owner.address);
          expect(await ethdiv.owner()).to.equal(owner.address);
        });
    });

    describe("Stock ERC-20 Functionality", function() {
        it("Should let owner mint", async function () {
            const {stock, owner, account1} = await loadFixture(deployStock); 
            const {abi, ZERO_ADDRESS} = await getUtils();

            await expect(stock.mint(account1,100)).to.emit(stock,"Transfer").withArgs(ZERO_ADDRESS,account1.address,100);
        });
        it("Should revert when other tries to mint", async function () {
            const {stock, owner, account1,account2} = await loadFixture(deployStock); 

            await expect(stock.connect(account1).mint(account2,100)).to.be.reverted;
        });
        it("Should let users transfer balance", async function() {
            const {stock, owner, account1, account2 } = await loadFixture(deployStock); 
            await stock.mint(account1,100);

            await expect(stock.connect(account1).transfer(account2,50)).to.emit(stock, "Transfer").withArgs(account1.address,account2.address,50);
        });
    });

    describe("Redeem ERC20 Dividend", function () {
        it("Should let user redeem from valid message", async function () {
            const {stock, owner, account1} = await loadFixture(deployStock);
            const {abi, ZERO_ADDRESS, chainId} = await getUtils();
            const dividend = await loadFixture(deployDividend);
            const coin = await loadFixture(deployCoin);

            const dividendaddress = await dividend.getAddress();
            const coinaddress = await coin.getAddress()

            await stock.mint(account1.address,100);
            await coin.mint(await dividend.getAddress(),100);

            const multiplier = ethers.FixedNumber.fromValue(5,1); //how many dividend units per token
            const intbalance = await stock.balanceOf(account1.address); //user balance
            const decimals = Number(await coin.decimals()); //decimals in dividend token contract
            const balance = ethers.FixedNumber.fromValue(intbalance,decimals); //user balance in decimal
            const smallvalue = balance.mul(multiplier); //dividends to send in decimal
            const value = ethers.parseUnits(smallvalue.toString(),decimals);

            const domain = {
              name: "ERC20Dividend",
              version: "1",
              chainId: chainId, 
              verifyingContract: dividendaddress
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
              dividendTokenAddress: coinaddress 
            };

            const rawsignature = await owner.signTypedData(domain,types,message);
            const signature = hre.ethers.Signature.from(rawsignature);

            await expect(dividend.connect(account1).redeem(message.messageId,message.value,message.dividendTokenAddress,signature.v,signature.r,signature.s)).to.emit(dividend,"Redeemed").withArgs(message.messageId,account1.address,value,coinaddress);          
            expect(await coin.balanceOf(account1.address)).to.equal(value);
        });
        it("Should not let user redeem from one message multiple times", async function () {
          const {stock, owner, account1} = await loadFixture(deployStock);
          const {abi, ZERO_ADDRESS, chainId} = await getUtils();
          const dividend = await loadFixture(deployDividend);
          const coin = await loadFixture(deployCoin);

          const dividendaddress = await dividend.getAddress();
          const coinaddress = await coin.getAddress()

          await stock.mint(account1.address,100);
          await coin.mint(await dividend.getAddress(),100);

          const multiplier = ethers.FixedNumber.fromValue(5,1); //how many dividend units per token
          const intbalance = await stock.balanceOf(account1.address); //user balance
          const decimals = Number(await coin.decimals()); //decimals in dividend token contract
          const balance = ethers.FixedNumber.fromValue(intbalance,decimals); //user balance in decimal
          const smallvalue = balance.mul(multiplier); //dividends to send in decimal
          const value = ethers.parseUnits(smallvalue.toString(),decimals);

          const domain = {
            name: "ERC20Dividend",
            version: "1",
            chainId: chainId, 
            verifyingContract: dividendaddress
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
            dividendTokenAddress: coinaddress 
          };

          const rawsignature = await owner.signTypedData(domain,types,message);
          const signature = hre.ethers.Signature.from(rawsignature);

          await expect(dividend.connect(account1).redeem(message.messageId,message.value,message.dividendTokenAddress,signature.v,signature.r,signature.s)).to.emit(dividend,"Redeemed").withArgs(message.messageId,account1.address,value,coinaddress);
          await expect(await coin.balanceOf(account1.address)).to.equal(value);
          await expect(dividend.connect(account1).redeem(message.messageId,message.value,message.dividendTokenAddress,signature.v,signature.r,signature.s)).to.be.revertedWithCustomError(dividend,"AlreadyRedeemed").withArgs(message.messageId);
      });
    });
    describe("Redeem ETH Dividend", function () {
      it("Should let user redeem from valid message", async function () {
          const {stock, owner, account1} = await loadFixture(deployStock);
          const {abi, ZERO_ADDRESS, chainId, provider} = await getUtils();
          const ethdiv = await loadFixture(deployETHDividend);

          const ethdivaddress = await ethdiv.getAddress();

          await stock.mint(account1.address,100);
          await owner.sendTransaction({
            to: await ethdiv.getAddress(),
            value: ethers.parseUnits('100', 'ether'),
          });

          const multiplier = ethers.FixedNumber.fromValue(5,1); //how many dividend units per token
          const balance = ethers.FixedNumber.fromValue(await stock.balanceOf(account1.address),0);
          const value = ethers.parseEther((balance.mul(multiplier)).toString());

          const domain = {
            name: "ETHDividend",
            version: "1",
            chainId: chainId, 
            verifyingContract: ethdivaddress
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
            value: value,
          };

          const rawsignature = await owner.signTypedData(domain,types,message);
          const signature = hre.ethers.Signature.from(rawsignature);

          const prevBalance = await provider.getBalance(account1.address);

          await expect(ethdiv.connect(account1).redeem(message.messageId,message.value,signature.v,signature.r,signature.s)).to.emit(ethdiv,"Redeemed").withArgs(message.messageId,account1.address,value);            
          expect(await provider.getBalance(account1.address)).to.be.greaterThan(prevBalance);
      });
      it("Should not let user redeem from one message multiple times", async function () {
        const {stock, owner, account1} = await loadFixture(deployStock);
          const {abi, ZERO_ADDRESS, chainId, provider} = await getUtils();
          const ethdiv = await loadFixture(deployETHDividend);

          const ethdivaddress = await ethdiv.getAddress();

          await stock.mint(account1.address,100);
          await owner.sendTransaction({
            to: await ethdiv.getAddress(),
            value: ethers.parseUnits('100', 'ether'),
          });

          const multiplier = ethers.FixedNumber.fromValue(5,1); //how many dividend units per token
          const balance = ethers.FixedNumber.fromValue(await stock.balanceOf(account1.address),0);
          const value = ethers.parseEther((balance.mul(multiplier)).toString());

          const domain = {
            name: "ETHDividend",
            version: "1",
            chainId: chainId, 
            verifyingContract: ethdivaddress
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
            value: value,
          };

          const rawsignature = await owner.signTypedData(domain,types,message);
          const signature = hre.ethers.Signature.from(rawsignature);

          const prevBalance = await provider.getBalance(account1.address);

          await expect(ethdiv.connect(account1).redeem(message.messageId,message.value,signature.v,signature.r,signature.s)).to.emit(ethdiv,"Redeemed").withArgs(message.messageId,account1.address,value);        
          await expect(await provider.getBalance(account1.address)).to.be.greaterThan(prevBalance);
          await expect(ethdiv.connect(account1).redeem(message.messageId,message.value,signature.v,signature.r,signature.s)).to.be.revertedWithCustomError(ethdiv,"AlreadyRedeemed").withArgs(message.messageId);
    });
  });
  describe("Redeem Voting Right", function () {
    it("Should let user redeem from valid message", async function () {
        const {stock, owner, account1} = await loadFixture(deployStock);
        const {abi, ZERO_ADDRESS, chainId} = await getUtils();
        const voting = await loadFixture(deployVotingRights);

        const votingaddress = await voting.getAddress();

        await stock.mint(account1.address,100);

        const multiplier = ethers.FixedNumber.fromValue(5,1); //how many dividend units per token
        const intbalance = await stock.balanceOf(account1.address); //user balance
        const decimals = Number(await voting.decimals()); //decimals in dividend token contract
        const balance = ethers.FixedNumber.fromValue(intbalance,decimals); //user balance in decimal
        const smallvalue = balance.mul(multiplier); //dividends to send in decimal
        const value = ethers.parseUnits(smallvalue.toString(),decimals);

        const domain = {
          name: "VotingRights",
          version: "1",
          chainId: chainId, 
          verifyingContract: votingaddress
        } 

        const types = {
          Redeem: [
            {name:"messageId",type:"uint256"},
            {name:"holderAddress",type:"address"},
            {name:"value",type:"uint256"},
            {name:"nftdata",type:"uint256"},
          ]
        };

        const message = {
          messageId: 0,
          holderAddress: account1.address,
          value: value,
          nftdata: 0
        };

        const rawsignature = await owner.signTypedData(domain,types,message);
        const signature = hre.ethers.Signature.from(rawsignature);

        await expect(voting.connect(account1).redeem(message.messageId,message.value,message.nftdata,signature.v,signature.r,signature.s)).to.emit(voting,"Redeemed").withArgs(message.messageId,account1.address,value,message.nftdata);            

        expect(await voting.balanceOf(account1.address)).to.equal(1);
    });
    it("Should not let user redeem from one message multiple times", async function () {
      const {stock, owner, account1} = await loadFixture(deployStock);
      const {abi, ZERO_ADDRESS, chainId} = await getUtils();
      const voting = await loadFixture(deployVotingRights);

      const votingaddress = await voting.getAddress();

      await stock.mint(account1.address,100);

      const multiplier = ethers.FixedNumber.fromValue(5,1); //how many dividend units per token
      const intbalance = await stock.balanceOf(account1.address); //user balance
      const decimals = Number(await voting.decimals()); //decimals in dividend token contract
      const balance = ethers.FixedNumber.fromValue(intbalance,decimals); //user balance in decimal
      const smallvalue = balance.mul(multiplier); //dividends to send in decimal
      const value = ethers.parseUnits(smallvalue.toString(),decimals);

      const domain = {
        name: "VotingRights",
        version: "1",
        chainId: chainId, 
        verifyingContract: votingaddress
      } 

      const types = {
        Redeem: [
          {name:"messageId",type:"uint256"},
          {name:"holderAddress",type:"address"},
          {name:"value",type:"uint256"},
          {name:"nftdata",type:"uint256"},
        ]
      };

      const message = {
        messageId: 0,
        holderAddress: account1.address,
        value: value,
        nftdata: 0
      };

      const rawsignature = await owner.signTypedData(domain,types,message);
      const signature = hre.ethers.Signature.from(rawsignature);

      await expect(voting.connect(account1).redeem(message.messageId,message.value,message.nftdata,signature.v,signature.r,signature.s)).to.emit(voting,"Redeemed").withArgs(message.messageId,account1.address,value,message.nftdata);            

      expect(await voting.balanceOf(account1.address)).to.equal(1);
      await expect(voting.connect(account1).redeem(message.messageId,message.value,message.nftdata,signature.v,signature.r,signature.s)).to.be.revertedWithCustomError(voting,"AlreadyRedeemed").withArgs(message.messageId);
    });
  });
});
  