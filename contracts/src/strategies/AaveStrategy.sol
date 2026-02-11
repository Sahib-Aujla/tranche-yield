// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IAavePool {
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

contract AaveStrategy {
    using SafeERC20 for IERC20;

    /// -----------------------------------------------------------------------
    /// State
    /// -----------------------------------------------------------------------

    IERC20 public immutable asset;      // USDC
    IAavePool public immutable pool;    // Aave V3 Pool
    address public immutable vault;     // ERC4626 Vault
    IERC20 public immutable aToken;     // aUSDC (yield token)

    /// -----------------------------------------------------------------------
    /// Modifiers
    /// -----------------------------------------------------------------------

    modifier onlyVault() {
        require(msg.sender == vault, "Not vault");
        _;
    }

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(
        address _asset,
        address _aToken,
        address _pool,
        address _vault
    ) {
        asset = IERC20(_asset);
        aToken = IERC20(_aToken);
        pool = IAavePool(_pool);
        vault = _vault;
    }

    /// -----------------------------------------------------------------------
    /// Core Logic
    /// -----------------------------------------------------------------------

    /**
     * @notice Called by vault after deposit
     */
    function deposit(uint256 amount) external onlyVault {
        if (amount == 0) return;

        asset.approve(address(pool), 0);
        asset.approve(address(pool), amount);

        pool.supply(
            address(asset),
            amount,
            address(this),
            0
        );
    }

    /**
     * @notice Called by vault before withdrawal
     */
    function withdraw(uint256 amount) external onlyVault {
        if (amount == 0) return;

        pool.withdraw(
            address(asset),
            amount,
            vault
        );
    }

    /**
     * @notice Total assets managed by strategy (principal + yield)
     */
    function totalAssets() public view returns (uint256) {
        return aToken.balanceOf(address(this));
    }
}
