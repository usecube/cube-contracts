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
    MockERC20 public xsgd;
    MockERC4626 public vault;

    address public owner;
    address public user;
    address public merchant;
    string constant UEN = "123456789A";
    uint256 constant INITIAL_BALANCE = 1000000 * 10 ** 6; // 1M ERC20
    uint256 constant DEFAULT_AMOUNT = 1000 * 10 ** 6; // 1000 ERC20

    event Transfer(address indexed from, address indexed to, uint256 amount, string uen);
    event FeeUpdated(uint256 newFee);
    event FeeCollectorUpdated(address newFeeCollector);
    event FeesWithdrawn(address indexed to, uint256 amount);
    event VaultDeposit(address indexed merchant, uint256 assets, uint256 shares);
    event VaultWithdraw(address indexed merchant, uint256 assets, uint256 shares);

    /**
     * @notice Setup the test.
     */
    function setUp() public {
        owner = makeAddr("owner");
        user = makeAddr("user");
        merchant = makeAddr("merchant");

        vm.startPrank(owner);

        // Deploy mock contracts
        usdc = new MockERC20("USDC", "USDC", 6);
        xsgd = new MockERC20("xSGD", "xSGD", 18);
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
        exchange = new Exchange(address(registry), address(usdc), address(xsgd), address(vault));

        vm.stopPrank();

        // Setup initial balances
        deal(address(usdc), user, INITIAL_BALANCE);
        deal(address(xsgd), user, INITIAL_BALANCE);
    }

    /**
     * @notice Test the transferUsdcToMerchant function.
     */
    function test_TransferUsdcToMerchant() public {
        vm.startPrank(user);
        usdc.approve(address(exchange), DEFAULT_AMOUNT);

        uint256 feeAmount = (DEFAULT_AMOUNT * exchange.fee()) / 10000;
        uint256 merchantAmount = DEFAULT_AMOUNT - feeAmount;

        vm.expectEmit(true, true, false, true);
        emit Transfer(user, merchant, merchantAmount, UEN);

        exchange.transferUsdcToMerchant(UEN, DEFAULT_AMOUNT);

        assertEq(usdc.balanceOf(merchant), merchantAmount);
        assertEq(usdc.balanceOf(address(exchange)), feeAmount);
        vm.stopPrank();
    }

    /**
     * @notice Test the transferXsgdToMerchant function.
     */
    function test_TransferXsgdToMerchant() public {
        vm.startPrank(user);
        xsgd.approve(address(exchange), DEFAULT_AMOUNT);

        uint256 feeAmount = (DEFAULT_AMOUNT * exchange.fee()) / 10000;
        uint256 merchantAmount = DEFAULT_AMOUNT - feeAmount;

        vm.expectEmit(true, true, false, true);
        emit Transfer(user, merchant, merchantAmount, UEN);

        exchange.transferXsgdToMerchant(UEN, DEFAULT_AMOUNT);

        assertEq(xsgd.balanceOf(merchant), merchantAmount);
        assertEq(xsgd.balanceOf(address(exchange)), feeAmount);
        vm.stopPrank();
    }

    /////////////////
    // VAULT TESTS //
    /////////////////

    /**
     * @notice Test the transferToVault function.
     */
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

    /**
     * @notice Test the withdrawToWallet function.
     */
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

    ///////////////
    // FEE TESTS //
    ///////////////

    /**
     * @notice Test the setFee function.
     */
    function test_SetFee() public {
        uint256 newFee = 200; // 2%

        vm.prank(owner);
        vm.expectEmit(false, false, false, true);
        emit FeeUpdated(newFee);

        exchange.setFee(newFee);
        assertEq(exchange.fee(), newFee);
    }

    /**
     * @notice Test the setFeeCollector function.
     */
    function test_SetFeeCollector() public {
        address newFeeCollector = makeAddr("newFeeCollector");

        vm.prank(owner);
        vm.expectEmit(false, false, false, true);
        emit FeeCollectorUpdated(newFeeCollector);

        exchange.setFeeCollector(newFeeCollector);
        assertEq(exchange.feeCollector(), newFeeCollector);
    }

    /**
     * @notice Test the withdrawUsdcFees function.
     */
    function test_WithdrawUsdcFees() public {
        // First make a transfer to generate fees
        vm.startPrank(user);
        usdc.approve(address(exchange), DEFAULT_AMOUNT);
        exchange.transferUsdcToMerchant(UEN, DEFAULT_AMOUNT);
        vm.stopPrank();

        uint256 feeAmount = (DEFAULT_AMOUNT * exchange.fee()) / 10000;
        address feeReceiver = makeAddr("feeReceiver");

        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit FeesWithdrawn(feeReceiver, feeAmount);

        exchange.withdrawUsdcFees(feeReceiver, feeAmount);
        assertEq(usdc.balanceOf(feeReceiver), feeAmount);
    }

    /**
     * @notice Test the withdrawXsgdFees function.
     */
    function test_WithdrawXsgdFees() public {
        // First make a transfer to generate fees
        vm.startPrank(user);
        xsgd.approve(address(exchange), DEFAULT_AMOUNT);
        exchange.transferXsgdToMerchant(UEN, DEFAULT_AMOUNT);
        vm.stopPrank();

        uint256 feeAmount = (DEFAULT_AMOUNT * exchange.fee()) / 10000;
        address feeReceiver = makeAddr("feeReceiver");

        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit FeesWithdrawn(feeReceiver, feeAmount);

        exchange.withdrawXsgdFees(feeReceiver, feeAmount);
        assertEq(xsgd.balanceOf(feeReceiver), feeAmount);
    }

    //////////////////
    // REVERT TESTS //
    //////////////////

    /**
     * @notice Test the revert when the transferUsdcToMerchant function is called with an invalid UEN.
     */
    function test_RevertWhen_TransferUsdcToMerchant_InvalidUEN() public {
        vm.startPrank(user);
        vm.expectRevert();
        exchange.transferUsdcToMerchant("INVALID_UEN", DEFAULT_AMOUNT);
    }

    /**
     * @notice Test the revert when the transferUsdcToMerchant function is called with a zero amount.
     */
    function test_RevertWhen_TransferUsdcToMerchant_ZeroAmount() public {
        vm.startPrank(user);
        vm.expectRevert();
        exchange.transferUsdcToMerchant(UEN, 0);
    }

    /**
     * @notice Test the revert when the transferXsgdToMerchant function is called with an invalid UEN.
     */
    function test_RevertWhen_TransferXsgdToMerchant_InvalidUEN() public {
        vm.startPrank(user);
        vm.expectRevert();
        exchange.transferXsgdToMerchant("INVALID_UEN", DEFAULT_AMOUNT);
    }

    /**
     * @notice Test the revert when the transferXsgdToMerchant function is called with a zero amount.
     */
    function test_RevertWhen_TransferXsgdToMerchant_ZeroAmount() public {
        vm.startPrank(user);
        vm.expectRevert();
        exchange.transferXsgdToMerchant(UEN, 0);
    }

    /**
     * @notice Test the revert when the transferToVault function is called with an invalid UEN.
     */
    function test_RevertWhen_TransferToVault_InvalidUEN() public {
        vm.startPrank(user);
        vm.expectRevert();
        exchange.transferToVault("INVALID_UEN", DEFAULT_AMOUNT);
    }

    /**
     * @notice Test the revert when the transferToVault function is called with a zero amount.
     */
    function test_RevertWhen_TransferToVault_ZeroAmount() public {
        vm.startPrank(user);
        vm.expectRevert();
        exchange.transferToVault(UEN, 0);
    }

    /**
     * @notice Test the revert when the withdrawToWallet function is called with an insufficient number of shares.
     */
    function test_RevertWhen_WithdrawToWallet_InsufficientShares() public {
        vm.startPrank(merchant);
        vm.expectRevert();
        exchange.withdrawToWallet(1000); // No shares deposited
    }

    /**
     * @notice Test the revert when the setFee function is called by a non-owner.
     */
    function test_RevertWhen_SetFee_NotOwner() public {
        vm.startPrank(user);
        vm.expectRevert();
        exchange.setFee(200);
    }

    /**
     * @notice Test the revert when the setFee function is called with a fee greater than 10%.
     */
    function test_RevertWhen_SetFee_TooHigh() public {
        vm.startPrank(owner);
        vm.expectRevert();
        exchange.setFee(1001); // > 10%
    }

    /**
     * @notice Test the revert when the setFeeCollector function is called by a non-owner.
     */
    function test_RevertWhen_SetFeeCollector_NotOwner() public {
        vm.startPrank(user);
        vm.expectRevert();
        exchange.setFeeCollector(address(1));
    }

    /**
     * @notice Test the revert when the setFeeCollector function is called with a zero address.
     */
    function test_RevertWhen_SetFeeCollector_ZeroAddress() public {
        vm.startPrank(owner);
        vm.expectRevert();
        exchange.setFeeCollector(address(0));
    }

    /**
     * @notice Test the revert when the withdrawUsdcFees function is called by a non-owner.
     */
    function test_RevertWhen_WithdrawUsdcFees_NotOwner() public {
        vm.startPrank(user);
        vm.expectRevert();
        exchange.withdrawUsdcFees(address(1), 100);
    }

    /**
     * @notice Test the revert when the withdrawUsdcFees function is called with a zero amount.
     */
    function test_RevertWhen_WithdrawUsdcFees_ZeroAmount() public {
        vm.startPrank(owner);
        vm.expectRevert();
        exchange.withdrawUsdcFees(address(1), 0);
    }

    /**
     * @notice Test the revert when the withdrawUsdcFees function is called with an insufficient balance.
     */
    function test_RevertWhen_WithdrawFees_InsufficientBalance() public {
        vm.startPrank(owner);
        vm.expectRevert();
        exchange.withdrawUsdcFees(address(1), INITIAL_BALANCE);
    }

    /**
     * @notice Test the revert when the withdrawXsgdFees function is called by a non-owner.
     */
    function test_RevertWhen_WithdrawXsgdFees_NotOwner() public {
        vm.startPrank(user);
        vm.expectRevert();
        exchange.withdrawXsgdFees(address(1), 100);
    }

    /**
     * @notice Test the revert when the withdrawXsgdFees function is called with a zero amount.
     */
    function test_RevertWhen_WithdrawXsgdFees_ZeroAmount() public {
        vm.startPrank(owner);
        vm.expectRevert();
        exchange.withdrawXsgdFees(address(1), 0);
    }

    /**
     * @notice Test the revert when the withdrawXsgdFees function is called with an insufficient balance.
     */
    function test_RevertWhen_WithdrawXsgdFees_InsufficientBalance() public {
        vm.startPrank(owner);
        vm.expectRevert();
        exchange.withdrawXsgdFees(address(1), INITIAL_BALANCE);
    }
}
