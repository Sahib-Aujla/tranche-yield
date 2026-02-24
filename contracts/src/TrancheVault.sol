// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./BaseVault.sol";
import {TrancheToken} from "./TrancheToken.sol";

contract TrancheVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant MAX_BPS = 10_000;

    IERC20 public immutable asset;
    BaseVault public immutable baseVault;

    // Tranche Tokens
    TrancheToken public seniorToken;
    TrancheToken public juniorToken;

    // Epoch
    uint256 public epochId;
    uint256 public epochStart;
    uint256 public epochDuration;
    bool public epochOpen;

    // Accounting
    uint256 public seniorDeposits;
    uint256 public juniorDeposits;

    uint256 public seniorFinalAssets;
    uint256 public juniorFinalAssets;

    // Fixed senior return per epoch (ex: 500 = 5%)
    uint256 public seniorReturnBps;

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _asset,
        address _baseVault,
        uint256 _epochDuration,
        uint256 _seniorReturnBps
    ) Ownable(msg.sender) {
        require(_asset != address(0), "Invalid asset");
        require(_baseVault != address(0), "Invalid vault");
        require(_seniorReturnBps <= MAX_BPS, "Invalid BPS");

        asset = IERC20(_asset);
        baseVault = BaseVault(_baseVault);
        epochDuration = _epochDuration;
        seniorReturnBps = _seniorReturnBps;

        seniorToken = new TrancheToken("Senior Tranche Token", "SENIOR",address(this));
        juniorToken = new TrancheToken("Junior Tranche Token", "JUNIOR",address(this));

        _startNewEpoch();
    }

    /*//////////////////////////////////////////////////////////////
                            EPOCH MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function _startNewEpoch() internal {
        epochId++;
        epochStart = block.timestamp;
        epochOpen = true;

        seniorDeposits = 0;
        juniorDeposits = 0;
        seniorFinalAssets = 0;
        juniorFinalAssets = 0;
    }

    function closeEpoch() external onlyOwner nonReentrant {
        require(epochOpen, "Already closed");
        require(
            block.timestamp >= epochStart + epochDuration,
            "Epoch not finished"
        );

        epochOpen = false;

        // Withdraw everything from BaseVault
        uint256 shares = baseVault.balanceOf(address(this));
        baseVault.redeem(shares, address(this), address(this));

        uint256 totalAssetsReturned = asset.balanceOf(address(this));

        _applyWaterfall(totalAssetsReturned);
    }

    function startNextEpoch() external onlyOwner {
        require(!epochOpen, "Epoch still active");
        _startNewEpoch();
    }

    /*//////////////////////////////////////////////////////////////
                            DEPOSIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function depositSenior(uint256 amount) external nonReentrant {
        require(epochOpen, "Epoch closed");
        require(amount > 0, "Zero amount");

        asset.safeTransferFrom(msg.sender, address(this), amount);

        seniorDeposits += amount;
        _mint(address(seniorToken), msg.sender, amount);

        _pushToBaseVault(amount);
    }

    function depositJunior(uint256 amount) external nonReentrant {
        require(epochOpen, "Epoch closed");
        require(amount > 0, "Zero amount");

        asset.safeTransferFrom(msg.sender, address(this), amount);

        juniorDeposits += amount;
        _mint(address(juniorToken), msg.sender, amount);

        _pushToBaseVault(amount);
    }

    function _pushToBaseVault(uint256 amount) internal {
        asset.approve(address(baseVault), amount);
        baseVault.deposit(amount, address(this));
    }

    /*//////////////////////////////////////////////////////////////
                            WATERFALL LOGIC
    //////////////////////////////////////////////////////////////*/

    function _applyWaterfall(uint256 totalAssets) internal {
        uint256 totalPrincipal = seniorDeposits + juniorDeposits;

        if (totalAssets >= totalPrincipal) {
            uint256 profit = totalAssets - totalPrincipal;

            uint256 seniorFixedReturn =
                (seniorDeposits * seniorReturnBps) / MAX_BPS;

            if (profit >= seniorFixedReturn) {
                seniorFinalAssets = seniorDeposits + seniorFixedReturn;
                juniorFinalAssets =
                    totalAssets -
                    seniorFinalAssets;
            } else {
                seniorFinalAssets =
                    seniorDeposits +
                    profit;
                juniorFinalAssets = juniorDeposits;
            }
        } else {
            uint256 loss = totalPrincipal - totalAssets;

            if (loss >= juniorDeposits) {
                juniorFinalAssets = 0;
                seniorFinalAssets =
                    totalAssets;
            } else {
                juniorFinalAssets =
                    juniorDeposits -
                    loss;
                seniorFinalAssets =
                    seniorDeposits;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                            REDEMPTION
    //////////////////////////////////////////////////////////////*/

    function redeemSenior(uint256 amount) external nonReentrant {
        require(!epochOpen, "Epoch active");

        uint256 totalSupply = seniorToken.totalSupply();
        require(totalSupply > 0, "No supply");

        uint256 payout =
            (amount * seniorFinalAssets) / totalSupply;

        _burn(address(seniorToken), msg.sender, amount);
        asset.safeTransfer(msg.sender, payout);
    }

    function redeemJunior(uint256 amount) external nonReentrant {
        require(!epochOpen, "Epoch active");

        uint256 totalSupply = juniorToken.totalSupply();
        require(totalSupply > 0, "No supply");

        uint256 payout =
            (amount * juniorFinalAssets) / totalSupply;

        _burn(address(juniorToken), msg.sender, amount);
        asset.safeTransfer(msg.sender, payout);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL TOKEN OPS
    //////////////////////////////////////////////////////////////*/

    function _mint(address token, address to, uint256 amount) internal {
        ERC20(token).transfer(to, amount);
    }

    function _burn(address token, address from, uint256 amount) internal {
        ERC20(token).transferFrom(from, address(this), amount);
    }
}