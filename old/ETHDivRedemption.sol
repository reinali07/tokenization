// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import {Redemption} from "./Redemption.sol";
//import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ETHDivRedemption is Redemption {

    event Redeemed(uint256 messageId, address holderAddress, uint256 value, address holderAddressPayable);

    constructor() Redemption(msg.sender, "ETHDivRedemption","1") {}

    function _releaseTokens(
        //uint256 messageId, 
        //address holderAddress,
        uint256 value, 
        address payable holderAddressPayable //override this if data is not uint256
    ) private {
        (bool sent, bytes memory data) = holderAddressPayable.call{value: value}("");
        require(sent, "Failed to send Ether");
    }

    function redeem(
        uint256 messageId,
        address holderAddress,
        uint256 value,
        bytes32 hashedData,
        address payable holderAddressPayable, //override this if data is not uint256
        bytes memory signature
    ) public {
        bytes32 hashOfData = keccak256(abi.encode(holderAddressPayable));
        if (hashOfData!=hashedData){
            revert InvalidDataHash(hashedData,hashOfData);
        }

        _verify(messageId,holderAddress,value,hashedData,signature);

        emit Redeemed(messageId,holderAddress,value,holderAddressPayable);
        _releaseTokens(value,holderAddressPayable);
    }

    receive() external payable {}
}