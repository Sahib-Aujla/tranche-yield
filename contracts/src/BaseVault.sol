// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BaseVault is ERC4626, Ownable {
    constructor(IERC20 _asset) ERC20("Tranche Vault Share", "TVS") ERC4626(_asset) Ownable(msg.sender) {}
}
