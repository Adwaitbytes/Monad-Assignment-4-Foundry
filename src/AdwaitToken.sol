// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/*
 AdwaitToken (ERC-20)
 - Admin (DEFAULT_ADMIN_ROLE): can pause/unpause, grant/revoke roles.
 - Minter (MINTER_ROLE): can mint (when not paused)
 - Ownable: owner can transfer ownership
 - Pausable: pause blocks transfers and minting
*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AdwaitToken is ERC20, Pausable, AccessControl, Ownable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event AdminPaused(address indexed admin);
    event AdminUnpaused(address indexed admin);
    event TokensMinted(address indexed minter, address indexed to, uint256 amount);

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply // supply in token smallest units (wei for 18 decimals)
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        // Grant roles to deployer
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        // Mint initial supply to deployer (if > 0)
        if (initialSupply > 0) {
            _mint(msg.sender, initialSupply);
            emit TokensMinted(msg.sender, msg.sender, initialSupply);
        }
    }

    // --------------------
    // Pausable controls (only Admin)
    // --------------------
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
        emit AdminPaused(msg.sender);
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
        emit AdminUnpaused(msg.sender);
    }

    // --------------------
    // Minting (only Minter)
    // --------------------
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) whenNotPaused {
        _mint(to, amount);
        emit TokensMinted(msg.sender, to, amount);
    }

    // --------------------
    // Role management helpers
    // --------------------
    function grantMinterRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, account);
    }

    function revokeMinterRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MINTER_ROLE, account);
    }

    function isMinter(address account) external view returns (bool) {
        return hasRole(MINTER_ROLE, account);
    }

    function isAdmin(address account) external view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    // --------------------
    // ERC20 hooks - prevent transfers while paused
    // --------------------
    function _update(address from, address to, uint256 value)
        internal
        override
        whenNotPaused
    {
        super._update(from, to, value);
    }

    // Necessary override to satisfy AccessControl interface support
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl)
        returns (bool)
    {
        return AccessControl.supportsInterface(interfaceId);
    }
}
