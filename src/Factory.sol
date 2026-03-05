// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Vault} from "./Vault.sol";
import {VaultNFT} from "./VaultNFT.sol";

contract Factory {
    VaultNFT public immutable vaultNFT;

    mapping(address => address) public vaultForToken;

    event VaultCreated(address indexed token, address indexed vault, address indexed creator, uint256 nftId, uint256 initialDeposit);
    event LiquidityAdded(address indexed token, address indexed vault, address indexed user, uint256 amount);

    constructor() {
        vaultNFT = new VaultNFT(address(this));
    }

    function deterministicVaultAddress(address token) public view returns (address predicted) {
        bytes32 salt = _vaultSalt(token);
        bytes memory bytecode = abi.encodePacked(type(Vault).creationCode, abi.encode(IERC20(token), uint256(0), address(0)));
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode))
        );
        predicted = address(uint160(uint256(hash)));
    }

    function createVaultAndDeposit(address token, uint256 amount) external returns (address vault, uint256 nftId) {
        require(amount > 0, "Amount zero");
        require(token != address(0), "Token zero");

        vault = vaultForToken[token];
        if (vault == address(0)) {
            bytes32 salt = _vaultSalt(token);
            vault = address(new Vault{salt: salt}(IERC20(token), amount, msg.sender));
            vaultForToken[token] = vault;
            nftId = vaultNFT.mintForVault(msg.sender, vault, token);
            emit VaultCreated(token, vault, msg.sender, nftId, amount);
        } else {
            Vault(vault).recordDeposit(msg.sender, amount);
        }

        require(IERC20(token).transferFrom(msg.sender, vault, amount), "Transfer failed");
        emit LiquidityAdded(token, vault, msg.sender, amount);
    }

    function addLiquidity(address token, uint256 amount) external returns (address vault) {
        require(amount > 0, "Amount zero");
        vault = vaultForToken[token];
        require(vault != address(0), "Vault not created");

        Vault(vault).recordDeposit(msg.sender, amount);
        require(IERC20(token).transferFrom(msg.sender, vault, amount), "Transfer failed");

        emit LiquidityAdded(token, vault, msg.sender, amount);
    }

    function _vaultSalt(address token) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(token));
    }
}

