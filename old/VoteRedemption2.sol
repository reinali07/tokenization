// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import {Redemption} from "./Redemption.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract VoteRedemption2 is ERC721, Redemption {

    uint256 private _nextTokenId;
    uint256 private _nextVoteId;

    //mapping(uint256 => bool) private redeemedIds;

    mapping(uint256 tokenId => VoteMetadata) private _votes;
    mapping(uint256 voteId => uint8) voteOptions;

    struct VoteMetadata {
        uint256 voteId;
        address owner;
        uint256 value;
    }

    event Redeemed(uint256 messageId, address holderAddress, uint256 value, uint256 voteId);

    constructor() ERC721("Vote", "VT") Redemption(msg.sender, "VoteRedemption","1") {
        _nextTokenId = 0;
        _nextVoteId = 0;
    }

    function setupVote(uint8 voteOptions_) public onlyOwner {
        voteOptions[_nextVoteId++] = voteOptions_;
    }

    function _safeMint(address to, VoteMetadata memory vote) private {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);

        _votes[tokenId] = vote;

    }

    function _releaseTokens(
        //uint256 messageId, 
        address holderAddress, 
        uint256 value, 
        uint256 voteId //override this if data is not uint256
    ) private {
        VoteMetadata memory vote = VoteMetadata(voteId, holderAddress, value);
        _safeMint(holderAddress,vote);
    }

    function redeem(
        uint256 messageId,
        address holderAddress,
        uint256 value,
        bytes32 hashedData,
        uint256 voteId, //override this if data is not uint256
        bytes memory signature
    ) public {
        if (keccak256(abi.encode(voteId))!=hashedData){
            revert InvalidDataHash(hashedData,keccak256(abi.encode(voteId)));
        }

        _verify(messageId,holderAddress,value,hashedData,signature);

        emit Redeemed(messageId,holderAddress,value,voteId);
        _releaseTokens(holderAddress,value,voteId);
    }
}