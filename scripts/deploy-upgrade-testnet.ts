import { ethers, upgrades } from 'hardhat';
import { MellowBits } from '../typechain-types';
import { ContractRunner } from 'ethers';

async function main() {
  const MELLOW_FEE_ADDRESS = '0x6d475839B944cb4c6e7d7e21DD78eBCC4E4C9310';

  const bitsFactory = await ethers.getContractFactory('MellowBits');
  console.log('Deploying Bits Factiory...');
  const bits = await upgrades.deployProxy(bitsFactory);
  await bits.waitForDeployment();

  console.log(await bits.getAddress());
  //   console.log(await bitsFactory.getDeployTransaction());

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
  const delta = ethers.parseEther('0.0000000005'); //0.0000000005
  const creatorFee = ethers.parseEther('0.04'); //%
  const mellowFee = ethers.parseEther('0.02'); //%
  const reflectionFee = ethers.parseEther('0.04'); //%

  await bits.setDeltaAmount(delta);
  await bits.setCreatorFeePercent(creatorFee);
  await bits.setMellowFeePercent(mellowFee);
  await bits.setReflectionFeePercent(reflectionFee);
  // Set fee distributor address
  await bits.setFeeDistributor(feeDistributorAddress);
  await bits.setMellowFeeAddress(MELLOW_FEE_ADDRESS);
  await bits.setFeeReader(feeReaderAddress);

  // const [owner, second] = await ethers.getSigners();

  // const accounts = await ethers.getSigners();
  // const ELON = accounts[3];
  // const ADDO = accounts[4];

  // const allUsers = [ELON, ADDO];

  // const numberToLoop = 10;
  // await purchaseBits(bitsFactory.attach(bits), owner.address, owner, 1);
  // await purchaseBits(bits, second.address, second, 1);

  //   for (let index = 0; index < 3; index++) {
  //     const inputValue2 = await bits.getBuyPriceAfterFee(
  //       accounts[0].address,
  //       1000
  //     );
  //     const buy2 = await bits.buyBits(accounts[0].address, 1000, {
  //       value: inputValue2,
  //     });
  //   }
  //   for (var demoUser of allUsers) {
  //     //Buy 10,000 of each user
  //     for (var buyAll of allUsers) {
  //       await purchaseBits(
  //         bits,
  //         buyAll.address,
  //         demoUser,
  //         randomInt(12500, 20000)
  //       );
  //     }
  //   }
  //   for (let i = 0; i < 300; i++) {
  //     const buyer = allUsers[randomInt(0, allUsers.length - 1)];
  //     const creator = allUsers[randomInt(0, allUsers.length - 1)];
  //     const ran = randomInt(0, 10);
  //     if (ran >= 7) {
  //       await sellBits(bits, creator.address, buyer, randomInt(50, 5000));
  //     } else {
  //       await purchaseBits(bits, creator.address, buyer, randomInt(50, 5000));
  //     }
  //   }
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
