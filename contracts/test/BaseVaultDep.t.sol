// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {Deploy} from "../script/Deploy.s.sol";
import {BaseVault} from "../src/BaseVault.sol";
import {MockUSDC} from "./mocks/mockUSDC.sol";
import {MockStrategy} from "./mocks/MockStrategy.sol";

contract BaseVaultTest is Test {
    Deploy deployer;

    BaseVault vault;
    MockUSDC usdc;
    MockStrategy strategy;
    MockStrategy strategy2;


    address user = address(1);

    function setUp() public {
        deployer = new Deploy();

        // Deploy contracts via script
        (vault, usdc, strategy) = deployer.run();

        // Mint USDC to user
        usdc.mint(user, 1_000_000 ether);

        vm.startPrank(user);
        usdc.approve(address(vault), type(uint256).max);
        vm.stopPrank();
    }

    /* ------------------------------------------------------------ */
    /*                        TESTS                                 */
    /* ------------------------------------------------------------ */

    function testDepositInvestsIntoStrategy() public {
        vm.startPrank(user);

        vault.deposit(100_000 ether, user);

        vm.stopPrank();

        assertEq(usdc.balanceOf(address(vault)), 0);
        assertEq(strategy.totalManaged(), 100_000 ether);
    }

    function testWithdrawPullsFromStrategy() public {
        vm.startPrank(user);

        vault.deposit(100_000 ether, user);
        vault.withdraw(40_000 ether, user, user);

        vm.stopPrank();

        assertEq(strategy.totalManaged(), 60_000 ether);
        assertEq(usdc.balanceOf(user), 940_000 ether);
    }

    function testSharePriceIncreasesAfterYield() public {
        vm.startPrank(user);
        vault.deposit(100_000 ether, user);
        vm.stopPrank();

        // Simulate yield
        strategy.addYield(50_000 ether);

        assertEq(vault.totalAssets(), 150_000 ether);

        vm.startPrank(user);
        uint256 shares = vault.balanceOf(user);
        vault.redeem(shares, user, user);
        vm.stopPrank();

        // User should end up with original + profit
        uint256 finalBalance = usdc.balanceOf(user);
        uint256 initialBalance = 1_000_000 ether;
        uint256 expectedProfit = 50_000 ether;
        assertGe(finalBalance, initialBalance + expectedProfit - 1);
    }

    function testSharePriceDecreasesAfterLoss() public {
        vm.startPrank(user);

        usdc.approve(address(vault), type(uint256).max);
        vault.deposit(100_000 ether, user);

        vm.stopPrank();

        // simulate loss
        strategy.addLoss(20_000 ether);

        uint256 assetsAfterLoss = vault.totalAssets();

        assertEq(assetsAfterLoss, 80_000 ether);

        vm.startPrank(user);

        uint256 shares = vault.balanceOf(user);
        vault.redeem(shares, user, user);

        uint256 finalBalance = usdc.balanceOf(user);

        // user should receive approx 80,000
        uint256 expectedFinalBalance = 980_000 ether;
        assertApproxEqAbs(finalBalance, expectedFinalBalance, 1);

        vm.stopPrank();
    }
}
