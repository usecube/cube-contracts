// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Registry} from "./Registry.sol";

contract Exchange is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    Registry public immutable registry;
    IERC20 public immutable usdcToken;

    uint256 public fee = 100; // 100 basis points fee (1%)
    address public feeCollector;

    event Transfer(address indexed from, address indexed to, uint256 amount, string uen);
    event FeeUpdated(uint256 newFee);
    event FeeCollectorUpdated(address newFeeCollector);
    event FeesWithdrawn(address indexed to, uint256 amount);

    constructor(address _registryAddress, address _usdcAddress) Ownable(msg.sender) {
        require(_registryAddress != address(0), "Invalid registry address");
        require(_usdcAddress != address(0), "Invalid USDC address");
        registry = Registry(_registryAddress);
        usdcToken = IERC20(_usdcAddress);
        feeCollector = address(this);
    }

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

    function setFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= 1000, "Fee cannot exceed 10%");
        fee = _newFee;
        emit FeeUpdated(_newFee);
    }

    function setFeeCollector(address _newFeeCollector) external onlyOwner {
        require(_newFeeCollector != address(0), "Invalid fee collector address");
        feeCollector = _newFeeCollector;
        emit FeeCollectorUpdated(_newFeeCollector);
    }

    function withdrawFees(address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "Invalid withdrawal address");
        require(_amount > 0, "Withdrawal amount must be greater than zero");
        require(_amount <= usdcToken.balanceOf(address(this)), "Insufficient balance");

        usdcToken.safeTransfer(_to, _amount);
        emit FeesWithdrawn(_to, _amount);
    }
}
