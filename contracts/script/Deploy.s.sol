//SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Script.sol";
import {BaseVault} from "../src/BaseVault.sol";
import {MockStrategy} from "../test/mocks/MockStrategy.sol";
import {MockUSDC} from "../test/mocks/mockUSDC.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Deploy is Script {
    function run() external returns (BaseVault vault, MockUSDC usdc, MockStrategy mockStrategy) {
        vm.startBroadcast();
        // Deploy mock USDC
        usdc = new MockUSDC();

        mockStrategy = new MockStrategy(address(usdc));
        vault = new BaseVault(IERC20(address(usdc)), address(mockStrategy));
        vm.stopBroadcast();
    }
}
