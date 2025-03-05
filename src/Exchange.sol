// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Registry} from "./Registry.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/**
 * @title Cube Exchange
 * @author @dannweeeee
 * @notice Cube Exchange is a contract that allows users to transfer USDC to merchants.
 */
contract Exchange is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    Registry public immutable registry;
    IERC20 public immutable usdcToken;
    IERC4626 public immutable vault;

    uint256 public fee = 100; // 100 basis points fee (1%)
    address public feeCollector;

    uint256 public lastUpdateTime;
    uint256 public lastPricePerShare;

    event Transfer(address indexed from, address indexed to, uint256 amount, string uen);
    event FeeUpdated(uint256 newFee);
    event FeeCollectorUpdated(address newFeeCollector);
    event FeesWithdrawn(address indexed to, uint256 amount);
    event VaultDeposit(address indexed merchant, uint256 assets, uint256 shares);
    event VaultWithdraw(address indexed merchant, uint256 assets, uint256 shares);

    constructor(address _registryAddress, address _usdcAddress, address _vaultAddress) Ownable(msg.sender) {
        require(_registryAddress != address(0), "Invalid registry address");
        require(_usdcAddress != address(0), "Invalid USDC address");
        require(_vaultAddress != address(0), "Invalid vault address");
        registry = Registry(_registryAddress);
        usdcToken = IERC20(_usdcAddress);
        feeCollector = address(this);
        vault = IERC4626(_vaultAddress);
        lastUpdateTime = block.timestamp;
        lastPricePerShare = vault.convertToAssets(1e6);
    }

    /////////////////////////
    /////// FUNCTIONS ///////
    /////////////////////////

    /**
     * @notice Transfer USDC to merchant.
     * @param _uen Merchant's UEN.
     * @param _amount Amount of USDC to transfer to merchant.
     */
    function transferToMerchant(string memory _uen, uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");

        address merchantWalletAddress = registry.getMerchantByUEN(_uen).wallet_address;
        require(merchantWalletAddress != address(0), "Invalid merchant wallet address");

        uint256 feeAmount = (_amount * fee) / 10000;
        uint256 merchantAmount = _amount - feeAmount;

        usdcToken.safeTransferFrom(msg.sender, merchantWalletAddress, merchantAmount);
        if (feeAmount > 0) {
            usdcToken.safeTransferFrom(msg.sender, feeCollector, feeAmount);
        }

        emit Transfer(msg.sender, merchantWalletAddress, merchantAmount, _uen);
    }

    /**
     * @notice Transfer USDC to vault.
     * @param _uen Merchant's UEN.
     * @param _amount Amount of USDC to transfer to vault.
     */
    function transferToVault(string memory _uen, uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");

        address merchantWalletAddress = registry.getMerchantByUEN(_uen).wallet_address;
        require(merchantWalletAddress != address(0), "Invalid merchant wallet address");

        uint256 feeAmount = (_amount * fee) / 10000;
        uint256 vaultAmount = _amount - feeAmount;

        // Transfer USDC from sender to this contract
        usdcToken.safeTransferFrom(msg.sender, address(this), _amount);

        // Transfer fee to fee collector
        if (feeAmount > 0) {
            usdcToken.safeTransfer(feeCollector, feeAmount);
        }

        // Approve vault to spend USDC
        usdcToken.approve(address(vault), vaultAmount);

        // Deposit USDC into vault and mint shares to merchant
        uint256 shares = vault.deposit(vaultAmount, merchantWalletAddress);

        emit Transfer(msg.sender, merchantWalletAddress, vaultAmount, _uen);
        emit VaultDeposit(merchantWalletAddress, vaultAmount, shares);
    }

    /**
     * @notice Withdraw USDC from vault to merchant's wallet.
     * @param _shares Amount of shares to withdraw.
     */
    function withdrawToWallet(uint256 _shares) external nonReentrant {
        address merchantWalletAddress = msg.sender;

        // Check if the caller has enough shares
        uint256 userShares = vault.balanceOf(merchantWalletAddress);
        require(userShares >= _shares, "Insufficient shares");

        // Check if the vault has enough assets to cover the withdrawal
        uint256 assets = vault.convertToAssets(_shares);
        require(vault.totalAssets() >= assets, "Insufficient vault assets");

        // Approve the vault to spend shares on behalf of the user
        vault.approve(address(this), _shares);

        // Withdraw USDC from vault and burn shares
        try vault.redeem(_shares, merchantWalletAddress, merchantWalletAddress) returns (uint256 redeemedAssets) {
            require(redeemedAssets == assets, "Unexpected amount of assets redeemed");
            emit VaultWithdraw(merchantWalletAddress, redeemedAssets, _shares);
        } catch Error(string memory reason) {
            revert(string(abi.encodePacked("Vault redeem failed: ", reason)));
        } catch (bytes memory) /* lowLevelData */ {
            revert("Vault redeem failed with unknown error");
        }
    }

    /**
     * @notice Set the fee.
     * @param _newFee New fee.
     */
    function setFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= 1000, "Fee cannot exceed 10%");
        fee = _newFee;
        emit FeeUpdated(_newFee);
    }

    /**
     * @notice Set the fee collector.
     * @param _newFeeCollector New fee collector.
     */
    function setFeeCollector(address _newFeeCollector) external onlyOwner {
        require(_newFeeCollector != address(0), "Invalid fee collector address");
        feeCollector = _newFeeCollector;
        emit FeeCollectorUpdated(_newFeeCollector);
    }

    /**
     * @notice Withdraw fees.
     * @param _to Withdrawal address.
     * @param _amount Amount of USDC to withdraw.
     */
    function withdrawFees(address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "Invalid withdrawal address");
        require(_amount > 0, "Withdrawal amount must be greater than zero");
        require(_amount <= usdcToken.balanceOf(address(this)), "Insufficient balance");

        usdcToken.safeTransfer(_to, _amount);
        emit FeesWithdrawn(_to, _amount);
    }

    /**
     * @notice Get current price per share
     * @return Current price of 1 share in terms of assets (USDC)
     */
    function getCurrentPricePerShare() public view returns (uint256) {
        return vault.convertToAssets(1e6);
    }

    /**
     * @notice Get vault metrics
     * @return totalAssets Total assets in vault
     * @return totalShares Total shares issued
     * @return pricePerShare Current price per share
     */
    function getVaultMetrics() public view returns (uint256 totalAssets, uint256 totalShares, uint256 pricePerShare) {
        totalAssets = vault.totalAssets();
        totalShares = vault.totalSupply();
        pricePerShare = getCurrentPricePerShare();
    }

    /**
     * @notice Calculate APY between two price points
     * @param startPrice Starting price per share
     * @param endPrice Ending price per share
     * @param timeElapsedInSeconds Time elapsed between prices in seconds
     * @return apy Annual Percentage Yield in basis points (1% = 100)
     */
    function calculateAPY(uint256 startPrice, uint256 endPrice, uint256 timeElapsedInSeconds)
        public
        pure
        returns (uint256 apy)
    {
        require(timeElapsedInSeconds > 0, "Time elapsed must be > 0");
        require(startPrice > 0, "Start price must be > 0");

        // Calculate yield for the period
        uint256 yield = ((endPrice - startPrice) * 1e6) / startPrice;

        // Annualize it (multiply by seconds in year and divide by elapsed time)
        uint256 secondsInYear = 365 days;
        apy = (yield * secondsInYear) / timeElapsedInSeconds;

        return apy;
    }

    /**
     * @notice Get current APY based on last update
     * @return Current APY in basis points (1% = 100)
     */
    function getCurrentAPY() external view returns (uint256) {
        uint256 currentPrice = getCurrentPricePerShare();
        uint256 timeElapsed = block.timestamp - lastUpdateTime;

        return calculateAPY(lastPricePerShare, currentPrice, timeElapsed);
    }

    /**
     * @notice Update the stored price per share
     * @dev This can be called periodically to update the reference point for APY calculations
     */
    function updatePricePerShare() external {
        lastPricePerShare = getCurrentPricePerShare();
        lastUpdateTime = block.timestamp;
    }

    /**
     * @notice Get detailed yield information
     * @return currentPrice Current price per share
     * @return lastPrice Last recorded price per share
     * @return timeSinceLastUpdate Seconds since last update
     * @return currentAPY Current APY in basis points
     */
    function getYieldInfo()
        external
        view
        returns (uint256 currentPrice, uint256 lastPrice, uint256 timeSinceLastUpdate, uint256 currentAPY)
    {
        currentPrice = getCurrentPricePerShare();
        lastPrice = lastPricePerShare;
        timeSinceLastUpdate = block.timestamp - lastUpdateTime;
        currentAPY = calculateAPY(lastPrice, currentPrice, timeSinceLastUpdate);

        return (currentPrice, lastPrice, timeSinceLastUpdate, currentAPY);
    }
}
