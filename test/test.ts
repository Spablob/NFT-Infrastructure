import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { ethers } from 'hardhat';
import { TA } from '../typechain-types';
import { TB } from '../typechain-types';
import { TBpool } from '../typechain-types';
import { Marketplace } from '../typechain-types';

describe('NFT Licensing', async () => {
  let TAcontract: TA;
  let TBcontract: TB;
  let marketplace: Marketplace;
  let pool: TBpool;
  let accounts: SignerWithAddress[];

  before(async () => {
    accounts = await ethers.getSigners();

    // Deploy TA Contract
    const TAcontractFactory = await ethers.getContractFactory('TA');
    TAcontract = await TAcontractFactory.deploy();
    await TAcontract.deployed();
    // console.log({ 'TA contract deployed to': TAcontract.address });

    // Deploy TB Contract
    const TBcontractFactory = await ethers.getContractFactory('TB');
    TBcontract = await TBcontractFactory.deploy(TAcontract.address);
    await TBcontract.deployed();
    // console.log({ 'TB contract deployed to': TBcontract.address });

    // Deploy TBpool Contract
    const TBpoolFactory = await ethers.getContractFactory('TBpool');
    pool = await TBpoolFactory.deploy(TBcontract.address);
    await pool.deployed();

    // Deploy Marketplace Contract
    const MarketplaceFactory = await ethers.getContractFactory('Marketplace');
    marketplace = await MarketplaceFactory.deploy(TBcontract.address, pool.address, TAcontract.address);
    await marketplace.deployed();
    // console.log({ 'Marketplace contract deployed to': marketplace.address });

    await TAcontract.connect(accounts[0]).setInstances(pool.address);
    await TBcontract.connect(accounts[0]).setInstances(pool.address);
  });

  describe('TA Interactions', async () => {
    it('Owner and User 1 fail to reset TB address', async () => {
      await expect(TAcontract.connect(accounts[0]).setInstances(pool.address)).to.be.revertedWith(
        'Cannot set TB contract address twice'
      );
      await expect(TAcontract.connect(accounts[1]).setInstances(pool.address)).to.be.revertedWith(
        'Ownable: caller is not the owner'
      );
    });
    it('User 1 successfully mints TA', async () => {
      TAcontract.connect(accounts[1]).setApprovalForAll(TAcontract.address, true);
      await TAcontract.connect(accounts[1]).mintTA(
        'Fried Rice',
        'QmTmfTk7N4SBZu2WeUjtMh9CPQvKs4gGH4fjqR5GiMBys9',
        ethers.utils.parseEther('1'),
        80,
        604800,
        10000
      );
      expect(await TAcontract.uri(1)).to.be.equal('ipfs://QmTmfTk7N4SBZu2WeUjtMh9CPQvKs4gGH4fjqR5GiMBys9/');
      expect(await TAcontract.balanceOf(accounts[1].address, 1)).to.be.equal(10000);
    });
    it('User 2 unsuccessfully rents TA due to lower msg.value than price', async () => {
      await expect(
        TAcontract.connect(accounts[2]).rentTA(1, { value: ethers.utils.parseEther('0.5') })
      ).to.be.revertedWith('Not enough ETH was sent');
    });
    it('User 2 successfully rents TA', async () => {
      await TAcontract.connect(accounts[2]).rentTA(1, { value: ethers.utils.parseEther('1') });
      expect(await TAcontract.totalTARented(1)).to.be.equal(1);
      expect(await TAcontract.activeRent(accounts[2].address, 1)).to.be.equal(true);
      expect(await ethers.provider.getBalance(pool.address)).to.be.equal(ethers.utils.parseEther('0.2'));
    });
    it('User 2 unsuccessfully rents TA before expiry', async () => {
      await expect(
        TAcontract.connect(accounts[2]).rentTA(1, { value: ethers.utils.parseEther('1') })
      ).to.be.revertedWith('Each address can only rent 1 TA NFT at a time');
    });
    it('User 1 checks if TA of User 2 has expired. But it is not expired', async () => {
      TAcontract.connect(accounts[1]).checkIfTAisActive(1, accounts[2].address);
      expect(await TAcontract.activeRent(accounts[2].address, 1)).to.be.equal(true);
      expect(await TAcontract.totalTARented(1)).to.be.equal(1);
    });
    it('User 1 checks if TA of User 2 has expired. It is expired', async () => {
      await ethers.provider.send('evm_increaseTime', [704801]);
      await TAcontract.connect(accounts[1]).checkIfTAisActive(1, accounts[2].address);
      expect(await TAcontract.activeRent(accounts[2].address, 1)).to.be.equal(false);
      expect(await TAcontract.totalTARented(1)).to.be.equal(0);
    });
    it('User 3 attempts to enable TB mint but is not renting', async () => {
      await expect(
        TBcontract.connect(accounts[2]).enableTBMint(
          1,
          'Malaysian Fried Rice',
          'QmTmfTk7N4SBZu2WeUjtMh9CPQvKs4gGH4fjqR5GiMBys9',
          ethers.utils.parseEther('2'),
          15
        )
      ).to.be.revertedWith('This address is not renting this TA id');
    });
    it('User 3 sucessfully rents TA', async () => {
      await TAcontract.connect(accounts[3]).rentTA(1, { value: ethers.utils.parseEther('1') });
      expect(await TAcontract.totalTARented(1)).to.be.equal(1);
      expect(await TAcontract.activeRent(accounts[3].address, 1)).to.be.equal(true);
      expect(await ethers.provider.getBalance(pool.address)).to.be.equal(ethers.utils.parseEther('0.4'));
    });
    it('User 3 attempts to enable TB mint but with wrong name', async () => {
      await expect(
        TBcontract.connect(accounts[3]).enableTBMint(
          1,
          'Malaysian Rice',
          'QmTmfTk7N4SBZu2WeUjtMh9CPQvKs4gGH4fjqR5GiMBys9',
          ethers.utils.parseEther('2'),
          15
        )
      ).to.be.revertedWith('TA name must be contained in TB name');
    });
    it('User 3 successfully enables TB', async () => {
      await TBcontract.connect(accounts[3]).enableTBMint(
        1,
        'Malaysian Fried Rice',
        'QmTmfTk7N4SBZu2WeUjtMh9CPQvKs4gGH4fjqR5GiMBys9',
        ethers.utils.parseEther('2'),
        15
      );
    });
    it('User 3 tries to register with same name or metadata twice but fails', async () => {
      await expect(
        TBcontract.connect(accounts[3]).enableTBMint(1, 'Malaysian Fried Rice', '', ethers.utils.parseEther('2'), 15)
      ).to.be.revertedWith('Each name can only be minted once');
      await expect(
        TBcontract.connect(accounts[3]).enableTBMint(
          1,
          'Seafood Fried Rice',
          'QmTmfTk7N4SBZu2WeUjtMh9CPQvKs4gGH4fjqR5GiMBys9',
          ethers.utils.parseEther('2'),
          15
        )
      ).to.be.revertedWith('Each metadataALink can only be minted once');
    });
    it('User 4 tries to mint TB that is not enabled', async () => {
      await expect(TBcontract.connect(accounts[4]).mintTB(2, 3)).to.be.revertedWith('This TB is not available to mint');
    });
    it('User 4 tries to mint TB that is enabled but without enough ETH', async () => {
      await expect(TBcontract.connect(accounts[4]).mintTB(1, 3)).to.be.revertedWith('Not enough ETH was sent');
    });
    it('User 4 successfully mints TB', async () => {
      await TBcontract.connect(accounts[4]).mintTB(1, 3, { value: ethers.utils.parseEther('6') });
      expect(await TBcontract.balanceOf(accounts[4].address, 1)).to.be.equal(3);
      expect(await ethers.provider.getBalance(pool.address)).to.be.equal(ethers.utils.parseEther('1'));
    });
    it('User 4 tries to list for sale. Fails because it does not possess the NFT', async () => {
      TBcontract.connect(accounts[4]).setApprovalForAll(marketplace.address, true);
      await expect(
        marketplace.connect(accounts[4]).listForSale(10, 5, ethers.utils.parseEther('10'))
      ).to.be.revertedWith('User does not own enough tokens');
    });
    it('User 4 sucessfully lists for sale', async () => {
      await marketplace.connect(accounts[4]).listForSale(1, 3, ethers.utils.parseEther('10'));
    });
    it('User 5 tries to buy. But there is not enought ETH', async () => {
      TBcontract.connect(accounts[5]).setApprovalForAll(marketplace.address, true);
      await expect(
        marketplace.connect(accounts[5]).buyTB(1, { value: ethers.utils.parseEther('9') })
      ).to.be.revertedWith('Not enough ETH');
    });
    it('User 5 successfully buys', async () => {
      await marketplace.connect(accounts[5]).buyTB(1, { value: ethers.utils.parseEther('10') });
      expect(await TBcontract.balanceOf(accounts[5].address, 1)).to.be.equal(3);
      expect(await ethers.provider.getBalance(pool.address)).to.be.equal(ethers.utils.parseEther('1.25'));
    });
    it('User 5 tries to buy. But the item was already sold', async () => {
      await expect(
        marketplace.connect(accounts[5]).buyTB(1, { value: ethers.utils.parseEther('10') })
      ).to.be.revertedWith('The offer is no longer in the market');
    });

    // Staking and Rewards Part

    it('User 5 successfully stakes 1 NFT', async () => {
      TBcontract.connect(accounts[5]).setApprovalForAll(pool.address, true);
      await pool.connect(accounts[5]).stakeNFT(1, 1);
      expect(await pool.lastInflow()).to.be.equal(4);
      expect(await pool.tokensStaked()).to.be.equal(1);
      expect(await pool.accumulatedRewardsPerShare()).to.be.equal(0);
    });
    it('1st Inflow occurs - User 6 successfully mints TB', async () => {
      await TBcontract.connect(accounts[6]).mintTB(1, 5, { value: ethers.utils.parseEther('10') });
      expect(await TBcontract.balanceOf(accounts[6].address, 1)).to.be.equal(5);
      expect(await ethers.provider.getBalance(pool.address)).to.be.equal(ethers.utils.parseEther('2.25'));

      expect(await pool.lastInflow()).to.be.equal(5);
      expect(await pool.tokensStaked()).to.be.equal(1);
      expect(await pool.accumulatedRewardsPerShare()).to.be.equal(ethers.utils.parseEther('1'));
    });
    it('User 6 successfully stakes 2 NFT', async () => {
      TBcontract.connect(accounts[6]).setApprovalForAll(pool.address, true);
      await pool.connect(accounts[6]).stakeNFT(1, 2);
      expect(await pool.lastInflow()).to.be.equal(5);
      expect(await pool.tokensStaked()).to.be.equal(3);
      expect(await pool.accumulatedRewardsPerShare()).to.be.equal(ethers.utils.parseEther('1'));
    });
    it('2nd Inflow occurs - User 7 successfully mints TB', async () => {
      await TBcontract.connect(accounts[7]).mintTB(1, 15, { value: ethers.utils.parseEther('30') });
      expect(await TBcontract.balanceOf(accounts[7].address, 1)).to.be.equal(15);
      expect(await ethers.provider.getBalance(pool.address)).to.be.equal(ethers.utils.parseEther('5.25'));
      expect(await pool.lastInflow()).to.be.equal(6);
      expect(await pool.tokensStaked()).to.be.equal(3);
      expect(await pool.accumulatedRewardsPerShare()).to.be.equal(ethers.utils.parseEther('2'));
    });
    it('User 5 harvests its rewards', async () => {
      await pool.connect(accounts[5]).harvestRewards();
      expect(await pool.lastInflow()).to.be.equal(6);
      expect(await pool.tokensStaked()).to.be.equal(3);
      expect(await pool.accumulatedRewardsPerShare()).to.be.equal(ethers.utils.parseEther('2'));
      expect(await ethers.provider.getBalance(pool.address)).to.be.equal(ethers.utils.parseEther('3.25'));
    });
    it('3rd Inflow occurs - User 7 successfully mints TB', async () => {
      await TBcontract.connect(accounts[7]).mintTB(1, 15, { value: ethers.utils.parseEther('30') });
      expect(await TBcontract.balanceOf(accounts[7].address, 1)).to.be.equal(30);
      expect(await ethers.provider.getBalance(pool.address)).to.be.equal(ethers.utils.parseEther('6.25'));
      expect(await pool.lastInflow()).to.be.equal(7);
      expect(await pool.tokensStaked()).to.be.equal(3);
      expect(await pool.accumulatedRewardsPerShare()).to.be.equal(ethers.utils.parseEther('3'));
    });
    it('User 5 harvests its rewards', async () => {
      await pool.connect(accounts[5]).harvestRewards();
      expect(await pool.lastInflow()).to.be.equal(7);
      expect(await pool.tokensStaked()).to.be.equal(3);
      expect(await pool.accumulatedRewardsPerShare()).to.be.equal(ethers.utils.parseEther('3'));
      expect(await ethers.provider.getBalance(pool.address)).to.be.equal(ethers.utils.parseEther('5.25'));
    });
    it('User 5 fails to withdraws due to error in tbIDs introduction', async () => {
      const withdraw5_ids = [1];
      const withdraw5_qty = [2];
      await expect(pool.connect(accounts[5]).withdraw(withdraw5_ids,withdraw5_qty)).to.be.revertedWith('Quantity was wrongly introduced');
    });
    it('User 5 successfully withdraws', async () => {
      expect(await pool.connect(accounts[5]).depositsMade(accounts[5].address, 1)).to.be.equal(1);
      expect(await TBcontract.balanceOf(accounts[5].address, 1)).to.be.equal(2);
      expect(await pool.tokensStaked()).to.be.equal(3);

      const withdraw5_ids = [1];
      const withdraw5_qty = [1];
      await pool.connect(accounts[5]).withdraw(withdraw5_ids,withdraw5_qty);

      expect(await pool.connect(accounts[5]).depositsMade(accounts[5].address, 1)).to.be.equal(0);
      expect(await TBcontract.balanceOf(accounts[5].address, 1)).to.be.equal(3);
      expect(await pool.tokensStaked()).to.be.equal(2);
      expect(await ethers.provider.getBalance(pool.address)).to.be.equal(ethers.utils.parseEther('5.25'));
    });
  });
});
