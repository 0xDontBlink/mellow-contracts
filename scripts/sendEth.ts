import { ethers } from 'hardhat';

async function main() {
  const [owner, second] = await ethers.getSigners();

  await owner.sendTransaction({
    to: '0x583849c54a476057c0bc5e04ebc24432d154d447',
    value: ethers.parseEther('4000'), // Sends exactly 1.0 ether
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
