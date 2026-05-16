const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);

  console.log("\nPikaCreate deploy ediliyor...");
  const PikaCreate = await ethers.getContractFactory("PikaCreate");
  const pikaCreate = await PikaCreate.deploy();
  await pikaCreate.waitForDeployment();
  const pikaCreateAddress = await pikaCreate.getAddress();

  console.log("✅ PikaCreate adresi:", pikaCreateAddress);
  console.log("\nindex.html dosyasında PIKACREATE_ADDR sabitini bu adresle güncelle!");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
