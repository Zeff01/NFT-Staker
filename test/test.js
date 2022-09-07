const { expect } = require("chai");
const { loadFixture } = require("ethereum-waffle");
const { ethers } = require("hardhat");
const { parseEther } = require("ethers/lib/utils");

describe("NFT Staking", () => {
  async function testFixture() {
    let NFTStakerContract;
    let NFTStaker;
    let PokemonContract;
    let Pokemon;

    const [owner, acct1, acct2] = await ethers.getSigners();

    Pokemon = await ethers.getContractFactory("Pokemon");
    PokemonContract = await Pokemon.deploy();
    await PokemonContract.deployed();

    NFTStaker = await ethers.getContractFactory("NFTStaker");
    NFTStakerContract = await NFTStaker.deploy(PokemonContract.address, {
      value: ethers.utils.parseEther("1"),
    });
    await NFTStakerContract.deployed();

    return {
      owner,
      acct1,
      acct2,
      PokemonContract,
      NFTStakerContract,
    };
  }

  describe("Contracts deployed....", () => {
    it("Should set the rightful owner of Pokemon NFT contract", async () => {
      const { owner, PokemonContract } = await loadFixture(testFixture);
      expect(await PokemonContract.owner()).to.be.equal(owner.address);
    });

    it("Should set the rightful owner of NFTStaker contract", async () => {
      const { owner, NFTStakerContract } = await loadFixture(testFixture);
      expect(await NFTStakerContract.owner()).to.be.equal(owner.address);
    });

    describe("NFT Minting a token", () => {
      it("Check the current supply of the NFT", async () => {
        const { owner, PokemonContract } = await loadFixture(testFixture);

        expect(await PokemonContract.currentSupply()).to.be.equal(0);
      });

      it("Mint 2 NFT for testing", async () => {
        const { owner, PokemonContract } = await loadFixture(testFixture);

        await PokemonContract.safeMint();
        await PokemonContract.safeMint();

        //check current supply if 2
        //if its 2, Mint Successfull
        expect(await PokemonContract.currentSupply()).to.be.equal(2);
      });
    });

    it("", async () => {});

    describe("Staker Contract", () => {
      it("Should set locktime period", async () => {
        const { NFTStakerContract } = await loadFixture(testFixture);

        await NFTStakerContract.setLockTimePeriod(60);
        expect(await NFTStakerContract.lockPeriod()).to.equal(60);
      });

      it("Should stake an NFT after approving", async () => {
        const { NFTStakerContract, PokemonContract } = await loadFixture(
          testFixture
        );
        await PokemonContract.approve(NFTStakerContract.address, 0);

        await NFTStakerContract.stake(0);
      });

      it("Should not unstake an NFT before lockperiod time", async () => {
        const { NFTStakerContract } = await loadFixture(testFixture);

        //*******************adjust time if there is error in test**************\\
        await NFTStakerContract.setLockTimePeriod(1662574802);
        await expect(NFTStakerContract.unStake(0)).to.be.revertedWith(
          "Stake is still in lock period"
        );
      });

      it("should view the rewards", async () => {
        const { NFTStakerContract, owner } = await loadFixture(testFixture);

        let value = await NFTStakerContract.viewRewards(owner.address);

      });

      it("should unstake after fastfoward of lockperiod time ", async () => {
        const { NFTStakerContract } = await loadFixture(testFixture);

        // fast forward time
        // increase time by 1762574802 seconds
        await ethers.provider.send("evm_increaseTime", [1762574802]);
        await NFTStakerContract.unStake(0);
      });

      it("should claim the rewards", async () => {
        const { NFTStakerContract, owner } = await loadFixture(testFixture);

        await expect(
          await NFTStakerContract.claimRewards()
        ).to.changeEtherBalance(owner, 1000000000000000);
      });
    });
  });
});
