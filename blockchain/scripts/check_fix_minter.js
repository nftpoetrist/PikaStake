const { ethers } = require("hardhat");

const PUSDC_ABI  = ["function minter() view returns (address)", "function setMinter(address) external"];
const STAKE_ABI  = ["function getStakeInfo(address) view returns (uint256, uint256, uint256)"];

async function main() {
  const [deployer] = await ethers.getSigners();

  const PIKAUSDC_ADDRESS  = process.env.PIKAUSDC_ADDRESS;
  const PIKASTAKE_ADDRESS = process.env.PIKASTAKE_ADDRESS;

  if (!PIKAUSDC_ADDRESS || !PIKASTAKE_ADDRESS) {
    console.error("PIKAUSDC_ADDRESS or PIKASTAKE_ADDRESS missing from .env");
    process.exit(1);
  }

  console.log("Deployer:", deployer.address);
  console.log("PikaUSDC :", PIKAUSDC_ADDRESS);
  console.log("PikaStake:", PIKASTAKE_ADDRESS);
  console.log("");

  const pikaUSDC = new ethers.Contract(PIKAUSDC_ADDRESS, PUSDC_ABI, deployer);
  const pikaStake = new ethers.Contract(PIKASTAKE_ADDRESS, STAKE_ABI, deployer);

  // 1. Check current minter
  const currentMinter = await pikaUSDC.minter();
  console.log("Current minter :", currentMinter);
  console.log("Expected minter:", PIKASTAKE_ADDRESS);

  const minterOk = currentMinter.toLowerCase() === PIKASTAKE_ADDRESS.toLowerCase();
  console.log("Minter OK?", minterOk ? "✅ YES" : "❌ NO — will fix");
  console.log("");

  // 2. Fix if wrong
  if (!minterOk) {
    console.log("Setting minter to PikaStake…");
    const tx = await pikaUSDC.setMinter(PIKASTAKE_ADDRESS);
    await tx.wait();
    console.log("✅ Minter fixed! Tx:", tx.hash);
  } else {
    console.log("Minter is correct. The withdraw error has a different cause.");
    console.log("Check: does the user have a real stake on this contract?");
    console.log("Run: npx hardhat run scripts/check_fix_minter.js --network arcTestnet");
    console.log("And provide the user wallet address to check their stake.");
  }

  // 3. Check stake info of deployer (optional quick sanity check)
  try {
    const info = await pikaStake.getStakeInfo(deployer.address);
    console.log("\nDeployer stake info:");
    console.log("  stakedAmount :", ethers.formatUnits(info[0], 18), "ETH");
    console.log("  pendingReward:", ethers.formatUnits(info[1], 18), "pUSDC");
  } catch(e) {
    console.log("Could not read stake info:", e.message);
  }
}

main().catch((e) => { console.error(e); process.exit(1); });
