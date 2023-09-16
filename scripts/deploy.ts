import { ethers } from 'hardhat';
import { MellowBits } from '../typechain-types';
import { ContractRunner } from 'ethers';

async function main() {
  const deploymentAddress = '0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199';

  const bits = await ethers.deployContract('MellowBits');
  await bits.waitForDeployment();
  console.log('BitsContract deployed: ' + (await bits.getAddress()));

  const feeDistributor = await ethers.deployContract(
    'CumulativeFeeDistributor'
  );
  await feeDistributor.waitForDeployment();
  const feeDistributorAddress = await feeDistributor.getAddress();
  console.log('FeeDistributor deployed: ' + feeDistributorAddress);

  const feeReader = await ethers.deployContract('FeeReader');
  await feeReader.waitForDeployment();
  const feeReaderAddress = await feeReader.getAddress();
  console.log('FeeReader deployed: ' + feeReaderAddress);

  //Set BITS fee and delta params
  const delta = ethers.parseEther('0.000000005'); //0.0000000006
  const creatorFee = ethers.parseEther('0.02'); //%
  const mellowFee = ethers.parseEther('0.02'); //%
  const reflectionFee = ethers.parseEther('0.02'); //%

  await bits.setDeltaAmount(delta);
  await bits.setCreatorFeePercent(creatorFee);
  await bits.setMellowFeePercent(mellowFee);
  await bits.setReflectionFeePercent(reflectionFee);
  // Set fee distributor address
  await bits.setFeeDistributor(feeDistributorAddress);
  await bits.setMellowFeeAddress(deploymentAddress);
  await bits.setFeeReader(feeReaderAddress);

  const [owner, second] = await ethers.getSigners();

  const accounts = await ethers.getSigners();
  const numberToLoop = 10;
  // await purchaseBits(bits, owner.address, owner, 1);
  // await purchaseBits(bits, second.address, second, 1);

  // 1000 * 10
  for (let i = 0; i < 10; i++) {
    // const account = accounts[randomInt(3, numberToLoop)];
    // await purchaseBits(bits, owner.address, account, 1000);
    // console.log(creatorFee);
    // console.log(
    //   'Balance before ' + (await ethers.provider.getBalance(account))
    // );
    // console.log(
    //   'Mellow Balance: ' +
    //     (await ethers.provider.getBalance(feeDistributorAddress))
    // );
    // await purchaseBits(bits, owner.address, account, 1000);
    // console.log(
    //   'Balance after buy ' + (await ethers.provider.getBalance(account))
    // );
    // console.log(
    //   'Mellow Balance: ' +
    //     (await ethers.provider.getBalance(feeDistributorAddress))
    // );
    // await sellBits(bits, owner.address, account, 1000);
    // console.log(
    //   'Balance after sell ' + (await ethers.provider.getBalance(account))
    // );
    // console.log(
    //   'Mellow Balance: ' +
    //     (await ethers.provider.getBalance(feeDistributorAddress))
    // );
    // await purchaseBits(bits, owner.address, account, 1000);
    // await purchaseBits(bits, owner.address, account, 1000);
    // await purchaseBits(bits, owner.address, account, 1000);
    // await purchaseBits(bits, owner.address, account, 1000);
    // await purchaseBits(bits, owner.address, account, 1000);
    // await purchaseBits(bits, owner.address, account, 1000);
    // await purchaseBits(bits, owner.address, account, 1000);
    // await purchaseBits(bits, owner.address, account, 500);
    // await purchaseBits(bits, owner.address, account, randomInt(50, 300));
    // await sellBits(bits, owner.address, account, randomInt(50, 500));
    // await purchaseBits(bits, owner.address, account, randomInt(50, 300));
    // await sellBits(bits, owner.address, account, randomInt(50, 300));
  }
}

function randomInt(min: number, max: number) {
  // min and max included
  return Math.floor(Math.random() * (max - min + 1) + min);
}

const purchaseBits = async (
  bits: MellowBits,
  creator: string,
  from: ContractRunner,
  amount: number
) => {
  const inputValue = await bits.getBuyPriceAfterFee(creator, amount);
  console.log(inputValue);
  const buy = await bits.connect(from).buyBits(creator, amount, {
    value: inputValue,
  });
};

const sellBits = async (
  bits: MellowBits,
  creator: string,
  from: ContractRunner,
  amount: number
) => {
  const outputValue = await bits.getSellPriceAfterFee(creator, amount);
  console.log(outputValue);
  const sell = await bits.connect(from).sellBits(creator, amount);
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// console.log(ethers.id('buyBits(address,uint256)').substring(0, 10));
// console.log(ethers.id('sellBits(address,uint256)').substring(0, 10));
