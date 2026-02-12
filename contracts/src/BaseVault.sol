// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./strategies/AaveStrategy.sol";

contract BaseVault is ERC4626, Ownable {
    AaveStrategy public strategy;

    constructor(IERC20 _asset, address _strategy)
        ERC20("Tranche Vault Share", "TVS")
        ERC4626(_asset)
        Ownable(msg.sender)
    {
        strategy = AaveStrategy(_strategy);
    }

    /// @dev Override deposit logic
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        // 1️⃣ Transfer + mint (standard behavior)
        super._deposit(caller, receiver, assets, shares);

        // 2️⃣ Invest into strategy
        IERC20(asset()).approve(address(strategy), assets);
        strategy.deposit(assets);
    }

    /// @dev Override withdraw logic
    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
    {
        // 1️⃣ Pull funds back from strategy first
        strategy.withdraw(assets);

        // 2️⃣ Then burn shares + transfer to user
        super._withdraw(caller, receiver, owner, assets, shares);
    }

    function totalAssets() public view override returns (uint256) {
        return IERC20(asset()).balanceOf(address(this)) + strategy.totalAssets();
    }
}
