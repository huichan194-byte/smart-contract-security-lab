// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title VulnerableVault
/// @notice A deliberately vulnerable ETH vault used to demonstrate reentrancy.
contract VulnerableVault {
    mapping(address => uint256) public balances;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function deposit() external payable {
        require(msg.value > 0, "zero deposit");

        balances[msg.sender] += msg.value;

        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "insufficient balance");

        // Vulnerability: external call happens before updating user balance.
        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        require(ok, "ETH transfer failed");

        balances[msg.sender] = 0;

        emit Withdrawn(msg.sender, amount);
    }
}
