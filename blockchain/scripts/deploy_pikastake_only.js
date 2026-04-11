const { ethers } = require("hardhat");

const USDC_ADDRESS    = "0x3600000000000000000000000000000000000000";
const PIKAUSDC_ADDRESS = process.env.PIKAUSDC_ADDRESS; // sabit kalır

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploy yapan adres:", deployer.address);
  console.log("PikaUSDC (sabit)  :", PIKAUSDC_ADDRESS);

  // ─── PikaStake deploy et ─────────────────────
  console.log("\nPikaStake deploy ediliyor...");
  const PikaStake = await ethers.getContractFactory("PikaStake");
  const pikaStake = await PikaStake.deploy(PIKAUSDC_ADDRESS, USDC_ADDRESS);
  await pikaStake.waitForDeployment();
  const pikaStakeAddress = await pikaStake.getAddress();
  console.log("✅ Yeni PikaStake adresi:", pikaStakeAddress);

  // ─── PikaUSDC'nin minter'ını güncelle ────────
  console.log("\nMinter guncelleniyor...");
  const pikaUSDC = await ethers.getContractAt("PikaUSDC", PIKAUSDC_ADDRESS);
  const tx = await pikaUSDC.setMinter(pikaStakeAddress);
  await tx.wait();
  console.log("✅ Minter guncellendi!");

  console.log("\n========================================");
  console.log("Yeni PIKASTAKE_ADDRESS:", pikaStakeAddress);
  console.log("index.html ve .env dosyasini guncelle!");
  console.log("========================================");
}

main().catch((e) => { console.error(e); process.exit(1); });
