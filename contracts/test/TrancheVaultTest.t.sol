// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {TrancheVault} from "../src/TrancheVault.sol";
import {BaseVault} from "../src/BaseVault.sol";
import {IStrategy} from "../src/interfaces/IStrategy.sol";

import {MockUSDC} from "./mocks/mockUSDC.sol";
import {MockStrategy} from "./mocks/MockStrategy.sol";

contract TrancheVaultTest is Test {
    MockUSDC usdc;
    BaseVault baseVault;
    MockStrategy strategy;
    IStrategy[] strategies = new IStrategy[](1);
    uint256[] weights = new uint256[](1);

    TrancheVault trancheVault;

    address seniorUser = address(1);
    address juniorUser = address(2);

    uint256 constant INITIAL_BALANCE = 1_000_000 ether;

    /*//////////////////////////////////////////////////////////////
                                SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        usdc = new MockUSDC();
        strategy = new MockStrategy(address(usdc));

        strategies[0] = IStrategy(address(strategy));

        weights[0] = 10_000;

        baseVault = new BaseVault(usdc, strategies, weights);

        trancheVault = new TrancheVault(
            address(usdc),
            address(baseVault),
            7 days,
            500 // 5% senior return
        );

        usdc.mint(seniorUser, INITIAL_BALANCE);
        usdc.mint(juniorUser, INITIAL_BALANCE);

        vm.startPrank(seniorUser);
        usdc.approve(address(trancheVault), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(juniorUser);
        usdc.approve(address(trancheVault), type(uint256).max);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT TESTS
    //////////////////////////////////////////////////////////////*/

    function testSeniorAndJuniorDeposit() public {
        vm.prank(seniorUser);
        trancheVault.depositSenior(100_000 ether);

        vm.prank(juniorUser);
        trancheVault.depositJunior(100_000 ether);

        assertEq(trancheVault.seniorDeposits(), 100_000 ether);
        assertEq(trancheVault.juniorDeposits(), 100_000 ether);
    }

    /*//////////////////////////////////////////////////////////////
                        PROFIT WATERFALL
    //////////////////////////////////////////////////////////////*/

    function testProfitWaterfall() public {
        vm.prank(seniorUser);
        trancheVault.depositSenior(100_000 ether);

        vm.prank(juniorUser);
        trancheVault.depositJunior(100_000 ether);

        // Add 40k profit
        strategy.addYield(40_000 ether);

        vm.warp(block.timestamp + 8 days);

        trancheVault.closeEpoch();

        // Senior gets 5% of 100k = 5k

        assertApproxEqAbs(trancheVault.seniorFinalAssets(), 105_000 ether, 1);
        // Remaining goes to junior
        assertApproxEqAbs(trancheVault.juniorFinalAssets(), 135_000 ether, 1);
    }

    /*//////////////////////////////////////////////////////////////
                        LOSS WATERFALL
    //////////////////////////////////////////////////////////////*/

    function testLossWaterfall() public {
        vm.prank(seniorUser);
        trancheVault.depositSenior(100_000 ether);

        vm.prank(juniorUser);
        trancheVault.depositJunior(100_000 ether);

        // Lose 80k
        strategy.addLoss(80_000 ether);

        vm.warp(block.timestamp + 8 days);

        trancheVault.closeEpoch();

        // Junior absorbs first
        assertEq(trancheVault.juniorFinalAssets(), 20_000 ether);
        assertEq(trancheVault.seniorFinalAssets(), 100_000 ether);
    }

    /*//////////////////////////////////////////////////////////////
                    EXTREME LOSS (JUNIOR WIPED)
    //////////////////////////////////////////////////////////////*/

    function testExtremeLossJuniorWiped() public {
        vm.prank(seniorUser);
        trancheVault.depositSenior(100_000 ether);

        vm.prank(juniorUser);
        trancheVault.depositJunior(100_000 ether);

        // Lose 150k
        strategy.addLoss(150_000 ether);

        vm.warp(block.timestamp + 8 days);

        trancheVault.closeEpoch();

        // Junior wiped
        assertEq(trancheVault.juniorFinalAssets(), 0);

        // Senior gets remainder (50k)
        assertEq(trancheVault.seniorFinalAssets(), 50_000 ether);
    }

    /*//////////////////////////////////////////////////////////////
                        REDEMPTION TEST
    //////////////////////////////////////////////////////////////*/

    function testRedemptionWorks() public {
        vm.prank(seniorUser);
        trancheVault.depositSenior(100_000 ether);

        strategy.addYield(10_000 ether);

        vm.warp(block.timestamp + 8 days);

        trancheVault.closeEpoch();

        vm.prank(seniorUser);
        trancheVault.redeemSenior(100_000 ether);

        uint256 finalBalance = usdc.balanceOf(seniorUser);

        // Should receive at least principal
        assertGt(finalBalance, INITIAL_BALANCE - 100_000 ether);
    }

    /*//////////////////////////////////////////////////////////////
                        EPOCH GUARDS
    //////////////////////////////////////////////////////////////*/

    function testCannotRedeemDuringActiveEpoch() public {
        vm.prank(seniorUser);
        trancheVault.depositSenior(100_000 ether);

        vm.expectRevert();
        vm.prank(seniorUser);
        trancheVault.redeemSenior(100_000 ether);
    }

    function testCannotDepositAfterClose() public {
        vm.prank(seniorUser);
        trancheVault.depositSenior(100_000 ether);

        vm.warp(block.timestamp + 8 days);
        trancheVault.closeEpoch();

        vm.expectRevert();
        vm.prank(juniorUser);
        trancheVault.depositJunior(10_000 ether);
    }

    function testCannotCloseEarly() public {
        vm.prank(seniorUser);
        trancheVault.depositSenior(100_000 ether);

        vm.expectRevert();
        trancheVault.closeEpoch();
    }

    /*//////////////////////////////////////////////////////////////
                    ACCOUNTING CONSISTENCY
    //////////////////////////////////////////////////////////////*/

    function testFinalAssetsSumEqualsTotalReturned() public {
        vm.prank(seniorUser);
        trancheVault.depositSenior(100_000 ether);

        vm.prank(juniorUser);
        trancheVault.depositJunior(100_000 ether);

        strategy.addYield(20_000 ether);

        vm.warp(block.timestamp + 8 days);

        trancheVault.closeEpoch();

        uint256 totalFinal = trancheVault.seniorFinalAssets() + trancheVault.juniorFinalAssets();

        assertApproxEqAbs(totalFinal, 220_000 ether, 1);
        
    }
}
