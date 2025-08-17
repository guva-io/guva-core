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

// Forward declaration of the mock Curve contract interface
interface IMockCurve {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
}

contract Bank {
    IMiner public minerContract;
    IGuvaNFT public guvaNFT;
    IWorkflow public workflowContract;
    IMockCurve public curveContract;
    IERC20 public pyUSD;
    IERC20 public usdc;

    mapping(address => uint256) public balanceOf;

    modifier onlyMiner() {
        require(minerContract.isMiner(msg.sender), "Bank: Caller is not a miner");
        _;
    }

    constructor(address minerAddress, address guvaNFTAddress, address workflowAddress, address curveAddress, address pyUSDAddress, address usdcAddress) {
        minerContract = IMiner(minerAddress);
        guvaNFT = IGuvaNFT(guvaNFTAddress);
        workflowContract = IWorkflow(workflowAddress);
        curveContract = IMockCurve(curveAddress);
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

    function convert() public {
        uint256 pyUSDBalance = pyUSD.balanceOf(address(this));
        require(pyUSDBalance > 0, "Bank: No PyUSD to convert");

        // Approve the curve contract to spend our PyUSD
        pyUSD.approve(address(curveContract), pyUSDBalance);

        // Perform the exchange. Assuming PyUSD is at index 0 and USDC is at index 1.
        // min_dy is set to 0 for simplicity in this mock context.
        curveContract.exchange(0, 1, pyUSDBalance, 0);
    }

    function withdrawWithUSDC(uint256 amount_) public {
        require(balanceOf[msg.sender] >= amount_, "Bank: Insufficient balance for withdrawal");
        require(usdc.balanceOf(address(this)) >= amount_, "Bank: Insufficient USDC in contract");

        balanceOf[msg.sender] -= amount_;
        usdc.transfer(msg.sender, amount_);
    }

    function withdrawWithPyUSD(uint256 amount_) public {
        require(balanceOf[msg.sender] >= amount_, "Bank: Insufficient balance for withdrawal");
        require(usdc.balanceOf(address(this)) >= amount_, "Bank: Insufficient USDC in contract for conversion");

        balanceOf[msg.sender] -= amount_;

        // Approve the curve contract to spend our USDC
        usdc.approve(address(curveContract), amount_);

        // Perform the exchange from USDC to PyUSD
        // Assuming USDC is at index 1 and PyUSD is at index 0.
        curveContract.exchange(1, 0, amount_, 0);

        // Transfer the received PyUSD to the user
        pyUSD.transfer(msg.sender, amount_);
    }
}
