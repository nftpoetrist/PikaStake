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
├── pikacreate.html      # Redirect shim → index.html#/create (9-line file)
├── nft/                 # NFT card images (sylveon.png, pikachu-gold.png, etc.)
├── blockchain/          # Hardhat smart contracts
│   ├── contracts/
│   │   ├── PikaUSDC.sol
│   │   ├── PikaStake.sol
│   │   ├── PikaMon.sol
│   │   ├── PikaCreate.sol      # ERC721 — user-created custom NFTs
│   │   └── PikaName.sol        # ERC721 — .pika domain name service
│   ├── scripts/
│   │   ├── deploy_all.js
│   │   ├── deploy_pikamon.js
│   │   ├── deploy_pikacreate.js
│   │   └── deploy_pikaname.js
│   ├── hardhat.config.js
│   └── .env                     # Private key + deployed contract addresses
└── pikastake/           # Legacy Next.js prototype (not the active site)
```

---

## Blockchain Commands

```bash
cd blockchain
npm run compile                                                    # Compile Solidity
npx hardhat run scripts/deploy_all.js --network arcTestnet        # Deploy everything fresh
npx hardhat run scripts/deploy_pikamon.js --network arcTestnet    # Redeploy PikaMon only
npx hardhat run scripts/deploy_pikacreate.js --network arcTestnet # Redeploy PikaCreate only
npx hardhat run scripts/deploy_pikaname.js --network arcTestnet   # Redeploy PikaName only
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
| `PikaName.sol` | ERC721URIStorage | Pika Name Service — free .pika domain registration; ERC721 token per domain |

**PikaName domain rules:** lowercase letters, digits, hyphens only; 1–32 chars; unique per name; free to mint (no USDC cost). Key functions: `mint(string name)`, `isAvailable(string name) view`, `getOwnerDomains(address) view`.

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
- PikaName: `0x089D7b3CA59629F7364eE22F499Ef087a46f55cd` (deployed block: 37593339)

---

## index.html Architecture

Single-file app using ethers.js v6 (CDN). Key sections inside `<script>`:

**Constants:** `STAKE_ADDR`, `PUSDC_ADDR`, `PIKAMON_ADDR`, `PIKACREATE_ADDR`, `PIKANAME_ADDR`, `MAX_PER_WALLET = 2`

**SPA Routing:** `navigate(page)` switches between `stake`, `create`, `gallery`, `domain` pages via `display` toggling. Hash-based: `#/create`, `#/gallery`, `#/domain`.

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
- `pikacreate_nfts_${address.toLowerCase()}` — per-wallet minted NFT history `{ name, imageSrc, date }`. `imageSrc` is stored as **base64 data URL** (≤500 KB) for instant load; larger images fall back to IPFS URL.
- `pikagallery_cache` — global gallery cache `{ name, image, addr }`
- `LAST_WALLET_KEY` — last connected wallet rdns for auto-connect

**Image caching (`_toDataUrl`):** Converts IPFS URLs to base64 on first load and saves to localStorage. On `loadMintedNfts`, existing IPFS URL entries in cache are upgraded to base64 in the background.

**PikaDomain flow (`doPikaMint()`):**
1. Frontend validates name (lowercase/digits/hyphens, max 32 chars) before any contract call
2. Live availability check via `isAvailable()` with 500ms debounce — shows ✅ Free or ❌ Taken
3. On MINT: direct `PikaName.mint(name)` — no approve needed (free)
4. Toast notification on success; My Domains + Recent Mints auto-refresh
5. `loadPikaMyDomains()` called on wallet connect/disconnect/navigate; clears on disconnect
6. Recent Mints uses `totalSupply()` + `tokenIdToDomain(id)` + `ownerOf(id)` via `Promise.all` — NOT event `queryFilter` (too slow/unreliable on Arc). Shows newest first (iterates from `total` down to 1).
7. Both panels paginate at 7 items; Load More expands only the clicked panel (`align-items: start` on grid)

