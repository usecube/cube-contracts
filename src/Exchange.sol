// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Registry} from "./Registry.sol";

contract Exchange is ReentrancyGuard {
    using SafeERC20 for IERC20;

    Registry public immutable registry;
    IERC20 public immutable usdcToken;

    event Transfer(address indexed from, address indexed to, uint256 amount, string uen);

    constructor(address _registryAddress, address _usdcAddress) {
        require(_registryAddress != address(0), "Invalid registry address");
        require(_usdcAddress != address(0), "Invalid USDC address");
        registry = Registry(_registryAddress);
        usdcToken = IERC20(_usdcAddress);
    }

    function transfer(string memory _uen, uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");

        Registry.Merchant memory merchant = registry.getMerchantByUEN(_uen);
        require(merchant.wallet_address != address(0), "Invalid merchant wallet address");

        usdcToken.safeTransferFrom(msg.sender, merchant.wallet_address, _amount);

        emit Transfer(msg.sender, merchant.wallet_address, _amount, _uen);
    }

    function getMerchantWalletAddress(string memory _uen) external view returns (address) {
        Registry.Merchant memory merchant = registry.getMerchantByUEN(_uen);
        return merchant.wallet_address;
    }

    function getUSDCBalance(address _account) external view returns (uint256) {
        return usdcToken.balanceOf(_account);
    }
}
