const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);

  // Mevcut PikaUSDC adresini kullan
  const PIKAUSDC_ADDRESS = process.env.PIKAUSDC_ADDRESS;

  console.log("\nPikaMon deploy ediliyor (yeni kartlarla)...");
  const PikaMon = await ethers.getContractFactory("PikaMon");
  const pikaMon = await PikaMon.deploy(PIKAUSDC_ADDRESS);
  await pikaMon.waitForDeployment();
  const pikaMonAddress = await pikaMon.getAddress();

  console.log("✅ Yeni PikaMon adresi:", pikaMonAddress);
  console.log("\nindex.html ve .env dosyalarında PIKAMON_ADDR'i bu adresle güncelle!");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
