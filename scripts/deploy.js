// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  // const Greeter = await hre.ethers.getContractFactory("Greeter");
  // const greeter = await Greeter.deploy("Hello, Hardhat!");
  // await greeter.deployed();
  // console.log("Greeter deployed to:", greeter.address);

  const ExchangeFactory = await hre.ethers.getContractFactory("ExchangeFactory");
  const exchangeFactory = await ExchangeFactory.deploy();
  await exchangeFactory.deployed();
  console.log("ExchangeFactory deployed to:", exchangeFactory.address);

  const OpenLabNFT = await hre.ethers.getContractFactory("OpenLabNFT");
  const openLabNFT = await OpenLabNFT.deploy();
  await openLabNFT.deployed();
  console.log("OpenLabNFT deployed to:", openLabNFT.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
