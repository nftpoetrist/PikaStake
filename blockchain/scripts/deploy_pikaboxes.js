const hre = require("hardhat");

async function main() {
  const PikaBoxes = await hre.ethers.getContractFactory("PikaBoxes");
  const pikaBoxes = await PikaBoxes.deploy();
  await pikaBoxes.waitForDeployment();
  const addr = await pikaBoxes.getAddress();
  console.log("PikaBoxes deployed to:", addr);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
