// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {Factory} from "../src/Factory.sol";
import {Vault} from "../src/Vault.sol";
import {VaultNFT} from "../src/VaultNFT.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract FactoryTest is Test {
    // Mainnet USDC token address
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    Factory factory;
    address user;

    function setUp() public {
        string memory rpc = vm.envOr(
            "MAINNET_RPC_URL",
            string("https://eth.llamarpc.com")
        );
        vm.createSelectFork(rpc);

        factory = new Factory();
        user = address(0x1234);

        // Give the test user some USDC on the fork
        deal(USDC, user, 1_000_000e6);
    }

    function testCreateVaultAndDepositMintsNFTAndTakesDeposit() public {
        uint256 amount = 1_000e6;

        vm.startPrank(user);
        IERC20(USDC).approve(address(factory), amount);
        (address vaultAddr, uint256 nftId) = factory.createVaultAndDeposit(
            USDC,
            amount
        );
        vm.stopPrank();

        assertTrue(vaultAddr != address(0), "Vault should not be zero");
        assertEq(
            factory.vaultForToken(USDC),
            vaultAddr,
            "Vault mapping should be set"
        );

        Vault vault = Vault(vaultAddr);
        assertEq(
            vault.totalDeposits(),
            amount,
            "Vault total deposits should match"
        );
        assertEq(
            vault.balances(user),
            amount,
            "User balance should be recorded"
        );

        VaultNFT nft = factory.vaultNFT();
        assertEq(nft.ownerOf(nftId), user, "User should own the NFT");

        string memory uri = nft.tokenURI(nftId);
        assertBytesNotEmpty(bytes(uri));
    }

    function testAddLiquidity() public {
        uint256 first = 500e6;
        uint256 second = 200e6;

        vm.startPrank(user);
        IERC20(USDC).approve(address(factory), first + second);
        (address vaultAddr, ) = factory.createVaultAndDeposit(USDC, first);
        factory.addLiquidity(USDC, second);
        vm.stopPrank();

        Vault vault = Vault(vaultAddr);
        assertEq(
            vault.totalDeposits(),
            first + second,
            "Total deposits should include extra liquidity"
        );
        assertEq(
            vault.balances(user),
            first + second,
            "User balance should include extra liquidity"
        );
    }

    function assertBytesNotEmpty(bytes memory data) internal pure {
        require(data.length > 0, "Expected non-empty bytes");
    }
}
