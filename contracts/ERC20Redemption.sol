// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract ERC20Redemption is Ownable, EIP712 {
    bytes32 private constant redeemTypeHash =
        keccak256("Redeem(uint256 messageId,address holderAddress,uint256 value,address dividendTokenAddress)");

    struct Message {
        uint256 redeemed;
    }
    mapping(uint256 => Message) messages;

    error ECDSAInvalidSignature(address signer, address owner);
    error AlreadyRedeemed(uint256 messageId);
    //error InvalidRedeemer(address target,address redeemer);
    //error ECSDABadSignature(bytes signature);

    event Redeemed(uint256 messageId, address holderAddress, uint256 value, address dividendTokenAddress);

    constructor(address initialOwner, string memory name, string memory version) Ownable(initialOwner) EIP712(name,version) {}

    // function preRedeem(
    //     uint256 messageId,
    //     address holderAddress,
    //     uint256 value,
    //     address dividendTokenAddress, //override this if data is not uint256
    //     bytes memory signature
    // ) external view {
    //     _viewVerify(messageId,holderAddress,value,dividendTokenAddress,signature);
    // }

    // function _viewVerify(
    //     uint256 messageId,
    //     address holderAddress,
    //     uint256 value,
    //     address dividendTokenAddress,
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
    //         keccak256(abi.encode(redeemTypeHash,messageId,holderAddress,value,dividendTokenAddress))
    //     );

    //     address signer = ECDSA.recover(structHash, signature);
    //     if (signer != owner()){
    //         revert ECSDAInvalidSigner(signer,owner());
    //     }
    // }

    function _releaseTokens(
        //uint256 messageId, 
        //address holderAddress, 
        uint256 value, 
        address dividendTokenAddress //override this if data is not uint256
    ) internal virtual {
        IERC20(dividendTokenAddress).transfer(msg.sender,value);
    }

    function redeem(
        uint256 messageId,
        //address holderAddress,
        uint256 value,
        address dividendTokenAddress, //override this if data is not uint256
        uint8 v,
        bytes32 r,
        bytes32 s
        //bytes memory signature
    ) external {
        //_verify(messageId,holderAddress,value,dividendTokenAddress,signature);
        _verify(messageId,value,dividendTokenAddress,v,r,s);

        emit Redeemed(messageId,msg.sender,value,dividendTokenAddress);
        _releaseTokens(value,dividendTokenAddress);
    }

    function _verify(
        uint256 messageId,
        //address holderAddress,
        uint256 value,
        address dividendTokenAddress,
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
            keccak256(abi.encode(redeemTypeHash,messageId,msg.sender,value,dividendTokenAddress))
        );

        //address signer = ECDSA.recover(structHash, signature);
        address signer = ECDSA.recover(structHash, v,r,s);
        if (signer != owner()){
            revert ECDSAInvalidSignature(signer,owner());
        }
    }

}
