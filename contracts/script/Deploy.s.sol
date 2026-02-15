//SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Script.sol";
import {BaseVault} from "../src/BaseVault.sol";
import {MockStrategy} from "../test/mocks/MockStrategy.sol";
import {MockUSDC} from "../test/mocks/mockUSDC.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/interfaces/IStrategy.sol";

contract Deploy is Script {
    function run()
        external
        returns (BaseVault vault, MockUSDC usdc, MockStrategy mockStrategy, MockStrategy mockStrategy2)
    {
        vm.startBroadcast();
        // Deploy mock USDC
        usdc = new MockUSDC();

        mockStrategy = new MockStrategy(address(usdc));
        mockStrategy2 = new MockStrategy(address(usdc));
        IStrategy[] memory strategies = new IStrategy[](2);
        strategies[0] = IStrategy(address(mockStrategy));
        strategies[1] = IStrategy(address(mockStrategy2));
        uint256[] memory weights = new uint256[](2);
        weights[0] = 7000; // 50%
        weights[1] = 3000; // 50%
        vault = new BaseVault(IERC20(address(usdc)), strategies, weights);
        vm.stopBroadcast();
    }
}
