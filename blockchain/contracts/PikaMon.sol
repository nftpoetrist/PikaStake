// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title PikaMon
 * @notice 6 limited-edition Pokemon NFT cards.
 *         Users burn pUSDC to mint cards.
 *         Each wallet can mint max 2 of each card.
 */
contract PikaMon is ERC1155, Ownable {

    ERC20Burnable public pikaUSDC;

    uint256 public constant MAX_PER_WALLET = 2;

    struct Card {
        string  name;
        uint256 price;      // pUSDC price (18 decimals)
        uint256 maxSupply;
        uint256 minted;
    }

    mapping(uint256 => Card) public cards;
    // wallet => cardId => amount minted
    mapping(address => mapping(uint256 => uint256)) public mintedBy;

    event CardMinted(address indexed user, uint256 indexed cardId, string cardName);

    constructor(address _pikaUSDC) ERC1155("") Ownable(msg.sender) {
        pikaUSDC = ERC20Burnable(_pikaUSDC);

        //                        name                          price            supply
        cards[1] = Card("Enchanted Ribbon Sylveon",  195 * 10**18,  4444, 0);
        cards[2] = Card("Golden Jewel Pikachu",      175 * 10**18,  5555, 0);
        cards[3] = Card("Mystical Crown Espeon",     155 * 10**18,  5555, 0);
        cards[4] = Card("Prismatic Power Pikachu",   130 * 10**18,  7300, 0);
        cards[5] = Card("Verdant Guardian Leafeon",  115 * 10**18,  8400, 0);
        cards[6] = Card("StormRage Pikachu",          85 * 10**18, 10000, 0);
    }

    function mintCard(uint256 cardId) external {
        require(cardId >= 1 && cardId <= 6, "Invalid card ID");

        Card storage card = cards[cardId];
        require(card.minted < card.maxSupply, "Sold out!");
        require(mintedBy[msg.sender][cardId] < MAX_PER_WALLET, "Max 2 per wallet");

        pikaUSDC.burnFrom(msg.sender, card.price);

        mintedBy[msg.sender][cardId]++;
        card.minted++;
        _mint(msg.sender, cardId, 1, "");

        emit CardMinted(msg.sender, cardId, card.name);
    }

    function getCard(uint256 cardId) external view returns (
        string memory name,
        uint256 price,
        uint256 maxSupply,
        uint256 minted,
        uint256 remaining
    ) {
        Card memory c = cards[cardId];
        return (c.name, c.price, c.maxSupply, c.minted, c.maxSupply - c.minted);
    }

    function getMintedBy(address user, uint256 cardId) external view returns (uint256) {
        return mintedBy[user][cardId];
    }

    function setURI(string memory newURI) external onlyOwner {
        _setURI(newURI);
    }
}
