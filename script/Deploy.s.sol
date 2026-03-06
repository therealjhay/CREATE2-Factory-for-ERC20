// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/VaultFactory.sol";
import "../src/VaultNFT.sol";

contract DeployScript is Script {
    function run() external {
        // 1. Get your private key from .env file
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // 2. Start broadcasting transactions (signing with your key)
        vm.startBroadcast(deployerPrivateKey);

        // 3. Deploy NFT Contract FIRST (it doesn't need any arguments)
        VaultNFT nft = new VaultNFT();
        console.log("NFT Contract Deployed:", address(nft));
        
        // 4. Deploy Factory Contract SECOND (it needs the NFT address)
        VaultFactory factory = new VaultFactory(address(nft));
        console.log("Factory Contract Deployed:", address(factory));

        // 5. Stop broadcasting
        vm.stopBroadcast();
        
        // 6. Print final addresses
        console.log("=== DEPLOYMENT COMPLETE ===");
        console.log("NFT Address:", address(nft));
        console.log("Factory Address:", address(factory));
    }
}