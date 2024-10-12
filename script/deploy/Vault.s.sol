// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Vault} from "../../src/Vault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract DeployVault is Script {
    function run() external {
        // Address of USDC on Base Sepolia
        address usdcAddress = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;

        // Address of Aave V3 Pool on Base Sepolia
        address aaveV3PoolAddress = 0xbE781D7Bdf469f3d94a62Cdcc407aCe106AEcA74;

        // Address of aBaseUSDC on Base Sepolia
        address aBaseUSDCAddress = 0xfE45Bf4dEF7223Ab1Bf83cA17a4462Ef1647F7FF;

        vm.startBroadcast();

        // Deploy the implementation contract
        Vault vaultImplementation = new Vault();

        // Deploy ProxyAdmin with the sender as the owner
        ProxyAdmin proxyAdmin = new ProxyAdmin(msg.sender);

        // Encode the initialization call
        bytes memory initializeData =
            abi.encodeWithSelector(Vault.initialize.selector, IERC20(usdcAddress), aaveV3PoolAddress, aBaseUSDCAddress);

        // Deploy the proxy
        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(address(vaultImplementation), address(proxyAdmin), initializeData);

        // The proxy address is the address of our upgradeable Vault
        Vault vault = Vault(address(proxy));

        vm.stopBroadcast();

        console.log("Vault implementation deployed at:", address(vaultImplementation));
        console.log("ProxyAdmin deployed at:", address(proxyAdmin));
        console.log("Vault proxy deployed at:", address(vault));
    }
}