**Key UI sections:**
- Navbar: logo (left), PikaCreate/PikaGallery/PikaDomain btns (centered via `.nav-center` with `position:absolute; left:50%; transform:translateX(-50%)`), **single unified wallet button** (`#profileBtn`, right). The pUSDC balance pill has been removed from the navbar.
- `#profileBtn` — dual-purpose: shows `Connect Wallet` when disconnected (calls `openWalletModal`), shows `Arc + short address + avatar` when connected (calls `openProfile`). Do NOT add a separate connect button.
- Staking panel (`.card`) — stake/withdraw/claim tabs
- NFT mint panel (`.mint-panel`) — 6×2 grid "Genesis Collection", select card → MINT bar at bottom
- PikaCreate page — upload zone + `Your Minted NFTs` panel (3×2 grid, 6/page, height matches Create panel `--create-panel-h: 620px`)
- PikaGallery page — 6×2 grid, fixed `700px` height, all users' NFTs, 12/page, localStorage cache + parallel fetch. Loading overlay (`#galleryLoadingOverlay`) shown on first visit (empty cache).
- PikaDomain page — search/mint bar + two panels (Recent Mints left, My Domains right); CSS classes use `.pika-` prefix; panels use `min-height: 440px`, grid `align-items: start` so Load More only expands clicked panel.
- Profile overlay (`#profileOverlay`) — shows wallet stats, Genesis Collection NFTs, nickname editor. Has **Disconnect** button (`.profile-disconnect`) left of the close ✕ button.
- **Premium side cards (stake page only):** Two credit-card-style panels flank the staking card:
  - **Dark card** (right, `#pikaCreditWrap` / `.pikacredit-*`): brushed dark metal, silver bezel, shows live pUSDC balance + wallet address + "Pay on ARC". Updates via `fetchUser()`.
  - **Gold card** (left, `#pikaGoldWrap` / `.pikagold-*`): brushed gold metal, gold bezel, shows "Pay on ARC" centered.
  - Both are `position: absolute` inside the stake page (scroll-fixed to top, don't follow viewport). Size: 270×170px wrapper, internal 520×328px scaled at `scale(0.52)` with `transform-origin: top left`.
  - Positioning: `_alignSideCards()` runs after `initRouter()` via `requestAnimationFrame` and on `resize`. Uses `#mainCard` `getBoundingClientRect()` to place cards beside staking card with `_CARD_GAP = 48px`, vertically centered via `(cardRect.height - wrap.offsetHeight) / 2`.
  - 3D tilt on hover (`rotateY/rotateX` ±8°/6°). Hidden on screens ≤900px.
  - **Do NOT call `_alignSideCards()` before `initRouter()`** — the stake page is `display:none` until then and `getBoundingClientRect()` returns zeros.

**Connect wallet timeout:** `eth_requestAccounts` has 30s timeout; `switchChain` has 15s.

**MAX withdraw:** uses `ethers.formatUnits(myStaked, USDC_DEC)` directly — never read from UI text to avoid rounding errors.

---

## Known Issues / Fixed Bugs

- **MAX withdraw rounding bug (fixed):** `fmtN` rounds to 4 decimals; using UI text as amount could exceed on-chain balance. Now uses raw BigInt.
- **Auto-connect NFT load (fixed):** Both EIP-6963 and legacy paths call `loadMintedNfts()` + `loadCreatePageStats()` on reconnect.
- **Gallery parallel fetch:** NFTs fetched with `Promise.all` — not sequential.
- **Gallery img onload order (fixed):** `img.src` must be set AFTER `onload`/`onerror` handlers and after appending to DOM, otherwise cached images miss the event. 12-second fallback (`setTimeout`) forces visibility if IPFS is slow.
- **CSS animation CPU usage:** Never use `background-position` for animations — causes continuous repaints. Always use `transform` or `opacity` (GPU-accelerated via compositor).

---

## Arc Testnet

- Chain ID: `5042002`
- RPC: `https://5042002.rpc.thirdweb.com`
- Configured in `blockchain/hardhat.config.js` and `index.html` constants

---

## Skills

This project uses two skill packages that give Claude Code pre-loaded context for Arc and deployment.

### Circle Skills (Arc + USDC context)

Provides Claude Code with correct Arc Testnet chain ID, USDC contract addresses, wallet integration patterns, and USDC transfer logic — eliminates guessing and wrong-address mistakes.

**Install (run once in project root):**
```bash
npx skills add https://github.com/circlefin/skills
```
Select these when prompted:
- `use-arc` — Arc Testnet configuration and RPC details
- `use-usdc` — USDC contract addresses and transfer patterns

Scope: **Project** | Method: **Symlink** | Install find-skills: **Yes**

### Vercel Skills (deployment automation)

Lets Claude Code connect to Vercel, configure the project, and run deploys automatically — no manual deployment steps needed.

**Install (run once in project root):**
```bash
npx skills add vercel-labs/agent-skills
```
Select `deploy-to-vercel`. Authorize Vercel in the browser that opens (create a free account at vercel.com if needed).

### When to use
- Working with USDC transfers, Arc wallet connections, or any on-chain interaction → Circle Skills already loaded
- Deploying or redeploying the app → use Vercel Skills via Claude Code instead of manual `git push`
