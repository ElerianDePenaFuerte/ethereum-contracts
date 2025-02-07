// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.26;
pragma abicoder v2;

/* solhint-disable no-console*/ // ELERIAN
import {console2} from "forge-std/console2.sol"; // ELERIAN

import {PantosRoles} from "../../src/access/PantosRoles.sol";
import {AccessController} from "../../src/access/AccessController.sol";

import {Script} from "forge-std/Script.sol";
import {Safe} from "@safe/Safe.sol";
import {PantosBaseScript} from "./PantosBaseScript.s.sol";

contract SafeAddresses is PantosBaseScript {
    enum Role {
        PAUSER,
        DEPLOYER,
        MEDIUM_CRITICAL_OPS,
        SUPER_CRITICAL_OPS
    }

    struct RoleInfo {
        string key;
        address address_;
    }

    mapping(Role => RoleInfo) private _roleInfo;
    mapping(string => Role) private _keysToRoles;

    string private constant _rolesJsonExtention = "-ROLES.json";
    string private constant _safeJsonExtention = "-SAFE.json";
    string private constant _rootSerializer = "root";
    string private constant _nonceSerializer = "nonce";
    string private constant _ownersSerializer = "owners";
    string private constant _thresholdSerializer = "threshold";
    string private constant _roleSerializer = "role";

    Blockchain private thisBlockchain;

    modifier onlyValidRoleName(string memory roleName) {
        bool isValidRoleName = false;
        for (uint256 i = 0; i < getRolesLength(); i++) {
            if (
                keccak256(abi.encodePacked(_roleInfo[Role(i)].key)) ==
                keccak256(abi.encodePacked(roleName))
            ) {
                isValidRoleName = true;
                break;
            }
        }
        require(isValidRoleName, "Invalid role name");
        _;
    }

    function getRoleAddress(Role role) public view returns (address) {
        address roleAddress = _roleInfo[role].address_;
        require(roleAddress != address(0), "Error: Address is zero");
        return roleAddress;
    }

    function readRoleAddresses() public {
        string memory path = string.concat(
            thisBlockchain.name,
            _rolesJsonExtention
        );
        string memory json = vm.readFile(path);
        string[] memory keys = vm.parseJsonKeys(json, "$");
        for (uint256 i = 0; i < keys.length; i++) {
            address address_ = vm.parseJsonAddress(
                json,
                string.concat(".", keys[i])
            );
            _roleInfo[_keysToRoles[keys[i]]].address_ = address_;
        }
    }

    function exportPantosRolesAddresses(
        address pauser,
        address deployer,
        address mediumCriticalOps,
        address superCriticalOps
    ) public {
        string memory blockchainName = thisBlockchain.name;
        string memory roles;
        vm.serializeAddress(
            _roleSerializer,
            _roleInfo[Role.PAUSER].key,
            pauser
        );
        vm.serializeAddress(
            _roleSerializer,
            _roleInfo[Role.DEPLOYER].key,
            deployer
        );
        vm.serializeAddress(
            _roleSerializer,
            _roleInfo[Role.MEDIUM_CRITICAL_OPS].key,
            mediumCriticalOps
        );
        roles = vm.serializeAddress(
            _roleSerializer,
            _roleInfo[Role.SUPER_CRITICAL_OPS].key,
            superCriticalOps
        );
        vm.writeJson(
            roles,
            string.concat(blockchainName, _rolesJsonExtention)
        );
    }

    function writeSafeInfo(address[] memory safeAddresses) public {
        string memory finalJson;

        for (uint256 i = 0; i < safeAddresses.length; i++) {
            address payable safeAddress = payable(safeAddresses[i]);

            console2.log("%s safeAddress %s", safeAddress, i);

            Safe safe = Safe(safeAddress); // wrap proxy
            // console2.log("Safe %s: %s", i, safe);
            string memory safeJson;
            vm.serializeUintToHex(safeJson, _nonceSerializer, safe.nonce());
            vm.serializeAddress(safeJson, _ownersSerializer, safe.getOwners());
            safeJson = vm.serializeUintToHex(
                safeJson,
                _thresholdSerializer,
                safe.getThreshold()
            );

            // Add Safe info item to root
            finalJson = vm.serializeString(
                _rootSerializer,
                vm.toString(safeAddress),
                safeJson
            );
        }
        // Write the JSON data to a file
        vm.writeJson(
            finalJson,
            string.concat(thisBlockchain.name, _safeJsonExtention)
        );

        console2.log(
            "File saved: %s",
            string.concat(thisBlockchain.name, _safeJsonExtention)
        );
    }

    function writeAllSafeInfo(AccessController accessController) public {
        address[] memory safeAddresses = new address[](4);
        // safeAddresses[0] = accessController.pauser();
        // safeAddresses[1] = accessController.deployer();
        // safeAddresses[2] = accessController.mediumCriticalOps();
        // safeAddresses[3] = accessController.superCriticalOps();

        console2.log("ADJUSTED ACCESSCONTROLER ADDRESSES");
        safeAddresses[0] = 0xb630E57aa63d1FfcB9f3366a49b7d39708442682;
        safeAddresses[1] = 0xfA934630fDC17eA53a46E1700aE84B8349952F4D;
        safeAddresses[2] = 0x2a8995dC21dC18F6522b951F05865d756DC6ECC2;
        safeAddresses[3] = 0x00a9262b83104e8756e31e1DeD9Dff5F8B08942a;
        writeSafeInfo(safeAddresses);
    }

    function getRole(
        string memory roleName
    ) public view onlyValidRoleName(roleName) returns (Role) {
        return _keysToRoles[roleName];
    }

    function getRolesLength() public pure returns (uint256) {
        return uint256(type(Role).max) + 1;
    }

    constructor() {
        thisBlockchain = determineBlockchain();

        _roleInfo[Role.DEPLOYER] = RoleInfo("deployer", address(0));
        _roleInfo[Role.PAUSER] = RoleInfo("pauser", address(0));
        _roleInfo[Role.MEDIUM_CRITICAL_OPS] = RoleInfo(
            "medium_critical_ops",
            address(0)
        );
        _roleInfo[Role.SUPER_CRITICAL_OPS] = RoleInfo(
            "super_critical_ops",
            address(0)
        );
        for (uint256 i; i < getRolesLength(); i++) {
            _keysToRoles[_roleInfo[Role(i)].key] = Role(i);
        }
    }
}
