// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract Vault {
    IERC20 public immutable token;
    address public immutable factory;

    uint256 public totalDeposits;
    mapping(address => uint256) public balances;

    constructor(IERC20 _token, uint256 initialDeposit, address initialDepositor) {
        token = _token;
        factory = msg.sender;
        if (initialDeposit > 0 && initialDepositor != address(0)) {
            totalDeposits = initialDeposit;
            balances[initialDepositor] = initialDeposit;
        }
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "Not factory");
        _;
    }

    function recordDeposit(address user, uint256 amount) external onlyFactory {
        require(amount > 0, "Zero amount");
        totalDeposits += amount;
        balances[user] += amount;
    }
}

