// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import {ETHRedemption} from "./ETHRedemption.sol";

contract ETHDividend is ETHRedemption {

    constructor() ETHRedemption(msg.sender, "ETHDividend","1") {}

}