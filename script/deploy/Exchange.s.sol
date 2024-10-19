// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../../src/Exchange.sol";

contract DeployExchange is Script {
    function run() external {
        vm.startBroadcast();

        address registryAddress = 0x2b4836d81370e37030727E4DCbd9cC5a772cf43A;
        address usdcAddress = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
        address vaultAddress = 0xd580248163CDD5AE3225A700E9f4e7CD525b27b0;

        Exchange exchange = new Exchange(registryAddress, usdcAddress, vaultAddress);

        console.log("Exchange deployed at:", address(exchange));

        vm.stopBroadcast();
    }
}
