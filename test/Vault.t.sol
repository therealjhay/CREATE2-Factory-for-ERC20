// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/VaultFactory.sol";
import "../src/VaultNFT.sol";
import "../src/Vault.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VaultTest is Test {
    VaultFactory factory;
    VaultNFT nft;
    
    // USDC Address
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    
    // Using Binance Wallet 
    address constant WHALE = 0x28C6c06298d514Db089934071355E5743bf21d60;

    function setUp() public {
        // 1. Load RPC URL from .env
        string memory rpcUrl = vm.envString("RPC_URL");
        
        // 2. Create Mainnet Fork
        vm.createSelectFork(rpcUrl);
        
        // 3. Deploy Contracts
        nft = new VaultNFT();
        factory = new VaultFactory(address(nft));
        
        console.log("Contracts Deployed on Fork");
    }

    function test_CreateVaultAndSeeNFT() public {
        console.log("=== TEST STARTED ===");

        // Impersonate the Whale (Pretend we are them)
        vm.startPrank(WHALE);
        
        // Send ourselves 100 USDC (USDC has 6 decimals)
        uint256 amount = 100 * 10**6;
        IERC20(USDC).transfer(address(this), amount);
        
        vm.stopPrank();
        
        // Check we got the money
        uint256 myBalance = IERC20(USDC).balanceOf(address(this));
        console.log("My USDC Balance:", myBalance);
        require(myBalance >= amount, "Failed to get funds from whale");

        // Create the Vault
        console.log("Creating Vault...");
        factory.createVault(USDC);
        
        // Finding the Vault Address
        // Since we used CREATE2, we can calculate the address
        bytes32 salt = bytes32(uint256(uint160(USDC)));
        bytes32 bytecodeHash = keccak256(abi.encodePacked(type(Vault).creationCode, abi.encode(USDC)));
        address vaultAddress = address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(factory), salt, bytecodeHash)))));
        
        console.log("Vault Address:", vaultAddress);

        // Deposit into Vault
        console.log("Depositing into Vault...");
        vm.startPrank(address(this));
        IERC20(USDC).approve(vaultAddress, amount);
        Vault(vaultAddress).deposit(amount);
        vm.stopPrank();

        // Check NFT
        uint256 tokenId = 0;
        console.log("NFT Owner:", nft.ownerOf(tokenId));

        // GET THE IMAGE DATA
        string memory uri = nft.tokenURI(tokenId);
        
        console.log("=== COPY THIS STRING TO VIEW NFT ===");
        console.log(uri);
        console.log("=== END OF STRING ===");

        // Verify Balance
        uint256 vaultBalance = IERC20(USDC).balanceOf(vaultAddress);
        console.log("Vault Balance:", vaultBalance);
        assertEq(vaultBalance, amount);
        
        console.log("=== TEST PASSED ===");
    }
}