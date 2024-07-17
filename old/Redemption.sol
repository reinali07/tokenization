// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

abstract contract Redemption is Ownable, EIP712 {
    bytes32 private constant redeemTypeHash =
        keccak256("Redeem(uint256 messageId,address holderAddress,uint256 value,bytes32 data)");

    mapping(uint256 => bool) redeemedIds;

    error ECSDAInvalidSigner(address signer, address owner);
    error AlreadyRedeemed(uint256 messageId);
    error InvalidRedeemer(address target,address redeemer);
    error ECSDABadSignature(bytes signature);
    error InvalidDataHash(bytes32 hashedData, bytes32 data);

    //event Redeemed(uint256 messageId, address holderAddress, uint256 value);

    constructor(address initialOwner, string memory name, string memory version) Ownable(initialOwner) EIP712(name,version) {}

    // function _releaseTokens(
    //     //uint256 messageId, 
    //     address holderAddress, 
    //     uint256 value, 
    //     uint256 data //override this if data is not uint256
    // ) internal virtual;

    // function redeem(
    //     uint256 messageId,
    //     address holderAddress,
    //     uint256 value,
    //     bytes32 hashedData,
    //     uint256 data, //override this if data is not uint256
    //     bytes memory signature
    // ) public virtual {

    //     if (keccak256(abi.encode(data))!=hashedData){
    //         revert InvalidDataHash(hashedData);
    //     }

    //     _verify(messageId,holderAddress,value,hashedData,signature);

    //     emit Redeemed(messageId,holderAddress,value,data);
    //     _releaseTokens(holderAddress,value,data);
    // }

    function _verify(
        uint256 messageId,
        address holderAddress,
        uint256 value,
        bytes32 hashedData,
        bytes memory signature
    ) internal {
        if (signature.length != 65) {
            revert ECSDABadSignature(signature);
        }
        if (holderAddress != msg.sender){
            revert InvalidRedeemer(holderAddress,msg.sender);
        }
        if (redeemedIds[messageId] == true) {
            revert AlreadyRedeemed(messageId);
        }

        redeemedIds[messageId] = true;

        bytes32 structHash = _hashTypedDataV4(
            keccak256(abi.encode(redeemTypeHash,messageId,holderAddress,value,hashedData))
        );

        address signer = ECDSA.recover(structHash, signature);
        if (signer != owner()){
            revert ECSDAInvalidSigner(signer,owner());
        }
        if (signer == address(0)) {
            revert ECSDAInvalidSigner(signer,owner());
        }
    }

}
