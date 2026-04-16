# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PikaStake is a staking + NFT minting DApp on Arc Testnet (Chain ID: 5042002). Users stake USDC to earn pUSDC, then burn pUSDC to mint Pokémon NFT cards. The UI language is **English**.

---

## The Active Website

**The main site is `index.html`** at the project root — a standalone HTML/CSS/JS file served directly in the browser (no build step). This is what runs at `localhost:3000` (or opened directly).

Deployed at: **https://pikastake-nine.vercel.app/** (auto-deploys on push to `main`)

The `pikastake/` Next.js app is a **separate, older prototype** — do not confuse the two. All UI work happens in `index.html`.

---

## Structure

```
PikaStake/
├── index.html           # ← Active website (HTML/CSS/JS + ethers.js)
├── nft/                 # NFT card images (sylveon.png, pikachu-gold.png, etc.)
├── blockchain/          # Hardhat smart contracts
│   ├── contracts/
│   │   ├── PikaUSDC.sol
│   │   ├── PikaStake.sol
│   │   ├── PikaMon.sol
│   │   └── PikaCreate.sol      # ERC721 — user-created custom NFTs
│   ├── scripts/
│   │   ├── deploy_all.js
│   │   ├── deploy_pikamon.js
│   │   └── deploy_pikacreate.js
│   ├── hardhat.config.js
│   └── .env                     # Private key + deployed contract addresses
└── pikastake/           # Legacy Next.js prototype (not the active site)
```

---

## Blockchain Commands

```bash
cd blockchain
npm run compile                                                   # Compile Solidity
npx hardhat run scripts/deploy_all.js --network arcTestnet       # Deploy everything fresh
npx hardhat run scripts/deploy_pikamon.js --network arcTestnet   # Redeploy PikaMon only
npx hardhat run scripts/deploy_pikacreate.js --network arcTestnet # Redeploy PikaCreate only
```

After redeploying, update the relevant `_ADDR` constant in `index.html` and `blockchain/.env`.

---

## Smart Contract Architecture

| Contract | Type | Role |
|----------|------|------|
| `PikaUSDC.sol` | ERC20Burnable | Reward token; only PikaStake can mint |
| `PikaStake.sol` | Custom | Accepts staked USDC value, emits pUSDC at 200% APD |
| `PikaMon.sol` | ERC1155 | 6 NFT cards (Genesis Collection); minted by burning pUSDC; max 2 per wallet |
| `PikaCreate.sol` | ERC721URIStorage | User-created custom NFTs; anyone can mint with image + name |

**Reward formula:** `(stakedAmount * SCALE * timeElapsedSeconds * dailyMultiplier) / (86400 * 100)`
*(SCALE = 1e12 — USDC is 6 decimals, pUSDC is 18 decimals. dailyMultiplier = 200 → 200% APD)*

**PikaMon cards (contract IDs 1–6) — "Genesis Collection":**
| ID | Name | Price | Supply |
|----|------|-------|--------|
| 1 | Enchanted Ribbon Sylveon | 195 pUSDC | 4,444 |
| 2 | Golden Jewel Pikachu | 175 pUSDC | 5,555 |
| 3 | Mystical Crown Espeon | 155 pUSDC | 5,555 |
| 4 | Prismatic Power Pikachu | 130 pUSDC | 7,300 |
| 5 | Verdant Guardian Leafeon | 115 pUSDC | 8,400 |
| 6 | StormRage Pikachu | 85 pUSDC | 10,000 |

**Deployed addresses (Arc Testnet):**
- USDC (ERC20, 6 dec): `0x3600000000000000000000000000000000000000`
- PikaUSDC: `0x940dA31Fcc2c678E9B53217C9d9bAc29e15c70E7`
- PikaStake: `0x57bf29eDF062A617FAC74Fde4D77Ec04fF809B6B`
- PikaMon: `0xFBF26c37F2e057A912af0aE65D80a35557C33839`
- PikaCreate: `0x960Da00dfC0670604a4331A5794c208B869b64DB`

---

## index.html Architecture

Single-file app using ethers.js v6 (CDN). Key sections inside `<script>`:

**Constants:** `STAKE_ADDR`, `PUSDC_ADDR`, `PIKAMON_ADDR`, `PIKACREATE_ADDR`, `MAX_PER_WALLET = 2`

**SPA Routing:** `navigate(page)` switches between `stake`, `create`, `gallery` pages via `display` toggling. Hash-based: `#/create`, `#/gallery`.

**JS card ID mapping:** `NFT_CARDS[i]` (JS index 0–5) maps to contract card ID `i+1` (1–6).

**Mint flow in `doMint()` (PikaMon):**
1. Read actual price from contract via `getCard(contractId)` — never use frontend price for approval
2. Check `balanceOf` to enforce 2/wallet limit
3. `approve` pUSDC → `mintCard(contractId)`

**PikaCreate flow in `doCreateMint()`:**
1. User selects image → pre-upload to IPFS starts immediately via `_preUploadedImageHash` / `_preUploadPromise`
2. On mint: use pre-uploaded hash if ready, otherwise upload now
3. Upload metadata JSON to IPFS → write `ipfs://` URI to chain via `PikaCreate.mint(tokenURI)`
4. Add to `Your Minted NFTs` panel and `PikaGallery` cache

**localStorage cache keys:**
- `pikacreate_nfts_${address.toLowerCase()}` — per-wallet minted NFT history `{ name, imageSrc, date }`
- `pikagallery_cache` — global gallery cache `{ name, image, addr }`
- `LAST_WALLET_KEY` — last connected wallet rdns for auto-connect

**Key UI sections:**
- Navbar: logo, PikaCreate btn (yellow), PikaGallery btn (yellow), pUSDC pill (white text), connect btn, My Profile btn
- Staking panel (`.card`) — stake/withdraw/claim tabs
- NFT mint panel (`.mint-panel`) — 3×2 grid "Genesis Collection", select card → MINT bar at bottom
- PikaCreate page — upload zone + `Your Minted NFTs` panel (4/page pagination, newest first)
- PikaGallery page — 5×2 grid, all users' NFTs, 10/page pagination, localStorage cache + parallel fetch

**Connect wallet timeout:** `eth_requestAccounts` has 30s timeout; `switchChain` has 15s.

**MAX withdraw:** uses `ethers.formatUnits(myStaked, USDC_DEC)` directly — never read from UI text to avoid rounding errors.

---

## Known Issues / Fixed Bugs

- **MAX withdraw rounding bug (fixed):** `fmtN` rounds to 4 decimals; using UI text as amount could exceed on-chain balance. Now uses raw BigInt.
- **Auto-connect NFT load (fixed):** Both EIP-6963 and legacy paths call `loadMintedNfts()` + `loadCreatePageStats()` on reconnect.
- **Gallery parallel fetch:** NFTs fetched with `Promise.all` — not sequential.

---

## Arc Testnet

- Chain ID: `5042002`
- RPC: `https://5042002.rpc.thirdweb.com`
- Configured in `blockchain/hardhat.config.js` and `index.html` constants
