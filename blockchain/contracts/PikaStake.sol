// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IPikaUSDC {
    function mint(address to, uint256 amount) external;
}

/**
 * @title PikaStake
 * @notice Kullanicilar USDC (6 decimal) yatirir, pUSDC (18 decimal) kazanir.
 *         Withdraw sadece USDC'yi geri verir, pUSDC ödüllerine dokunmaz.
 *         pUSDC yalnizca claimRewards() cagirildiginda cüzdana gönderilir.
 *         dailyMultiplier = 100 → %100 APD, 200 → %200 APD vb.
 */
contract PikaStake {
    using SafeERC20 for IERC20;

    IPikaUSDC public pikaUSDC;
    IERC20    public usdc;
    address   public owner;

    // USDC 6 decimal, pUSDC 18 decimal → fark 12 basamak
    uint256 private constant SCALE = 1e12;

    // APD carpani: 100 = %100/gun, 200 = %200 APD
    uint256 public dailyMultiplier = 200;

    struct StakeInfo {
        uint256 amount;             // Yatirilan USDC (6 decimal)
        uint256 lastClaimed;        // Son hesaplama timestamp
        uint256 accumulatedRewards; // Withdraw/stake sirasinda biriken pUSDC (mint edilmemis)
    }

    mapping(address => StakeInfo) public stakes;
    uint256 public totalStaked;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 reward);
    event MultiplierUpdated(uint256 oldValue, uint256 newValue);

    modifier onlyOwner() {
        require(msg.sender == owner, "Sadece owner");
        _;
    }

    constructor(address _pikaUSDC, address _usdc) {
        pikaUSDC = IPikaUSDC(_pikaUSDC);
        usdc     = IERC20(_usdc);
        owner    = msg.sender;
    }

    // ─────────────────────────────────────────
    //  APD ORANINI GUNCELLE (sadece owner)
    // ─────────────────────────────────────────
    function setDailyMultiplier(uint256 newMultiplier) external onlyOwner {
        require(newMultiplier > 0 && newMultiplier <= 10000, "Gecersiz carpan");
        emit MultiplierUpdated(dailyMultiplier, newMultiplier);
        dailyMultiplier = newMultiplier;
    }

    // ─────────────────────────────────────────
    //  USDC YATIR
    // ─────────────────────────────────────────
    function stake(uint256 amount) external {
        require(amount > 0, "Sifirdan fazla yatirmalisin");

        usdc.safeTransferFrom(msg.sender, address(this), amount);

        if (stakes[msg.sender].amount > 0) {
            // Mevcut stake varsa ödülleri kaydet ama MINT ETME
            _saveRewards(msg.sender);
        } else {
            stakes[msg.sender].lastClaimed = block.timestamp;
        }

        stakes[msg.sender].amount += amount;
        totalStaked += amount;

        emit Staked(msg.sender, amount);
    }

    // ─────────────────────────────────────────
    //  USDC GERI CEK — pUSDC ödüllerine dokunmaz
    // ─────────────────────────────────────────
    function withdraw(uint256 amount) external {
        StakeInfo storage info = stakes[msg.sender];
        require(info.amount > 0, "Yatirilan USDC bulunamadi");

        uint256 toWithdraw = (amount == 0 || amount >= info.amount)
            ? info.amount
            : amount;

        require(toWithdraw <= info.amount, "Yetersiz bakiye");

        // Ödülleri kaydet (accumulated'a ekle) ama MINT ETME
        _saveRewards(msg.sender);

        info.amount -= toWithdraw;
        totalStaked -= toWithdraw;

        if (info.amount == 0) {
            info.lastClaimed = 0;
            // accumulatedRewards sıfırlanmaz — kullanıcı hâlâ claim edebilir
        }

        usdc.safeTransfer(msg.sender, toWithdraw);

        emit Withdrawn(msg.sender, toWithdraw);
    }

    // ─────────────────────────────────────────
    //  SADECE ODULU CLAIM ET — pUSDC cüzdana gönderilir
    // ─────────────────────────────────────────
    function claimRewards() external {
        StakeInfo storage info = stakes[msg.sender];
        uint256 total = pendingRewards(msg.sender);
        require(total > 0, "Henuz odul birikmedi");

        info.accumulatedRewards = 0;
        info.lastClaimed = block.timestamp;

        pikaUSDC.mint(msg.sender, total);
        emit Claimed(msg.sender, total);
    }

    // ─────────────────────────────────────────
    //  BIRIKEN ODULU HESAPLA (accumulated + güncel)
    // ─────────────────────────────────────────
    function pendingRewards(address user) public view returns (uint256) {
        StakeInfo memory info = stakes[user];
        uint256 current = 0;
        if (info.amount > 0 && info.lastClaimed > 0) {
            uint256 timeElapsed = block.timestamp - info.lastClaimed;
            current = (info.amount * SCALE * timeElapsed * dailyMultiplier) / (86400 * 100);
        }
        return info.accumulatedRewards + current;
    }

    // ─────────────────────────────────────────
    //  KULLANICI BILGISINI TOPLU GETIR
    // ─────────────────────────────────────────
    function getStakeInfo(address user) external view returns (
        uint256 stakedAmount,
        uint256 pendingAmount,
        uint256 lastClaimedTime
    ) {
        return (
            stakes[user].amount,
            pendingRewards(user),
            stakes[user].lastClaimed
        );
    }

    // ─────────────────────────────────────────
    //  IC FONKSIYON — ödülleri kaydet, MINT ETME
    // ─────────────────────────────────────────
    function _saveRewards(address user) internal {
        StakeInfo storage info = stakes[user];
        if (info.amount > 0 && info.lastClaimed > 0) {
            uint256 timeElapsed = block.timestamp - info.lastClaimed;
            uint256 reward = (info.amount * SCALE * timeElapsed * dailyMultiplier) / (86400 * 100);
            if (reward > 0) {
                info.accumulatedRewards += reward;
            }
        }
        info.lastClaimed = block.timestamp;
    }
}
