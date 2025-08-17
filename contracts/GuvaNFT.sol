// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract GuvaNFT is ERC721URIStorage {
    uint256 private _tokenIdCounter;

    mapping(uint256 => uint256) public rentOf;
    mapping(uint256 => address) public creatorOf;

    constructor() ERC721("GuvaNFT", "GUVA") {
    }

    function updateRent(uint256 tokenId_, uint256 rent_) public {
        require(ownerOf(tokenId_) == msg.sender, "GuvaNFT: Caller is not the owner");
        rentOf[tokenId_] = rent_;
    }

    function mint(address to_, string memory uri_) public {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        creatorOf[tokenId] = msg.sender;
        _safeMint(to_, tokenId);
        _setTokenURI(tokenId, uri_);
    }
}
