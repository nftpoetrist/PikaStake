// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract PikaBoxes {
    IERC20  public constant USDC       = IERC20(0x3600000000000000000000000000000000000000);
    address public constant VAULT      = 0xd76B24F43bCF5C3fFe09906A7414CD4D02EA7cDe;

    // 0=common,1=rare,2=epic,3=legendary
    uint256[4] public PRICES     = [2e6,   4e6,  8e6,  16e6];
    uint256[4] public MAX_SUPPLY = [10000, 8000, 5000, 1000];
    uint256[4] public minted;

    event BoxMinted(address indexed buyer, uint8 indexed rarity, uint256 price);

    function mint(uint8 rarity) external {
        require(rarity < 4, "Invalid rarity");
        require(minted[rarity] < MAX_SUPPLY[rarity], "Sold out");
        uint256 price = PRICES[rarity];
        require(USDC.transferFrom(msg.sender, VAULT, price), "USDC transfer failed");
        minted[rarity]++;
        emit BoxMinted(msg.sender, rarity, price);
    }

    function getSupplyInfo(uint8 rarity) external view returns (uint256 _minted, uint256 _max) {
        require(rarity < 4, "Invalid rarity");
        return (minted[rarity], MAX_SUPPLY[rarity]);
    }

    function getPrice(uint8 rarity) external view returns (uint256) {
        require(rarity < 4, "Invalid rarity");
        return PRICES[rarity];
    }
}
