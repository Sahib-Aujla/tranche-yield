// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IStrategy.sol";

contract StakingStrategy is IStrategy {
    IERC20 public immutable asset;
    address public immutable vault;

    uint256 public totalStaked;
    uint256 public rewardRatePerSecond; // simulated linear yield
    uint256 public lastUpdate;
    uint256 public accruedRewards;

    modifier onlyVault() {
        require(msg.sender == vault, "Not vault");
        _;
    }

    constructor(address _asset, address _vault, uint256 _rewardRatePerSecond) {
        require(_asset != address(0), "Invalid asset");
        require(_vault != address(0), "Invalid vault");

        asset = IERC20(_asset);
        vault = _vault;
        rewardRatePerSecond = _rewardRatePerSecond;
        lastUpdate = block.timestamp;
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function _accrue() internal {
        if (totalStaked == 0) {
            lastUpdate = block.timestamp;
            return;
        }

        uint256 timeElapsed = block.timestamp - lastUpdate;

        if (timeElapsed > 0) {
            uint256 reward = timeElapsed * rewardRatePerSecond;
            accruedRewards += reward;
            lastUpdate = block.timestamp;
        }
    }

    /*//////////////////////////////////////////////////////////////
                            VAULT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 amount) external override onlyVault {
        require(amount > 0, "Zero amount");

        _accrue();

        asset.transferFrom(msg.sender, address(this), amount);
        totalStaked += amount;
    }

    function withdraw(uint256 amount) external override onlyVault {
        require(amount > 0, "Zero amount");

        _accrue();

        require(amount <= totalAssets(), "Insufficient assets");

        // Withdraw from principal first
        if (amount <= totalStaked) {
            totalStaked -= amount;
        } else {
            uint256 rewardPortion = amount - totalStaked;
            totalStaked = 0;

            require(rewardPortion <= accruedRewards, "Reward underflow");
            accruedRewards -= rewardPortion;
        }

        asset.transfer(vault, amount);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view override returns (uint256) {
        uint256 pending;

        if (totalStaked > 0) {
            uint256 timeElapsed = block.timestamp - lastUpdate;
            pending = timeElapsed * rewardRatePerSecond;
        }

        return totalStaked + accruedRewards + pending;
    }
}
