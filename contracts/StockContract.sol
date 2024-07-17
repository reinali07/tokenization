// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StockContract is ERC20, ERC20Burnable, Ownable {
    string public stockname;
    string public stocksymbol;

    event NameChanged(string newName, string newSymbol);

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
        Ownable(msg.sender)
    {
        stockname = name_;
        stocksymbol = symbol_;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function rename(string memory name_, string memory symbol_) public onlyOwner {
        stocksymbol = name_;
        stocksymbol = symbol_;

        emit NameChanged(name_, symbol_);
    } 
}
