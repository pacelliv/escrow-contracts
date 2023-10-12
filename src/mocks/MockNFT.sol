// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockNFT is ERC721 {
    constructor() ERC721("MockNFT", "NFT") {}

    function mint(address recipient, uint256 tokenId) external {
        _mint(recipient, tokenId);
    }
}
