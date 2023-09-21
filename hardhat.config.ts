import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import '@openzeppelin/hardhat-upgrades';
import '@nomiclabs/hardhat-ganache';

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: '0.8.20',
        settings: {
          evmVersion: 'paris',
        },
      },
    ],
  },
  networks: {
    hardhat: {
      mining: {
        auto: true,
        interval: 10000,
      },
    },
    mellowtestnet: {
      url: 'https://localtestnet.mellow.to',
    },
    basegoerli: {
      url: 'https://goerli.base.org',
      gasPrice: 50000000000,
      accounts: [
        '0babf5cf9d95db8813026cd4a0a6238542a7fed61fc48b979de41dcddf3e33fe',
      ],
    },
  },
  etherscan: {
    apiKey: {
      'base-goerli': 'PLACEHOLDER_STRING',
    },
    customChains: [
      {
        network: 'base-goerli',
        chainId: 84531,
        urls: {
          apiURL: 'https://api-goerli.basescan.org/api',
          browserURL: 'https://goerli.basescan.org',
        },
      },
    ],
  },
};

export default config;
