// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {Exchange} from "../src/Exchange.sol";
import {Registry} from "../src/Registry.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockERC4626} from "./mocks/MockERC4626.sol";

contract ExchangeTest is Test {
    Exchange public exchange;
    Registry public registry;
    MockERC20 public usdc;
    MockERC4626 public vault;

    address public owner;
    address public user;
    address public merchant;
    string constant UEN = "123456789A";
    uint256 constant INITIAL_BALANCE = 1000000 * 10 ** 6; // 1M USDC
    uint256 constant DEFAULT_AMOUNT = 1000 * 10 ** 6; // 1000 USDC

    event Transfer(address indexed from, address indexed to, uint256 amount, string uen);
    event FeeUpdated(uint256 newFee);
    event FeeCollectorUpdated(address newFeeCollector);
    event FeesWithdrawn(address indexed to, uint256 amount);
    event VaultDeposit(address indexed merchant, uint256 assets, uint256 shares);
    event VaultWithdraw(address indexed merchant, uint256 assets, uint256 shares);

    function setUp() public {
        owner = makeAddr("owner");
        user = makeAddr("user");
        merchant = makeAddr("merchant");

        vm.startPrank(owner);

        // Deploy mock contracts
        usdc = new MockERC20("USDC", "USDC", 6);
        vault = new MockERC4626(address(usdc), "Vault USDC", "vUSDC");

        // Deploy registry and add merchant
        registry = new Registry();
        registry.addMerchant(
            UEN, // _uen
            "Test Merchant", // _entity_name
            "Test Owner", // _owner_name
            merchant // _wallet_address
        );

        // Deploy exchange
        exchange = new Exchange(address(registry), address(usdc), address(vault));

        vm.stopPrank();

        // Setup initial balances
        deal(address(usdc), user, INITIAL_BALANCE);
    }

    function test_TransferToMerchant() public {
        vm.startPrank(user);
        usdc.approve(address(exchange), DEFAULT_AMOUNT);

        uint256 feeAmount = (DEFAULT_AMOUNT * exchange.fee()) / 10000;
        uint256 merchantAmount = DEFAULT_AMOUNT - feeAmount;

        vm.expectEmit(true, true, false, true);
        emit Transfer(user, merchant, merchantAmount, UEN);

        exchange.transferToMerchant(UEN, DEFAULT_AMOUNT);

        assertEq(usdc.balanceOf(merchant), merchantAmount);
        assertEq(usdc.balanceOf(address(exchange)), feeAmount);
        vm.stopPrank();
    }

    function test_TransferToVault() public {
        vm.startPrank(user);
        usdc.approve(address(exchange), DEFAULT_AMOUNT);

        uint256 feeAmount = (DEFAULT_AMOUNT * exchange.fee()) / 10000;
        uint256 vaultAmount = DEFAULT_AMOUNT - feeAmount;

        vm.expectEmit(true, true, false, true);
        emit Transfer(user, merchant, vaultAmount, UEN);
        vm.expectEmit(true, false, false, true);
        emit VaultDeposit(merchant, vaultAmount, vaultAmount); // Mock vault returns 1:1 shares

        exchange.transferToVault(UEN, DEFAULT_AMOUNT);

        assertEq(vault.balanceOf(merchant), vaultAmount);
        assertEq(usdc.balanceOf(address(exchange)), feeAmount);
        vm.stopPrank();
    }

    function test_WithdrawToWallet() public {
        // First deposit to vault
        vm.startPrank(user);
        usdc.approve(address(exchange), DEFAULT_AMOUNT);
        exchange.transferToVault(UEN, DEFAULT_AMOUNT);
        vm.stopPrank();

        uint256 feeAmount = (DEFAULT_AMOUNT * exchange.fee()) / 10000;
        uint256 vaultAmount = DEFAULT_AMOUNT - feeAmount;

        // Then withdraw
        vm.startPrank(merchant);
        vm.expectEmit(true, false, false, true);
        emit VaultWithdraw(merchant, vaultAmount, vaultAmount);

        exchange.withdrawToWallet(vaultAmount);

        assertEq(usdc.balanceOf(merchant), vaultAmount);
        assertEq(vault.balanceOf(merchant), 0);
        vm.stopPrank();
    }

    function test_SetFee() public {
        uint256 newFee = 200; // 2%

        vm.prank(owner);
        vm.expectEmit(false, false, false, true);
        emit FeeUpdated(newFee);

        exchange.setFee(newFee);
        assertEq(exchange.fee(), newFee);
    }

    function test_SetFeeCollector() public {
        address newFeeCollector = makeAddr("newFeeCollector");

        vm.prank(owner);
        vm.expectEmit(false, false, false, true);
        emit FeeCollectorUpdated(newFeeCollector);

        exchange.setFeeCollector(newFeeCollector);
        assertEq(exchange.feeCollector(), newFeeCollector);
    }

    function test_WithdrawFees() public {
        // First make a transfer to generate fees
        vm.startPrank(user);
        usdc.approve(address(exchange), DEFAULT_AMOUNT);
        exchange.transferToMerchant(UEN, DEFAULT_AMOUNT);
        vm.stopPrank();

        uint256 feeAmount = (DEFAULT_AMOUNT * exchange.fee()) / 10000;
        address feeReceiver = makeAddr("feeReceiver");

        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit FeesWithdrawn(feeReceiver, feeAmount);

        exchange.withdrawFees(feeReceiver, feeAmount);
        assertEq(usdc.balanceOf(feeReceiver), feeAmount);
    }

    function testFail_TransferToMerchant_InvalidUEN() public {
        vm.prank(user);
        exchange.transferToMerchant("INVALID_UEN", DEFAULT_AMOUNT);
    }

    function testFail_TransferToMerchant_ZeroAmount() public {
        vm.prank(user);
        exchange.transferToMerchant(UEN, 0);
    }

    function testFail_TransferToVault_InvalidUEN() public {
        vm.prank(user);
        exchange.transferToVault("INVALID_UEN", DEFAULT_AMOUNT);
    }

    function testFail_TransferToVault_ZeroAmount() public {
        vm.prank(user);
        exchange.transferToVault(UEN, 0);
    }

    function testFail_WithdrawToWallet_InsufficientShares() public {
        vm.prank(merchant);
        exchange.withdrawToWallet(1000); // No shares deposited
    }

    function testFail_SetFee_NotOwner() public {
        vm.prank(user);
        exchange.setFee(200);
    }

    function testFail_SetFee_TooHigh() public {
        vm.prank(owner);
        exchange.setFee(1001); // > 10%
    }

    function testFail_SetFeeCollector_NotOwner() public {
        vm.prank(user);
        exchange.setFeeCollector(address(1));
    }

    function testFail_SetFeeCollector_ZeroAddress() public {
        vm.prank(owner);
        exchange.setFeeCollector(address(0));
    }

    function testFail_WithdrawFees_NotOwner() public {
        vm.prank(user);
        exchange.withdrawFees(address(1), 100);
    }

    function testFail_WithdrawFees_ZeroAmount() public {
        vm.prank(owner);
        exchange.withdrawFees(address(1), 0);
    }

    function testFail_WithdrawFees_InsufficientBalance() public {
        vm.prank(owner);
        exchange.withdrawFees(address(1), INITIAL_BALANCE);
    }
}
