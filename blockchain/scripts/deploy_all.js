const { ethers } = require("hardhat");

const USDC_ADDRESS = "0x3600000000000000000000000000000000000000"; // Arc Testnet USDC

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploy yapan adres:", deployer.address);

  // ─── 1. PikaUSDC deploy et ───────────────────────────
  console.log("\n1. PikaUSDC deploy ediliyor...");
  const PikaUSDC = await ethers.getContractFactory("PikaUSDC");
  const pikaUSDC = await PikaUSDC.deploy();
  await pikaUSDC.waitForDeployment();
  const pikaUSDCAddress = await pikaUSDC.getAddress();
  console.log("✅ PikaUSDC adresi:", pikaUSDCAddress);

  // ─── 2. PikaStake deploy et ──────────────────────────
  console.log("\n2. PikaStake deploy ediliyor...");
  const PikaStake = await ethers.getContractFactory("PikaStake");
  const pikaStake = await PikaStake.deploy(pikaUSDCAddress, USDC_ADDRESS);
  await pikaStake.waitForDeployment();
  const pikaStakeAddress = await pikaStake.getAddress();
  console.log("✅ PikaStake adresi:", pikaStakeAddress);

  // ─── 3. PikaMon deploy et ────────────────────────────
  console.log("\n3. PikaMon deploy ediliyor...");
  const PikaMon = await ethers.getContractFactory("PikaMon");
  const pikaMon = await PikaMon.deploy(pikaUSDCAddress);
  await pikaMon.waitForDeployment();
  const pikaMonAddress = await pikaMon.getAddress();
  console.log("✅ PikaMon adresi:", pikaMonAddress);

  // ─── 4. PikaUSDC'ye staking kontratini minter yap ───
  console.log("\n4. Staking kontratiyla minter olarak ayarlaniyor...");
  const tx = await pikaUSDC.setMinter(pikaStakeAddress);
  await tx.wait();
  console.log("✅ Minter ayarlandi!");

  // ─── SONUC ───────────────────────────────────────────
  console.log("\n========================================");
  console.log("🎉 TUM KONTRATLAR BASARIYLA DEPLOY EDILDI");
  console.log("========================================");
  console.log("PikaUSDC  :", pikaUSDCAddress);
  console.log("PikaStake :", pikaStakeAddress);
  console.log("PikaMon   :", pikaMonAddress);
  console.log("========================================");
  console.log("\nBu adresleri index.html ve .env dosyasina kaydet!");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
