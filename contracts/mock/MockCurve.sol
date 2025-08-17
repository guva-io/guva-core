// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Mock ERC20 interface for minting
interface IMintableERC20 is IERC20 {
    function mint(address to, uint256 amount) external;
}

contract MockCurve {
    IMintableERC20 public pyUSD;
    IMintableERC20 public usdc;

    constructor(address pyUSDAddress, address usdcAddress) {
        pyUSD = IMintableERC20(pyUSDAddress);
        usdc = IMintableERC20(usdcAddress);
        // Pre-fund the mock curve contract with a large amount of USDC
        usdc.mint(address(this), 1000000 * 10**18);
    }

    // Simulates a 1:1 exchange from PyUSD to USDC
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) public {
        // Unused parameters to match the real interface
        i; j; min_dy;

        // Pull PyUSD from the caller
        pyUSD.transferFrom(msg.sender, address(this), dx);
        // Send USDC back to the caller
        usdc.transfer(msg.sender, dx);
    }
}
