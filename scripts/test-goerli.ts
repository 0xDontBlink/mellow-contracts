import { ethers } from 'hardhat';
import { MellowBits } from '../typechain-types';
import { ContractRunner } from 'ethers';

async function main() {
  const bits = await ethers.getContractAt(
    'MellowBits',
    '0x2adB43bab5e8304EDdE2fE93FaBC4eD8FBdCEd05'
  );

  const [deployer] = await ethers.getSigners();

  await purchaseBits(bits, deployer.address, deployer, 1000);
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
  console.log(buy);
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
