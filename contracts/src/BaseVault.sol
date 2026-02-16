// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IStrategy.sol";

contract BaseVault is ERC4626, Ownable {
    uint256 public constant MAX_BPS = 10_000;

    IStrategy[] public strategies;
    uint256[] public weights; // basis points (10000 = 100%)

    constructor(IERC20 _asset, IStrategy[] memory _strategies, uint256[] memory _weights)
        ERC20("Tranche Vault Share", "TVS")
        ERC4626(_asset)
        Ownable(msg.sender)
    {
        require(_strategies.length == _weights.length, "Length mismatch");

        uint256 totalWeight;

        for (uint256 i = 0; i < _weights.length; i++) {
            totalWeight += _weights[i];
        }

        require(totalWeight == MAX_BPS, "Weights must equal 100%");

        strategies = _strategies;
        weights = _weights;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        super._deposit(caller, receiver, assets, shares);

        // Allocate across strategies based on weights
        for (uint256 i = 0; i < strategies.length; i++) {
            uint256 allocation = (assets * weights[i]) / MAX_BPS;

            if (allocation > 0) {
                IERC20(asset()).approve(address(strategies[i]), allocation);
                strategies[i].deposit(allocation);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        WITHDRAW LOGIC
    //////////////////////////////////////////////////////////////*/

    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
    {
        uint256 total = totalAssets();
        uint256 len = strategies.length;

        uint256 totalPulled;

        for (uint256 i = 0; i < len; i++) {
            uint256 stratAssets = strategies[i].totalAssets();

            if (stratAssets == 0) continue;

            uint256 portion;

            if (i == len - 1) {
                // Last strategy pulls remainder
                portion = assets - totalPulled;
            } else {
                portion = (assets * stratAssets) / total;
                totalPulled += portion;
            }

            if (portion > 0) {
                strategies[i].withdraw(portion);
            }
        }

        super._withdraw(caller, receiver, owner, assets, shares);
    }

    /*//////////////////////////////////////////////////////////////
                        ACCOUNTING
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view override returns (uint256) {
        uint256 total = IERC20(asset()).balanceOf(address(this));

        for (uint256 i = 0; i < strategies.length; i++) {
            total += strategies[i].totalAssets();
        }

        return total;
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW HELPERS
    //////////////////////////////////////////////////////////////*/

    function strategyCount() external view returns (uint256) {
        return strategies.length;
    }
}
