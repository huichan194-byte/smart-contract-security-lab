// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title  VulnerableTreasury
/// @notice A deliberately vulnerable ETH treasury used to demonstrate missing
///         access control. The contract stores an `owner`, but the sensitive
///         functions do not check the caller.
/// @dev    Two independent access control bugs are present:
///
///         1. `withdraw` is callable by anyone — an attacker can drain the treasury directly.
///         2. `setOwner` is callable by anyone — an attacker can permanently take over the contract.
///
///         Each bug stands on its own; the attacker does not need both to cause damage.
contract VulnerableTreasury {
    address public owner;

    event Deposited(address indexed sender, uint256 amount);
    event Withdrawn(address indexed caller, address indexed to, uint256 amount);
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    /// @notice Allow the contract to receive plain ETH transfers.
    receive() external payable {
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Anyone can deposit ETH into the treasury. This is intentional.
    function deposit() external payable {
        require(msg.value > 0, "zero deposit");

        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Withdraws ETH from the treasury to an arbitrary recipient.
    /// @dev    Vulnerability: missing access control.
    ///         This function should be restricted to `owner`, but it is `external`
    ///         with no `onlyOwner` check. Any external account can call it and
    ///         transfer ETH out of the treasury.
    function withdraw(address payable to, uint256 amount) external {
        require(to != address(0), "zero recipient");
        require(address(this).balance >= amount, "insufficient treasury balance");

        (bool ok, ) = to.call{value: amount}("");
        require(ok, "ETH transfer failed");

        emit Withdrawn(msg.sender, to, amount);
    }

    /// @notice Sets a new owner of the treasury.
    /// @dev    Vulnerability: missing access control.
    ///         This setter should be restricted to the current `owner`, but it
    ///         allows any external account to overwrite `owner`. This is a
    ///         classic privilege-escalation bug — once `setOwner` is called by
    ///         the attacker, they control the contract permanently.
    function setOwner(address newOwner) external {
        require(newOwner != address(0), "zero owner");

        address previousOwner = owner;
        owner = newOwner;

        emit OwnerChanged(previousOwner, newOwner);
    }
}
