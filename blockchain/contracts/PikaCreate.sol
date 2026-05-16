// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

/**
 * @title PikaCreate
 * @notice Kullanıcıların kendi NFT'lerini mint edebildiği ERC721 kontratı.
 *         Token URI'si metadata JSON'u base64 olarak içerir (görsel dahil).
 */
contract PikaCreate is ERC721URIStorage {

    uint256 private _tokenIds;

    // Her adresin mint ettiği token ID listesi
    mapping(address => uint256[]) private _ownerTokens;

    event NFTMinted(address indexed minter, uint256 indexed tokenId);

    constructor() ERC721("PikaCreate NFT", "PKAC") {}

    function mint(string memory tokenURI) external returns (uint256) {
        _tokenIds++;
        uint256 newTokenId = _tokenIds;
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        _ownerTokens[msg.sender].push(newTokenId);
        emit NFTMinted(msg.sender, newTokenId);
        return newTokenId;
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIds;
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        return _ownerTokens[owner];
    }
}
