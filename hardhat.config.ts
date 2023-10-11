import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import '@openzeppelin/hardhat-upgrades';
import '@nomiclabs/hardhat-ganache';
import '@nomicfoundation/hardhat-ledger';

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
      gasPrice: 694201337,
    },
    basegoerli: {
      url: 'https://goerli.base.org',
      gasPrice: 694201337,
      accounts: [
        '0babf5cf9d95db8813026cd4a0a6238542a7fed61fc48b979de41dcddf3e33fe',
      ],
    },
    base: {
      url: 'https://mainnet.base.org',
      gasPrice: 694201337,
      ledgerAccounts: ['0x3f83D44e7c6EF5eb1D3F096f4cb3955AbE92Cf55'],
    },
  },
  etherscan: {
    apiKey: {
      'base-goerli': 'PLACEHOLDER_STRING',
      base: 'JFCM6J2KRE5KZQAA3S8N29XH37ZZDEQH8J',
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
