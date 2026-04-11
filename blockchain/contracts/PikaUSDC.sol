// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title PikaUSDC (pUSDC)
 * @notice PikaStake odul tokeni.
 *         Deploy aninda owner'a 100,000 pUSDC verilir.
 *         Staking kontratiyla yetkilendirilince kullanicilara mint eder.
 *         ERC20Burnable sayesinde NFT kontratiyla yakilabilir.
 */
contract PikaUSDC is ERC20, ERC20Burnable, Ownable {

    address public minter;

    constructor() ERC20("Pika USD Coin", "pUSDC") Ownable(msg.sender) {
        // Deploy aninda owner'a 100,000 pUSDC ver
        _mint(msg.sender, 100_000 * 10 ** 18);
    }

    // Owner, staking kontratini minter olarak atar
    function setMinter(address _minter) external onlyOwner {
        require(_minter != address(0), "Gecersiz adres");
        minter = _minter;
    }

    // Sadece staking kontratiyla cagrilabilir
    function mint(address to, uint256 amount) external {
        require(msg.sender == minter, "Sadece staking kontratiyla mint edilebilir");
        _mint(to, amount);
    }
}
