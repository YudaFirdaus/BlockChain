// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ProjectNFT is ERC721URIStorage, Ownable {
    uint256 private _nextTokenId;

    // Struct untuk menyimpan data aset project
    struct AssetData {
        string assetName;
        string category;
    }

    mapping(uint256 => AssetData) public projectAssets;

    constructor() ERC721("ProjectNFT", "PNFT") Ownable(msg.sender) {}

    // Fungsi untuk mint NFT baru beserta data asetnya
    function mintNFT(
        address recipient, 
        string memory uri, 
        string memory _assetName, 
        string memory _category
    ) public onlyOwner returns (uint256) {
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;

        _mint(recipient, tokenId);
        _setTokenURI(tokenId, uri);

        projectAssets[tokenId] = AssetData(_assetName, _category);

        return tokenId;
    }
}