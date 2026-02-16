// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {Deploy} from "../script/Deploy.s.sol";
import {BaseVault} from "../src/BaseVault.sol";
import {MockUSDC} from "./mocks/mockUSDC.sol";
import {MockStrategy} from "./mocks/MockStrategy.sol";

contract BaseVaultMultiTest is Test {
    Deploy deployer;

    BaseVault vault;
    MockUSDC usdc;

    MockStrategy strategy1;
    MockStrategy strategy2;

    address user = address(1);

    uint256 constant INITIAL_BALANCE = 1_000_000 ether;

    function setUp() public {
        deployer = new Deploy();

        // Deploy via script
        (vault, usdc, strategy1, strategy2) = deployer.run();

        // Mint funds to user
        usdc.mint(user, INITIAL_BALANCE);

        vm.startPrank(user);
        usdc.approve(address(vault), type(uint256).max);
        vm.stopPrank();
    }

    /* ------------------------------------------------------------ */
    /*                    BASIC ALLOCATION TEST                     */
    /* ------------------------------------------------------------ */

    function testDepositSplitsByWeight() public {
        vm.startPrank(user);
        vault.deposit(100_000 ether, user);
        vm.stopPrank();

        // Expect 70/30 split
        assertEq(strategy1.totalManaged(), 70_000 ether);
        assertEq(strategy2.totalManaged(), 30_000 ether);

        // Vault should hold zero idle funds
        assertEq(usdc.balanceOf(address(vault)), 0);
    }

    /* ------------------------------------------------------------ */
    /*                    PROPORTIONAL WITHDRAW                     */
    /* ------------------------------------------------------------ */

    function testWithdrawPullsProportionally() public {
        vm.startPrank(user);

        vault.deposit(100_000 ether, user);
        vault.withdraw(40_000 ether, user, user);

        vm.stopPrank();

        // Remaining total = 60,000
        // 70% = 42,000
        // 30% = 18,000

        assertEq(strategy1.totalManaged(), 42_000 ether);
        assertEq(strategy2.totalManaged(), 18_000 ether);

        assertEq(usdc.balanceOf(user), INITIAL_BALANCE - 100_000 ether + 40_000 ether);
    }

    /* ------------------------------------------------------------ */
    /*                        YIELD TEST                            */
    /* ------------------------------------------------------------ */

    function testSharePriceIncreasesAfterYield() public {
        vm.startPrank(user);
        vault.deposit(100_000 ether, user);
        vm.stopPrank();

        // Add yield only to strategy1
        strategy1.addYield(50_000 ether);

        uint256 totalAssets = vault.totalAssets();
        assertEq(totalAssets, 150_000 ether);

        vm.startPrank(user);
        uint256 shares = vault.balanceOf(user);
        vault.redeem(shares, user, user);
        vm.stopPrank();

        uint256 finalBalance = usdc.balanceOf(user);

        // Initial 1,000,000 - 100,000 + 150,000
        uint256 expected = INITIAL_BALANCE + 50_000 ether;

        assertGe(finalBalance, expected - 1);
    }

    /* ------------------------------------------------------------ */
    /*                        LOSS TEST                             */
    /* ------------------------------------------------------------ */

    function testSharePriceDecreasesAfterLoss() public {
        vm.startPrank(user);
        vault.deposit(100_000 ether, user);
        vm.stopPrank();

        // Only strategy1 loses 20k
        strategy1.addLoss(20_000 ether);

        uint256 totalAssets = vault.totalAssets();
        assertEq(totalAssets, 80_000 ether);

        vm.startPrank(user);
        uint256 shares = vault.balanceOf(user);
        vault.redeem(shares, user, user);
        vm.stopPrank();

        uint256 finalBalance = usdc.balanceOf(user);

        // 1,000,000 - 100,000 + 80,000 = 980,000
        uint256 expectedFinalBalance = INITIAL_BALANCE - 20_000 ether;

        assertApproxEqAbs(finalBalance, expectedFinalBalance, 1);
    }

    /* ------------------------------------------------------------ */
    /*                  UNEVEN YIELD DRIFT TEST                     */
    /* ------------------------------------------------------------ */

    function testDriftAfterUnevenYield() public {
        vm.startPrank(user);
        vault.deposit(100_000 ether, user);
        vm.stopPrank();

        // strategy1 performs very well
        strategy1.addYield(100_000 ether);

        uint256 totalAssets = vault.totalAssets();
        assertEq(totalAssets, 200_000 ether);

        vm.startPrank(user);
        uint256 shares = vault.balanceOf(user);
        vault.redeem(shares, user, user);
        vm.stopPrank();

        uint256 finalBalance = usdc.balanceOf(user);

        // Should receive full 200k total value
        assertApproxEqAbs(finalBalance, INITIAL_BALANCE + 100_000 ether, 1);
    }

    /* ------------------------------------------------------------ */
    /*                  MULTI-STRATEGY CONSISTENCY                  */
    /* ------------------------------------------------------------ */

    function testTotalAssetsAggregation() public {
        vm.startPrank(user);
        vault.deposit(200_000 ether, user);
        vm.stopPrank();

        strategy1.addYield(30_000 ether);
        strategy2.addYield(20_000 ether);

        uint256 total = vault.totalAssets();

        // 200k + 50k yield
        assertEq(total, 250_000 ether);
    }
}
