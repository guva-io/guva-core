// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// Forward declaration of the Miner contract interface
interface IMiner {
    function isMiner(address) external view returns (bool);
}

// Forward declaration of the GuvaNFT contract interface
interface IGuvaNFT is IERC721 {
    function rent() external view returns (uint256);
}

// Forward declaration of the Workflow contract interface
interface IWorkflow {
    function rentOf(uint256) external view returns (uint256);
}

contract Bank {
    IMiner public minerContract;
    IGuvaNFT public guvaNFT;
    IWorkflow public workflowContract;
    IERC20 public pyUSD;
    IERC20 public usdc;

    mapping(address => uint256) public balanceOf;

    modifier onlyMiner() {
        require(minerContract.isMiner(msg.sender), "Bank: Caller is not a miner");
        _;
    }

    constructor(address minerAddress, address guvaNFTAddress, address workflowAddress, address pyUSDAddress, address usdcAddress) {
        minerContract = IMiner(minerAddress);
        guvaNFT = IGuvaNFT(guvaNFTAddress);
        workflowContract = IWorkflow(workflowAddress);
        pyUSD = IERC20(pyUSDAddress);
        usdc = IERC20(usdcAddress);
    }

    function topUpWithPyUSD(uint256 amount) public {
        require(amount > 0, "Bank: Amount must be greater than zero");
        uint256 initialBalance = pyUSD.balanceOf(address(this));
        pyUSD.transferFrom(msg.sender, address(this), amount);
        uint256 finalBalance = pyUSD.balanceOf(address(this));
        uint256 received = finalBalance - initialBalance;
        balanceOf[msg.sender] += received;
    }

    function topUpWithUSDC(uint256 amount) public {
        require(amount > 0, "Bank: Amount must be greater than zero");
        uint256 initialBalance = usdc.balanceOf(address(this));
        usdc.transferFrom(msg.sender, address(this), amount);
        uint256 finalBalance = usdc.balanceOf(address(this));
        uint256 received = finalBalance - initialBalance;
        balanceOf[msg.sender] += received;
    }

    function spend(address fromAddress_, uint256 nftTokenId_, uint256 workflowIndex_) public onlyMiner {
        uint256 nftRent = guvaNFT.rent();
        uint256 workflowRent = workflowContract.rentOf(workflowIndex_);
        uint256 totalRent = nftRent + workflowRent;

        require(balanceOf[fromAddress_] >= totalRent, "Bank: Insufficient balance");

        address nftOwner = guvaNFT.ownerOf(nftTokenId_);

        balanceOf[fromAddress_] -= totalRent;
        balanceOf[nftOwner] += nftRent;
        balanceOf[msg.sender] += workflowRent;
    }
}
