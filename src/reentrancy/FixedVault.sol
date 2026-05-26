// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title  FixedVault
/// @notice Same external interface as `VulnerableVault`, but hardened against reentrancy.
/// @dev    Two independent layers of defense are applied:
///
///         1. Checks-Effects-Interactions (CEI):
///            `balances[msg.sender]` is updated BEFORE any ETH is sent out, so the
///            invariant `caller balance == credited amount` always holds when the
///            external call begins.
///
///         2. OpenZeppelin's `ReentrancyGuard`:
///            A hard lock around `withdraw`. Even if CEI were ever violated by future
///            edits, any nested re-entry into `withdraw` would revert with
///            `ReentrancyGuardReentrantCall`. Defense in depth.
contract FixedVault is ReentrancyGuard {
    mapping(address => uint256) public balances;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function deposit() external payable {
        require(msg.value > 0, "zero deposit");

        balances[msg.sender] += msg.value;

        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(balances[msg.sender] >= amount, "insufficient balance");

        // Effect: update the user's recorded balance BEFORE the external call.
        // If a re-entrant call ever made it past `nonReentrant`, the require above
        // would now fail (balance is already debited).
        balances[msg.sender] -= amount;

        // Interaction: the external ETH transfer happens last, with consistent state.
        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        require(ok, "ETH transfer failed");

        emit Withdrawn(msg.sender, amount);
    }
}
