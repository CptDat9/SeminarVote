// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// Note: Có 1 main admin là người gọi ban đầu của hợp đồng, người này có thể add và remove những admin khác
// Những voter chỉ được add và remove bởi admin

contract WhitelistUpgradeableV2 is Initializable, OwnableUpgradeable, AccessControlUpgradeable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE"); 
    bytes32 public constant VOTER_ROLE = keccak256("VOTER_ROLE"); 

    event RoleAdded(address indexed account, bytes32 role);
    event RoleRemoved(address indexed account, bytes32 role);

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner); //sai khi k truyền tham số
        __AccessControl_init();

        _grantRole(ADMIN_ROLE, initialOwner); 
        _setRoleAdmin(VOTER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE); 
    }
    /// @dev add admin
<<<<<<< HEAD
    function addAdmin(address admin) public onlyOwner {
=======
    function addAdmin(address admin) public onlyOwner { // Chỉ sở hữu hợp đồng mới có thể thêm admin
>>>>>>> 61b85c33cb5f6cfbca46896554adff10615dccac
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
    // @dev Check admin.
    function isAdmin(address admin) public view returns (bool) {
        return hasRole(ADMIN_ROLE, admin);
    }
}