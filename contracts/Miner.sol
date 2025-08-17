// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Miner is Ownable {
    IERC721 public guvaNFT;
    mapping(address => bool) public isMiner;

    constructor(address guvaNFT_) Ownable(msg.sender) {
        guvaNFT = IERC721(guvaNFT_);
    }

    function addMiner(address miner_) public onlyOwner {
        isMiner[miner_] = true;
    }

    function removeMiner(address miner_) public onlyOwner {
        isMiner[miner_] = false;
    }
}
