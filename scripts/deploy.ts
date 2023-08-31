import { ethers } from 'hardhat';
import { MellowBits } from '../typechain-types';

async function main() {
  const deploymentAddress = '0x000000000000000000000000000000000000dead';

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
  const delta = ethers.parseEther('0.001'); //0.000006
  const creatorFee = ethers.parseEther('0.2'); //%
  const mellowFee = ethers.parseEther('0.2'); //%
  const reflectionFee = ethers.parseEther('0.2'); //%

  await bits.setDeltaAmount(delta);
  await bits.setCreatorFeePercent(creatorFee);
  await bits.setMellowFeePercent(mellowFee);
  await bits.setReflectionFeePercent(reflectionFee);
  // Set fee distributor address
  await bits.setFeeDistributor(feeDistributorAddress);
  await bits.setMellowFeeAddress(deploymentAddress);
  await bits.setFeeReader(feeReaderAddress);

  const [owner] = await ethers.getSigners();

  await purchaseBits(bits, owner.address, 1);
  await purchaseBits(bits, owner.address, 3);
  await sellBits(bits, owner.address, 1);
  await purchaseBits(bits, owner.address, 5);
  await sellBits(bits, owner.address, 3);
}

const purchaseBits = async (
  bits: MellowBits,
  address: string,
  amount: number
) => {
  const inputValue = await bits.getBuyPriceAfterFee(address, amount);
  const buy = await bits.buyBits(address, amount, {
    value: inputValue,
  });
};

const sellBits = async (bits: MellowBits, address: string, amount: number) => {
  const inputValue = await bits.getSellPriceAfterFee(address, amount);
  console.log(inputValue);
  const buy = await bits.sellBits(address, amount, {
    value: inputValue,
  });
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// console.log(ethers.id('buyBits(address,uint256)').substring(0, 10));
// console.log(ethers.id('sellBits(address,uint256)').substring(0, 10));
