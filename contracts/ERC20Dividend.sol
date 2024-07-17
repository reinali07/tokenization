// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import {ERC20Redemption} from "./ERC20Redemption.sol";

contract ERC20Dividend is ERC20Redemption {

    constructor() ERC20Redemption(msg.sender, "ERC20Dividend","1") {}
       
}

