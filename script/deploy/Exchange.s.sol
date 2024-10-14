// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../../src/Exchange.sol";

contract DeployExchange is Script {
    function run() external {
        vm.startBroadcast();

        address registryAddress = 0x9d69b9b2907Bba74E65Aa6c87B2284fF0F0931e0;
        address usdcAddress = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;

        Exchange exchange = new Exchange(registryAddress, usdcAddress);

        console.log("Exchange deployed at:", address(exchange));

        vm.stopBroadcast();
    }
}
