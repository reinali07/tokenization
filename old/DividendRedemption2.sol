// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import {Redemption} from "./Redemption.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DividendRedemption2 is Redemption {

    event Redeemed(uint256 messageId, address holderAddress, uint256 value, address dividendTokenAddress);

    constructor() Redemption(msg.sender, "DividendRedemption","1") {}

    function _releaseTokens(
        //uint256 messageId, 
        address holderAddress, 
        uint256 value, 
        address dividendTokenAddress //override this if data is not uint256
    ) private {
        IERC20(dividendTokenAddress).transfer(holderAddress,value);
    }

    function redeem(
        uint256 messageId,
        address holderAddress,
        uint256 value,
        bytes32 hashedData,
        address dividendTokenAddress, //override this if data is not uint256
        bytes memory signature
    ) public {
        bytes32 hashOfData = keccak256(abi.encode(dividendTokenAddress));
        if (hashOfData!=hashedData){
            revert InvalidDataHash(hashedData,hashOfData);
        }

        _verify(messageId,holderAddress,value,hashedData,signature);

        emit Redeemed(messageId,holderAddress,value,dividendTokenAddress);
        _releaseTokens(holderAddress,value,dividendTokenAddress);
    }
}