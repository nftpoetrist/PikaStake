require("dotenv").config();
const hre = require("hardhat");

async function main() {
  const PikaName = await hre.ethers.getContractFactory("PikaName");
  const pikaname = await PikaName.deploy();
  await pikaname.waitForDeployment();

  const addr = await pikaname.getAddress();
  console.log("PikaName deployed to:", addr);
  console.log("Update PIKANAME_ADDR in index.html and blockchain/.env");
}

main().catch((e) => { console.error(e); process.exit(1); });
