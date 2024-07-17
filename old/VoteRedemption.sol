// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract VoteRedemption is ERC721, Ownable, EIP712 {    
    bytes32 private constant redeemTypeHash =
        keccak256("Redeem(uint256 messageId,address holderAddress,uint256 value,uint256 voteId)");

    uint256 private _nextTokenId;
    mapping(uint256 => bool) private redeemedIds;

    mapping(uint256 tokenId => VoteMetadata) private _votes;
    mapping(uint256 voteId => uint256) voteOptions;

    struct VoteMetadata {
        uint256 voteId;
        address owner;
        uint256 value;
    }

    constructor(address initialOwner)
        ERC721("Vote", "VT")
        Ownable(initialOwner)
        EIP712("VoteRedemption","1")
    {}

    error ECSDAInvalidSigner(address signer, address owner);
    error AlreadyRedeemed(uint256 messageId);
    error InvalidRedeemer(address target,address redeemer);
    error ECSDABadSignature(bytes signature);

    event Redeemed(address redeemer, uint256 value, uint256 _voteId);

    function redeem(
        uint256 messageId,
        address holderAddress,
        uint256 value,
        uint256 voteId,
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

        bytes32 structHash = keccak256(abi.encode(redeemTypeHash,messageId,holderAddress,value,voteId));

        bytes32 hash_ = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash_, signature);
        if (signer != owner()){
            revert ECSDAInvalidSigner(signer,owner());
        }
        if (signer == address(0)) {
            revert ECSDAInvalidSigner(signer,owner());
        }

        redeemedIds[messageId] = true;
        emit Redeemed(holderAddress,value,voteId);

        _releaseTokens(holderAddress,value,voteId);
    }

    function _safeMint(address to) private onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }

    function _releaseTokens(address _holderAddress, uint256 _value, uint256 _voteId) private {

    }

}
