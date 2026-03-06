// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Vault.sol";
import "./VaultNFT.sol";

contract VaultFactory {
    VaultNFT public nft;

    // Whitelisted Tokens
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    constructor(address _nft) {
        nft = VaultNFT(_nft);
    }

    function createVault(address token) external returns (address) {
        //  Check if token is allowed
        require(isWhitelisted(token), "Token not supported");
        
        // CREATE2 Logic: Use token address as 'salt'
        // This ensures the vault address is always the same for this token
        bytes32 salt = bytes32(uint256(uint160(token)));
        
        // Deploy Vault
        address vaultAddress = address(new Vault{salt: salt}(token));
        
        // 4. Mint NFT to the user who created it
        nft.mint(msg.sender, vaultAddress);
        
        return vaultAddress;
    }

    // Ensures that only the below tokens can be used in vault system
    function isWhitelisted(address token) public pure returns (bool) {
        return (token == USDC || token == USDT || token == DAI);
    }
}