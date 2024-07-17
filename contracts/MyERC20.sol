// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyERC20 is ERC20, ERC20Burnable, Ownable {
    uint256 public realReserve = 100 * 10 ** decimals();
    constructor() ERC20("MyToken", "MTK") Ownable(msg.sender) {
        _mint(msg.sender, 100 * 10 ** decimals());
    }

    function updateReal(uint256 addedReserves) public onlyOwner {
        realReserve = realReserve + addedReserves;
    }
}
