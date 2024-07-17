// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DividendRedemption is Ownable, EIP712 {
    bytes32 private constant redeemTypeHash =
        keccak256("Redeem(uint256 messageId,address holderAddress,uint256 value,address dividendTokenAddress)");

    mapping(uint256 => bool) redeemedIds;

    error ECSDAInvalidSigner(address signer, address owner);
    error AlreadyRedeemed(uint256 messageId);
    error InvalidRedeemer(address target,address redeemer);
    error ECSDABadSignature(bytes signature);

    event Redeemed(address redeemer, uint256 value, address dividendTokenAddress);

    constructor() Ownable(msg.sender) EIP712("DividendRedemption","1") {}

    function redeem(
        uint256 messageId,
        address holderAddress,
        uint256 value,
        address dividendTokenAddress,
        bytes memory signature
    ) public {

        if (signature.length != 65) {
            revert ECSDABadSignature(signature);
        }
        if (holderAddress != msg.sender){
            revert InvalidRedeemer(holderAddress,msg.sender);
        }
        if (redeemedIds[messageId] == true) {
            revert AlreadyRedeemed(messageId);
        }

        bytes32 structHash = keccak256(abi.encode(redeemTypeHash,messageId,holderAddress,value,dividendTokenAddress));

        bytes32 hash_ = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash_, signature);
        if (signer != owner()){
            revert ECSDAInvalidSigner(signer,owner());
        }
        if (signer == address(0)) {
            revert ECSDAInvalidSigner(signer,owner());
        }

        redeemedIds[messageId] = true;
        emit Redeemed(holderAddress,value,dividendTokenAddress);

        _releaseTokens(holderAddress,value,dividendTokenAddress);
    }

    function _releaseTokens(address _holderAddress, uint256 _value, address _dividendTokenAddress) private {
        IERC20(_dividendTokenAddress).transfer(_holderAddress,_value);
    }

}
