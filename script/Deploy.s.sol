// SPDX-License-Identifier: MIT
// scripts/deploy_indietreat.js
const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying IndieTreat with account:", deployer.address);

  const paymentTokenAddress = "0xYOUR_OMN_TOKEN_ADDRESS"; // Replace with deployed token address

  const IndieTreat = await ethers.getContractFactory("IndieTreat");
  const checkout = await IndieTreat.deploy(paymentTokenAddress);

  await checkout.deployed();

  console.log("IndieTreat deployed to:", checkout.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});


/*

// scripts/deploy_token.js
const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying token with account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const initialSupply = ethers.utils.parseUnits("1000000", 18); // 1M tokens
  const Token = await ethers.getContractFactory("Optimona");
  const token = await Token.deploy(initialSupply);

  await token.deployed();

  console.log("Optimona token deployed to:", token.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

*/
