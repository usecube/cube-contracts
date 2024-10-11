// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../../src/Exchange.sol";

contract DeployExchange is Script {
    function run() external {
        vm.startBroadcast();

        address registryAddress = 0xF64C3fA7F56b9C59010Be7a96BaB0d08055B3cfE;
        address usdcAddress = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;

        Exchange exchange = new Exchange(registryAddress, usdcAddress);

        console.log("Exchange deployed at:", address(exchange));

        vm.stopBroadcast();
    }
}
