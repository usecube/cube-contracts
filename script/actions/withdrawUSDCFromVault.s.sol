// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Exchange} from "../../src/Exchange.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WithdrawUSDCFromVault is Script {
    function run(address exchangeAddress, uint256 sharesToWithdraw) external {
        // Ensure the private key is set in the environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Get the Exchange contract instance
        Exchange exchange = Exchange(exchangeAddress);

        // Get the vault address
        IERC4626 vault = exchange.vault();

        // First approve the Exchange contract to spend your vault shares
        IERC20(address(vault)).approve(exchangeAddress, sharesToWithdraw);

        // Then call withdrawToWallet function
        exchange.withdrawToWallet(sharesToWithdraw);

        vm.stopBroadcast();
    }

    // Helper function to check how many shares you have
    function checkShares(address exchangeAddress, address walletAddress) external view returns (uint256) {
        Exchange exchange = Exchange(exchangeAddress);
        IERC4626 vault = exchange.vault();
        return vault.balanceOf(walletAddress);
    }

    // Helper function to convert shares to assets (USDC)
    function convertSharesToAssets(address exchangeAddress, uint256 shares) external view returns (uint256) {
        Exchange exchange = Exchange(exchangeAddress);
        IERC4626 vault = exchange.vault();
        return vault.convertToAssets(shares);
    }
}
