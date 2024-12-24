// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// Note: Có 1 main admin là người gọi ban đầu của hợp đồng, người này có thể add và remove những admin khác
// Những voter chỉ được add và remove bởi admin

contract WhitelistUpgradeableV2 is Initializable, OwnableUpgradeable, AccessControlUpgradeable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE"); // Mã hóa role admin
    bytes32 public constant VOTER_ROLE = keccak256("VOTER_ROLE"); // Mã hóa role voter

    event RoleAdded(address indexed account, bytes32 role);
    event RoleRemoved(address indexed account, bytes32 role);

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __AccessControl_init();

        _grantRole(ADMIN_ROLE, initialOwner); // Người đầu tiên gọi hợp đồng sẽ được cấp quyền admin
        _setRoleAdmin(VOTER_ROLE, ADMIN_ROLE); // ADMIN_ROLE quản lý VOTER_ROLE
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE); // ADMIN_ROLE tự quản lý ADMIN_ROLE
    }
    /// @dev add admin
    function addAdmin(address admin) public onlyOwner { // Chỉ sở hữu hợp đồng mới có thể thêm admin
        grantRole(ADMIN_ROLE, admin);
        emit RoleAdded(admin, ADMIN_ROLE);
    }
    /// @dev xoa admin
    function removeAdmin(address admin) public onlyOwner {
        revokeRole(ADMIN_ROLE, admin);
        emit RoleRemoved(admin, ADMIN_ROLE);
    }
    /// @dev add voter(can co admin_role)
    function addVoter(address voter) public onlyRole(ADMIN_ROLE) {
        grantRole(VOTER_ROLE, voter);
        emit RoleAdded(voter, VOTER_ROLE);
    }
    /// @dev Remove voter (can co admin_role)
    function removeVoter(address voter) public onlyRole(ADMIN_ROLE) {
        revokeRole(VOTER_ROLE, voter);
        emit RoleRemoved(voter, VOTER_ROLE);
    }
    /// @dev Check voter.
    function isVoter(address voter) public view returns (bool) {
        return hasRole(VOTER_ROLE, voter);
    }
}
