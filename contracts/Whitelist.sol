// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract WhitelistUpgradeableV2 is Initializable, OwnableUpgradeable, AccessControlUpgradeable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant VOTER_ROLE = keccak256("VOTER_ROLE");

    event RoleAdded(address indexed account, bytes32 role);
    event RoleRemoved(address indexed account, bytes32 role);

    function initialize(address initialOwner) public initializer {
        __AccessControl_init();

        _transferOwnership(initialOwner);
        _grantRole(ADMIN_ROLE, initialOwner);
        _setRoleAdmin(VOTER_ROLE, ADMIN_ROLE);
    }

    function addAdmin(address admin) public onlyOwner {
        grantRole(ADMIN_ROLE, admin);
        emit RoleAdded(admin, ADMIN_ROLE);
    }

    function removeAdmin(address admin) public onlyOwner {
        revokeRole(ADMIN_ROLE, admin);
        emit RoleRemoved(admin, ADMIN_ROLE);
    }

    function addVoter(address voter) public onlyRole(ADMIN_ROLE) {
        grantRole(VOTER_ROLE, voter);
        emit RoleAdded(voter, VOTER_ROLE);
    }

    function removeVoter(address voter) public onlyRole(ADMIN_ROLE) {
        revokeRole(VOTER_ROLE, voter);
        emit RoleRemoved(voter, VOTER_ROLE);
    }

    function isVoter(address voter) public view returns (bool) {
        return hasRole(VOTER_ROLE, voter);
    }
}
