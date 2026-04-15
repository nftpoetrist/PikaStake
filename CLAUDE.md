# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PikaStake is a staking + NFT minting DApp on Arc Testnet (Chain ID: 5042002). Users stake USDC to earn pUSDC, then burn pUSDC to mint Pokémon NFT cards. The UI language is **English**.

---

## The Active Website

**The main site is `index.html`** at the project root — a standalone HTML/CSS/JS file served directly in the browser (no build step). This is what runs at `localhost:3000` (or opened directly).

The `pikastake/` Next.js app is a **separate, older prototype** — do not confuse the two. All UI work happens in `index.html`.

---

## Structure

```
PikaStake/
├── index.html           # ← Active website (HTML/CSS/JS + ethers.js)
├── nft/                 # NFT card images (12 cards total)
├── blockchain/          # Hardhat smart contracts
│   ├── contracts/
│   │   ├── PikaUSDC.sol
│   │   ├── PikaStake.sol
│   │   └── PikaMon.sol
│   ├── scripts/
│   │   ├── deploy_all.js        # Deploy all 3 contracts from scratch
│   │   └── deploy_pikamon.js    # Redeploy only PikaMon (keeps existing PikaUSDC/PikaStake)
│   ├── hardhat.config.js
│   └── .env                     # Private key + deployed contract addresses
└── pikastake/           # Legacy Next.js prototype (not the active site)
```

---

## Blockchain Commands

```bash
cd blockchain
npm run compile                                              # Compile Solidity
npx hardhat run scripts/deploy_all.js --network arcTestnet  # Deploy everything fresh
npx hardhat run scripts/deploy_pikamon.js --network arcTestnet  # Redeploy PikaMon only
```

After redeploying PikaMon, update `PIKAMON_ADDR` in `index.html` and `PIKAMON_ADDRESS` in `blockchain/.env`.

---

## Smart Contract Architecture

| Contract | Type | Role |
|----------|------|------|
| `PikaUSDC.sol` | ERC20Burnable | Reward token; only PikaStake can mint |
| `PikaStake.sol` | Custom | Accepts staked USDC, emits pUSDC at configurable APD (default 200% APD) |
| `PikaMon.sol` | ERC1155 | 12 NFT cards; minted by burning pUSDC; max 2 per wallet enforced on-chain; `addCard()` allows adding new cards without redeployment |

**Reward formula:** `(stakedAmount * SCALE * timeElapsedSeconds * dailyMultiplier) / (86400 * 100)`
*(SCALE = 1e12 — USDC is 6 decimals, pUSDC is 18 decimals)*

**Terminology:** Always use **APD** (not APY) throughout the UI.

**PikaMon cards (contract IDs 1–12):**
| ID | Name | Price | Supply |
|----|------|-------|--------|
| 1 | Enchanted Ribbon Sylveon | 195 pUSDC | 4,444 |
| 2 | Golden Jewel Pikachu | 175 pUSDC | 5,555 |
| 3 | Mystical Crown Espeon | 155 pUSDC | 5,555 |
| 4 | Prismatic Power Pikachu | 130 pUSDC | 7,300 |
| 5 | Verdant Guardian Leafeon | 115 pUSDC | 8,400 |
| 6 | StormRage Pikachu | 85 pUSDC | 10,000 |
| 7 | Nature's Shelter Pikachu | 195 pUSDC | 4,444 |
| 8 | Prismatic Bloom Ivysaur | 175 pUSDC | 5,555 |
| 9 | Electric Bond Pachirisu | 155 pUSDC | 5,555 |
| 10 | Hearth Glow Vulpix | 130 pUSDC | 7,300 |
| 11 | Sunlit Alley Litleo | 115 pUSDC | 8,400 |
| 12 | Midnight Meteor Helioptile | 85 pUSDC | 10,000 |

**Deployed addresses (Arc Testnet):**
- USDC (ERC20, 6 dec): `0x3600000000000000000000000000000000000000`
- PikaUSDC: `0x940dA31Fcc2c678E9B53217C9d9bAc29e15c70E7`
- PikaStake: `0x57bf29eDF062A617FAC74Fde4D77Ec04fF809B6B`
- PikaMon: `0x98A9d9E580582Ac9e24f570bFBb09C3929c3cD92`

**Deployer wallet:** `0xd76B24F43bCF5C3fFe09906A7414CD4D02EA7cDe`

---

## index.html Architecture

Single-file app using ethers.js v6 (CDN). Key sections inside `<script>`:

**Constants:** `STAKE_ADDR`, `PUSDC_ADDR`, `PIKAMON_ADDR`, `MAX_PER_WALLET = 2`

**JS card ID mapping:** `NFT_CARDS[i]` (JS index 0–11) maps to contract card ID `i+1` (1–12).

**Mint flow in `doMint()`:**
1. Parallel `Promise.all([getCard(), balanceOf(), allowance()])` for speed
2. Read actual price from contract via `getCard(contractId)` — never use frontend price for approval
3. Check `balanceOf` to enforce 2/wallet limit
4. `approve` pUSDC → `mintCard(contractId)`

**Error handling:** `parseError(e)` maps all contract/wallet errors to user-friendly English messages.

**Key UI sections:**
- Floating glass navbar (`position: absolute`, not fixed — scrolls with page)
- Staking panel (`.card`) — stake/withdraw/claim tabs
- NFT mint panel (`.mint-panel`) — 6×2 grid (12 cards), select card → MINT bar at bottom
- My Profile panel (`#profileOverlay`) — shows owned NFTs in 6-column grid, editable nickname (saved to localStorage), no wallet address or pUSDC balance shown
- `selectNft(id)` / `updateSlotState(id, owned)` / `checkMintedCards()` manage mint UI state

**Beam effect:** Conic-gradient animated beam on `.nft-slot:hover` and profile cards. RAF loop starts only on `mouseenter` of nftGrid or when profile is open — stops on `mouseleave` (if profile closed) to avoid CPU waste.

**Connect wallet:**
- Wallet order: MetaMask, Phantom, OKX, Backpack, Trust, Rainbow, Keplr
- Nightly wallet is blocklisted (`WALLET_BLOCKLIST`)
- `eth_requestAccounts` runs BEFORE `switchChain` (required for Phantom/Trust)
- `switchChainWithProvider` catches ALL errors (except 4001) and tries `wallet_addEthereumChain` as fallback
- `eth_requestAccounts` has 30s timeout; `switchChain` has 15s

**Nickname:** `loadNick()` / `startNickEdit()` / `saveNick()` — stored in `localStorage` key `pikaStakeNick`. Shows input field directly if no nickname saved yet.

---

## Arc Testnet

- Chain ID: `5042002`
- RPC: `https://5042002.rpc.thirdweb.com`
- Block explorer: `https://testnet.arcscan.app`
- Configured in `blockchain/hardhat.config.js` and `index.html` constants
