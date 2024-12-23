require("@nomicfoundation/hardhat-toolbox");
// require("dotenv").config();

// /** @type import('hardhat/config').HardhatUserConfig */
// module.exports = {
//   solidity: "0.8.28",
//   networks: {
//     bsctestnet: {
//       url: BSC_TESTNET_RPC_URL,
//       accounts: [PRIVATE_KEY],
//     },
//   },
// };
module.exports = {
  solidity: {
    version: "0.8.20",
    include: ["./contracts/Whitelist.sol"]
  }
};
