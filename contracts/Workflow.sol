// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Workflow is Ownable {
    mapping(uint256 => uint256) public rentOf;

    constructor(address initialOwner) Ownable(initialOwner) {}

    function setGPURent(uint256 workflowIndex_, uint256 amount_) public onlyOwner {
        rentOf[workflowIndex_] = amount_;
    }
}
