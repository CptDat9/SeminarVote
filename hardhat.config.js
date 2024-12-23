require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();

module.exports = {
    solidity: "0.8.20",
    networks: {
        bsctestnet: {
            url: "https://data-seed-prebsc-1-s1.binance.org:8545",
            chainId: 97,
            accounts: [`0x${process.env.PRIVATE_KEY}`],
        },
    },
};
