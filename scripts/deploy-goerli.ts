import { ethers } from 'hardhat';
import { MellowBits } from '../typechain-types';
import { ContractRunner } from 'ethers';

async function main() {
  const deploymentAddress = '0x6d475839B944cb4c6e7d7e21DD78eBCC4E4C9310';

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
  const delta = ethers.parseEther('0.0000000006'); //0.0000000006
  const creatorFee = ethers.parseEther('0.04'); //%
  const reflectionFee = ethers.parseEther('0.04'); //%
  const mellowFee = ethers.parseEther('0.02'); //%

  await bits.setDeltaAmount(delta);
  await bits.setCreatorFeePercent(creatorFee);
  await bits.setMellowFeePercent(mellowFee);
  await bits.setReflectionFeePercent(reflectionFee);
  // Set fee distributor address
  await bits.setFeeDistributor(feeDistributorAddress);
  await bits.setMellowFeeAddress(deploymentAddress);
  await bits.setFeeReader(feeReaderAddress);

  // const [owner, second] = await ethers.getSigners();

  const [deployer] = await ethers.getSigners();

  await purchaseBits(bits, deployer.address, deployer, 1);
}
// 1000 * 10

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
