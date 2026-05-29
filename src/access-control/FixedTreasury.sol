// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title  FixedTreasury
/// @notice Same external interface as `VulnerableTreasury`, but sensitive functions
///         are restricted with OpenZeppelin's `Ownable`.
/// @dev    Fix applied to both bugs from the vulnerable version:
///
///         1. `withdraw` — `onlyOwner` so only the owner can move treasury ETH.
///         2. `setOwner` — `onlyOwner` and delegates to `transferOwnership` so
///            ownership changes follow OpenZeppelin's two-step-safe pattern.
///
///         `deposit` and `receive` remain public by design (anyone may fund the treasury).
contract FixedTreasury is Ownable {
    event Deposited(address indexed sender, uint256 amount);
    event Withdrawn(address indexed caller, address indexed to, uint256 amount);

    constructor() Ownable(msg.sender) {}

    receive() external payable {
        emit Deposited(msg.sender, msg.value);
    }

    function deposit() external payable {
        require(msg.value > 0, "zero deposit");

        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Owner-only withdrawal. Non-owners revert with `OwnableUnauthorizedAccount`.
    function withdraw(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "zero recipient");
        require(address(this).balance >= amount, "insufficient treasury balance");

        (bool ok, ) = to.call{value: amount}("");
        require(ok, "ETH transfer failed");

        emit Withdrawn(msg.sender, to, amount);
    }

    /// @notice Owner-only ownership transfer. Wraps OpenZeppelin `transferOwnership`.
    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero owner");

        transferOwnership(newOwner);
    }
}
