//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {XSGD} from "../../src/XSGD.sol";
import {console} from "forge-std/console.sol";

contract DeployXSGD is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        string memory name = "StraitsX Singapore Dollar";
        string memory symbol = "XSGD";
        uint256 initialSupply = 1000000 * 10**18; // 1 million tokens
        
        XSGD xsgd = new XSGD(name, symbol, initialSupply);
        
        console.log("XSGD deployed at:", address(xsgd));
        
        vm.stopBroadcast();
    }
}