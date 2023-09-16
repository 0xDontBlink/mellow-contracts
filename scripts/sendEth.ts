import { ethers } from 'hardhat';

async function main() {
  const [owner, second] = await ethers.getSigners();

  await owner.sendTransaction({
    to: '0xadc19a4a7038d739c22ef05bfa0568665050f56e',
    value: ethers.parseEther('500'), // Sends exactly 1.0 ether
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// console.log(ethers.id('buyBits(address,uint256)').substring(0, 10));
// console.log(ethers.id('sellBits(address,uint256)').substring(0, 10));
