// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TrancheToken is ERC20 {

    address public immutable vault;

    modifier onlyVault() {
        require(msg.sender == vault, "Not vault");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address _vault
    ) ERC20(name, symbol) {
        vault = _vault;
    }

    function mint(address to, uint256 amount) external onlyVault {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyVault {
        _burn(from, amount);
    }
}