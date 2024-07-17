// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

abstract contract NFTRedemption is Ownable, EIP712, ERC721, ERC721Burnable {
    uint256 private _nextTokenId;

    bytes32 private constant redeemTypeHash =
        keccak256("Redeem(uint256 messageId,address holderAddress,uint256 value,uint256 nftdata)");

    struct Message {
        uint256 redeemed;
    }
    mapping(uint256 => Message) messages;

    error ECDSAInvalidSignature(address signer, address owner);
    error AlreadyRedeemed(uint256 messageId);
    //error InvalidRedeemer(address target,address redeemer);
    //error ECSDABadSignature(bytes signature);
    //error NonTransferable();

    event Redeemed(uint256 messageId, address holderAddress, uint256 value, uint256 nftdata);

    constructor(address initialOwner, string memory name, string memory symbol, string memory version) Ownable(initialOwner) EIP712(name,version) ERC721(name, symbol) {
        _nextTokenId = 0;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    // function preRedeem(
    //     uint256 messageId,
    //     address holderAddress,
    //     uint256 value,
    //     uint256 nftdata, //override this if data is not uint256
    //     bytes memory signature
    // ) external view {
    //     _viewVerify(messageId,holderAddress,value,nftdata,signature);
    // }

    // function _viewVerify(
    //     uint256 messageId,
    //     address holderAddress,
    //     uint256 value,
    //     uint256 nftdata,
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
    //         keccak256(abi.encode(redeemTypeHash,messageId,holderAddress,value,nftdata))
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
        uint256 nftdata //override this if data is not uint256
    ) internal virtual;

    function redeem(
        uint256 messageId,
        //address holderAddress,
        uint256 value,
        uint256 nftdata, //override this if data is not uint256
        uint8 v,
        bytes32 r,
        bytes32 s
        //bytes memory signature
    ) external {
        //_verify(messageId,holderAddress,value,nftdata,signature);
        _verify(messageId,value,nftdata,v,r,s);

        emit Redeemed(messageId,msg.sender,value,nftdata);
        _releaseTokens(value,nftdata);
    }

    function _verify(
        uint256 messageId,
        //address holderAddress,
        uint256 value,
        uint256 nftdata,
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
            keccak256(abi.encode(redeemTypeHash,messageId,msg.sender,value,nftdata))
        );

        //address signer = ECDSA.recover(structHash, signature);
        address signer = ECDSA.recover(structHash, v,r,s);
        if (signer != owner()){
            revert ECDSAInvalidSignature(signer,owner());
        }
    }

    // function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
    //     if (to != address(0) && auth != address(0)) {
    //         revert NonTransferable();
    //     }
    //     return super._update(to,tokenId,auth);
    // }

}
