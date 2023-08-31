import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';

const config: HardhatUserConfig = {
  solidity: '0.8.20',
  networks: {
    hardhat: {
      mining: {
        auto: true,
        interval: 10000,
      },
    },
  },
};

export default config;
