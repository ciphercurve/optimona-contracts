// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title Optimona Token
/// @notice Example ERC20 token with EIP-2612 Permit support for gasless approvals.
contract Optimona is ERC20, ERC20Permit, Ownable {
    constructor(
        uint256 initialSupply
    ) ERC20("Optimona", "OMN") ERC20Permit("Optimona") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    /// @notice Mint new tokens to a specific address (owner-only)
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
