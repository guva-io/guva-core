// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract GuvaNFT is ERC721URIStorage {
    uint256 private _tokenIdCounter;

    uint256 public rent;
    address public immutable creator;

    constructor() ERC721("GuvaNFT", "GUVA") {
        creator = msg.sender;
    }

    function updateRent(uint256 rent_) public {
        rent = rent_;
    }

    function mint(address to_, string memory uri_) public {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        _safeMint(to_, tokenId);
        _setTokenURI(tokenId, uri_);
    }
}
