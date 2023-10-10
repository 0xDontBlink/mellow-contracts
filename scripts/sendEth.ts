import { ethers } from 'hardhat';

async function main() {
  const [owner, second, third] = await ethers.getSigners();

  await owner.sendTransaction({
    to: '0x597c09bc8da1f5057ff5c3e4a52caf7011b0d648',
    value: ethers.parseEther('9999'), // Sends exactly 1.0 ether
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
