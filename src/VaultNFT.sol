// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./Vault.sol";

contract VaultNFT is ERC721 {
    using Strings for uint256;

    uint256 public tokenCounter;
    mapping(uint256 => address) public tokenIdToVault;

    // Sets our NFT name and symbol
    constructor() ERC721("VaultReceipt", "VLT") {}

    // Called by Factory to give NFT to user
    function mint(address to, address vaultAddress) external returns (uint256) {
        
        uint256 tokenId = tokenCounter;
        _mint(to, tokenId); 
        tokenIdToVault[tokenId] = vaultAddress;
        tokenCounter++;
        return tokenId;
    }

    // Creates the image data
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(ownerOf(tokenId) != address(0), "Token does not exist");
        
        address vaultAddress = tokenIdToVault[tokenId];
        Vault vault = Vault(vaultAddress);
        
        // Get Data
       // address tokenAddr = vault.TOKEN();
        uint256 balance = vault.getBalance();
        
        // Create SVG Image
        string memory svg = _createSVG(balance);
        
        // Create JSON Metadata
        string memory json = _createJSON(svg);
        
        // Encode to Base64
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(bytes(json))
            )
        );
    }

    // Creates our SVG and encodes it
    function _createSVG(uint256 balance) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" width="500" height="500">',
                '<rect width="100%" height="100%" fill="#222"/>',
                '<text x="50%" y="50%" text-anchor="middle" fill="white" font-size="20">VAULT RECEIPT</text>',
                '<text x="50%" y="70%" text-anchor="middle" fill="#0f0" font-size="16">User Token Balance: ',
                balance.toString(),
                '</text>',
                '</svg>'
            )
        );
    }

    // Creates our JSON to convert our svg
    function _createJSON(string memory svg) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '{"name":"Vault Receipt","description":"A receipt for your vault","image":"data:image/svg+xml;base64,',
                Base64.encode(bytes(svg)),
                '"}'
            )
        );
    }
}