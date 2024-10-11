// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Vault} from "../../src/Vault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployVault is Script {
    function run() external {
        address usdcAddress = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;

        vm.startBroadcast();

        Vault vault = new Vault(IERC20(usdcAddress));

        vm.stopBroadcast();

        console.log("Vault deployed at:", address(vault));
    }
}
