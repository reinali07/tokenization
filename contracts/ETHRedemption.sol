// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

abstract contract ETHRedemption is Ownable, EIP712 {
    bytes32 private constant redeemTypeHash =
        keccak256("Redeem(uint256 messageId,address holderAddress,uint256 value)");

    struct Message {
        uint256 redeemed;
    }
    mapping(uint256 => Message) messages;

    error ECDSAInvalidSignature(address signer, address owner);
    error AlreadyRedeemed(uint256 messageId);
    //error InvalidRedeemer(address target,address redeemer);
    //error ECSDABadSignature(bytes signature);

    event Redeemed(uint256 messageId, address holderAddress, uint256 value);

    constructor(address initialOwner, string memory name, string memory version) Ownable(initialOwner) EIP712(name,version) {}

    // function preRedeem(
    //     uint256 messageId,
    //     address holderAddress,
    //     uint256 value,
    //     bytes memory signature
    // ) external view {
    //     _viewVerify(messageId,holderAddress,value,signature);
    // }

    // function _viewVerify(
    //     uint256 messageId,
    //     address holderAddress,
    //     uint256 value,
    //     bytes memory signature
    // ) internal view {
    //     if (signature.length != 65) {
    //         revert ECSDABadSignature(signature);
    //     }
    //     if (holderAddress != msg.sender){
    //         revert InvalidRedeemer(holderAddress,msg.sender);
    //     }
    //     if (redeemedIds[messageId] == true) {
    //         revert AlreadyRedeemed(messageId);
    //     }

    //     bytes32 structHash = _hashTypedDataV4(
    //         keccak256(abi.encode(redeemTypeHash,messageId,holderAddress,value))
    //     );

    //     address signer = ECDSA.recover(structHash, signature);
    //     if (signer != owner()){
    //         revert ECSDAInvalidSigner(signer,owner());
    //     }
    //     return true;
    // }

    function _releaseTokens(
        //uint256 messageId, 
        //address holderAddress, 
        uint256 value 
    ) internal {
        (bool sent, ) = payable(msg.sender).call{value: value}("");
        require(sent, "Failed to send Ether");
    }

    function redeem(
        uint256 messageId,
        //address holderAddress,
        uint256 value,
        uint8 v,
        bytes32 r,
        bytes32 s
        //bytes memory signature
    ) external {
        //_verify(messageId,holderAddress,value,signature);
        _verify(messageId,value,v,r,s);

        emit Redeemed(messageId,msg.sender,value);
        _releaseTokens(value);
    }

    function _verify(
        uint256 messageId,
        //address holderAddress,
        uint256 value,
        uint8 v,
        bytes32 r,
        bytes32 s
        //bytes memory signature
    ) internal {
        // if (signature.length != 65) {
        //     revert ECSDABadSignature(signature);
        // }
        // if (holderAddress != msg.sender){
        //     revert InvalidRedeemer(holderAddress,msg.sender);
        // }
        Message storage message = messages[messageId];
        if (message.redeemed == 1) {
            revert AlreadyRedeemed(messageId);
        }
        message.redeemed = 1;

        bytes32 structHash = _hashTypedDataV4(
            keccak256(abi.encode(redeemTypeHash,messageId,msg.sender,value))
        );

        //address signer = ECDSA.recover(structHash, signature);
        address signer = ECDSA.recover(structHash, v,r,s);
        if (signer != owner()){
            revert ECDSAInvalidSignature(signer,owner());
        }
    }

    receive() external payable {}
}
