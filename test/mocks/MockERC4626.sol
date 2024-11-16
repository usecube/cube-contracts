// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

contract MockERC4626 is ERC20, IERC4626 {
    IERC20 private _asset;

    constructor(address asset, string memory name, string memory symbol) ERC20(name, symbol) {
        _asset = IERC20(asset);
    }

    function asset() external view returns (address) {
        return address(_asset);
    }

    function totalAssets() external view returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    function convertToShares(uint256 assets) external pure returns (uint256) {
        return assets; // 1:1 conversion for simplicity
    }

    function convertToAssets(uint256 shares) external pure returns (uint256) {
        return shares; // 1:1 conversion for simplicity
    }

    function maxDeposit(address) external pure returns (uint256) {
        return type(uint256).max;
    }

    function previewDeposit(uint256 assets) external pure returns (uint256) {
        return assets;
    }

    function deposit(uint256 assets, address receiver) external returns (uint256) {
        _asset.transferFrom(msg.sender, address(this), assets);
        _mint(receiver, assets);
        return assets;
    }

    function maxMint(address) external pure returns (uint256) {
        return type(uint256).max;
    }

    function previewMint(uint256 shares) external pure returns (uint256) {
        return shares;
    }

    function mint(uint256 shares, address receiver) external returns (uint256) {
        _asset.transferFrom(msg.sender, address(this), shares);
        _mint(receiver, shares);
        return shares;
    }

    function maxWithdraw(address owner) external view returns (uint256) {
        return balanceOf(owner);
    }

    function previewWithdraw(uint256 assets) external pure returns (uint256) {
        return assets;
    }

    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256) {
        require(balanceOf(owner) >= assets, "Insufficient balance");
        _burn(owner, assets);
        _asset.transfer(receiver, assets);
        return assets;
    }

    function maxRedeem(address owner) external view returns (uint256) {
        return balanceOf(owner);
    }

    function previewRedeem(uint256 shares) external pure returns (uint256) {
        return shares;
    }

    function redeem(uint256 shares, address receiver, address owner) external returns (uint256) {
        require(balanceOf(owner) >= shares, "Insufficient balance");
        _burn(owner, shares);
        _asset.transfer(receiver, shares);
        return shares;
    }
}
