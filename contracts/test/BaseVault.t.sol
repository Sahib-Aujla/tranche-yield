// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/BaseVault.sol";
import "./mocks/mockUSDC.sol";
import "./mocks/MockStrategy.sol";

contract BaseVaultsTest is Test {
    MockUSDC usdc;
    BaseVault vault;

    address user = address(1);

    function setUp() public {
        usdc = new MockUSDC();
        MockStrategy strategy = new MockStrategy(address(usdc));
        vault = new BaseVault(IERC20(address(usdc)), address(strategy));

        usdc.mint(user, 1_0000_000);
    }

    function testDeposit() public {
        vm.startPrank(user);
        usdc.approve(address(vault), type(uint256).max);
        vault.deposit(500_000, user);
        assertEq(vault.balanceOf(user), 500_000);
        //assertEq(usdc.balanceOf(address(vault)), 500_000);
        vm.stopPrank();
    }

    function testWithdraw() public {
        vm.startPrank(user);
        usdc.approve(address(vault), 500_000);
        vault.deposit(400_000, user);
        assertEq(vault.balanceOf(user), 400_000);
       // assertEq(usdc.balanceOf(address(vault)), 400_000);
        vault.withdraw(100_000, user, user);
        //assertEq(vault.balanceOf(user), 300_000);
        //assertEq(usdc.balanceOf(address(vault)), 300_000);
        vm.stopPrank();
    }

    function testRedeem() public {
        vm.startPrank(user);
        usdc.approve(address(vault), 500_000);
        vault.deposit(400_000, user);
        assertEq(vault.balanceOf(user), 400_000);
        //assertEq(usdc.balanceOf(address(vault)), 400_000);
        vault.redeem(100_000, user, user);
        assertEq(vault.balanceOf(user), 300_000);
        //assertEq(usdc.balanceOf(address(vault)), 300_000);
        vm.stopPrank();
    }

    function testMint() public {
        vm.startPrank(user);
        usdc.approve(address(vault), type(uint256).max);
        vault.mint(500_000, user);
        assertEq(vault.balanceOf(user), 500_000);
        //assertEq(usdc.balanceOf(address(vault)), 500_000);
        vm.stopPrank();
    }

    function testWithdrawWithApproval() public {
        address operator = address(2);

        vm.startPrank(user);
        usdc.approve(address(vault), 100_000);
        vault.deposit(100_000, user);
        vault.approve(operator, 50_000); // approve shares
        vm.stopPrank();

        vm.prank(operator);
        vault.withdraw(50_000, operator, user);

        assertEq(vault.balanceOf(user), 50_000);
    }
}
