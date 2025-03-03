// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Registry} from "../../src/Registry.sol";
import {console} from "forge-std/console.sol";

contract CheckRegistry is Script {
    Registry public registry;
    address constant REGISTRY_ADDRESS = 0x2b4836d81370e37030727E4DCbd9cC5a772cf43A;

    function setUp() public {
        registry = Registry(REGISTRY_ADDRESS);
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Get all merchants
        Registry.Merchant[] memory allMerchants = registry.getAllMerchants();
        console.log("Total number of merchants:", allMerchants.length);

        // Print details of each merchant
        for (uint256 i = 0; i < allMerchants.length; i++) {
            console.log("--------------------------------");
            console.log("\nMerchant", i + 1);
            console.log("UEN:", allMerchants[i].uen);
            console.log("Entity Name:", allMerchants[i].entity_name);
            console.log("Owner Name:", allMerchants[i].owner_name);
            console.log("Wallet Address:", allMerchants[i].wallet_address);
            console.log("--------------------------------");
        }

        vm.stopBroadcast();
    }
}
