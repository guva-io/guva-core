// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockPyUSD is ERC20 {
    constructor() ERC20("Mock PyUSD", "mPYUSD") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
