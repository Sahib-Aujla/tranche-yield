// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MockUSDC} from "./mockUSDC.sol";

contract MockStrategy {
    IERC20 public immutable asset;
    uint256 public totalManaged;

    constructor(address _asset) {
        asset = IERC20(_asset);
    }

    function deposit(uint256 amount) external {
        asset.transferFrom(msg.sender, address(this), amount);
        totalManaged += amount;
    }

    function withdraw(uint256 amount) external {
        require(totalManaged >= amount, "Insufficient assets");
        totalManaged -= amount;
        asset.transfer(msg.sender, amount);
    }

    function totalAssets() external view returns (uint256) {
        return totalManaged;
    }

    //simulating yield to fluctuate price, now only price increases
    function addYield(uint256 amount) external {
        MockUSDC(address(asset)).mint(address(this), amount);
        totalManaged += amount;
    }
}
