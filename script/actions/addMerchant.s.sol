// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Registry} from "../../src/Registry.sol";
import {console} from "forge-std/console.sol";

contract AddMerchant is Script {
    Registry public registry;
    address constant REGISTRY_ADDRESS = 0x2b4836d81370e37030727E4DCbd9cC5a772cf43A;

    function setUp() public {
        registry = Registry(REGISTRY_ADDRESS);
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Add merchant
        string memory UEN = "201715518C";
        registry.addMerchant(UEN, "Merchant Name", "Owner Name", msg.sender);

        console.log("Merchant added successfully", UEN);

        vm.stopBroadcast();
    }
}
