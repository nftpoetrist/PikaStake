// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PikaName is ERC721URIStorage, Ownable {

    uint256 private _nextTokenId;

    mapping(string => address) public domainOwner;
    mapping(string => uint256) public domainToTokenId;
    mapping(uint256 => string) public tokenIdToDomain;
    mapping(address => string[]) private _ownerDomains;

    event DomainMinted(address indexed owner, string domain, uint256 tokenId);

    constructor() ERC721("Pika Name Service", "PIKANAME") Ownable(msg.sender) {}

    function isAvailable(string calldata name) external view returns (bool) {
        return _isValid(name) && domainOwner[name] == address(0);
    }

    function mint(string calldata name) external {
        require(_isValid(name), "Invalid name");
        require(domainOwner[name] == address(0), "Already taken");

        uint256 tokenId = ++_nextTokenId;
        domainOwner[name] = msg.sender;
        domainToTokenId[name] = tokenId;
        tokenIdToDomain[tokenId] = name;
        _ownerDomains[msg.sender].push(name);

        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked("arc://", name, ".arc")));

        emit DomainMinted(msg.sender, name, tokenId);
    }

    function getOwnerDomains(address owner) external view returns (string[] memory) {
        return _ownerDomains[owner];
    }

    function totalSupply() external view returns (uint256) {
        return _nextTokenId;
    }

    function _isValid(string calldata name) internal pure returns (bool) {
        bytes memory b = bytes(name);
        if (b.length == 0 || b.length > 32) return false;
        for (uint i = 0; i < b.length; i++) {
            bytes1 c = b[i];
            bool ok = (c >= 0x61 && c <= 0x7A) ||
                      (c >= 0x30 && c <= 0x39) ||
                      (c == 0x2D);
            if (!ok) return false;
        }
        return true;
    }
}
