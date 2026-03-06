// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Vault {
    using SafeERC20 for IERC20;

    // The token this vault holds
    address public immutable TOKEN;
    
    // Total amount deposited in this vault
    uint256 public totalDeposited;

    // Event to track deposits
    event Deposit(address indexed user, uint256 amount);

    constructor(address _token) {
        TOKEN = _token;
    }

    // User deposits tokens here
    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        
        // Move tokens from user to this vault
        IERC20(TOKEN).safeTransferFrom(msg.sender, address(this), amount);
        
        // Update total
        totalDeposited += amount;
        
        emit Deposit(msg.sender, amount);
    }

    // Helper function for the NFT to read balance easily
    function getBalance() external view returns (uint256) {
        return IERC20(TOKEN).balanceOf(address(this));
    }
}