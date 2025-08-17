const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("Overall System Test", function () {
    let owner, miner, creator, user;
    let guvaNFT, minerContract, workflow, bank;
    let mockPyUSD, mockUSDC, mockCurve;

    before(async function () {
        [owner, miner, creator, user] = await ethers.getSigners();

        // Deploy Mock Tokens
        const MockPyUSD = await ethers.getContractFactory("MockPyUSD");
        mockPyUSD = await MockPyUSD.deploy();
        const mockPyUSDAddress = await mockPyUSD.getAddress();

        const MockUSDC = await ethers.getContractFactory("MockUSDC");
        mockUSDC = await MockUSDC.deploy();
        const mockUSDCAddress = await mockUSDC.getAddress();

        // Deploy Mock Curve
        const MockCurve = await ethers.getContractFactory("MockCurve");
        mockCurve = await MockCurve.deploy(mockPyUSDAddress, mockUSDCAddress);
        const mockCurveAddress = await mockCurve.getAddress();

        // Pre-fund the mock curve with a large amount of USDC
        await mockUSDC.mint(mockCurveAddress, ethers.parseUnits("1000000", 18));

        // Deploy GuvaNFT
        const GuvaNFT = await ethers.getContractFactory("GuvaNFT");
        guvaNFT = await GuvaNFT.deploy();
        const guvaNFTAddress = await guvaNFT.getAddress();

        // Deploy Miner Contract
        const Miner = await ethers.getContractFactory("Miner");
        minerContract = await Miner.deploy(guvaNFTAddress);
        const minerContractAddress = await minerContract.getAddress();

        // Deploy Workflow
        const Workflow = await ethers.getContractFactory("Workflow");
        workflow = await Workflow.deploy(owner.address);
        const workflowAddress = await workflow.getAddress();

        // Deploy Bank
        const Bank = await ethers.getContractFactory("Bank");
        bank = await Bank.deploy(
            minerContractAddress,
            guvaNFTAddress,
            workflowAddress,
            mockCurveAddress,
            mockPyUSDAddress,
            mockUSDCAddress
        );
    });

    it("should simulate the entire workflow and verify balances", async function () {
        const bankAddress = await bank.getAddress();
        // 1. Owner (admin) adds 1 miner
        await minerContract.connect(owner).addMiner(miner.address);
        expect(await minerContract.isMiner(miner.address)).to.be.true;

        // 2. Owner (admin) adds 2 workflows of different cost
        await workflow.connect(owner).setGPURent(0, ethers.parseUnits("0.15", 18));
        await workflow.connect(owner).setGPURent(1, ethers.parseUnits("0.20", 18));
        expect(await workflow.rentOf(0)).to.equal(ethers.parseUnits("0.15", 18));
        expect(await workflow.rentOf(1)).to.equal(ethers.parseUnits("0.20", 18));

        // 3. 1 creator mints 2 NFTs and sets the rent
        await guvaNFT.connect(creator).mint(creator.address, "nft1_uri");
        await guvaNFT.connect(creator).mint(creator.address, "nft2_uri");
        await guvaNFT.connect(creator).updateRent(0, ethers.parseUnits("0.01", 18));
        await guvaNFT.connect(creator).updateRent(1, ethers.parseUnits("0.02", 18));
        expect(await guvaNFT.rentOf(0)).to.equal(ethers.parseUnits("0.01", 18));
        expect(await guvaNFT.rentOf(1)).to.equal(ethers.parseUnits("0.02", 18));

        // 4. 1 user deposits USDC and PyUSD to topUp
        await mockUSDC.mint(user.address, ethers.parseUnits("100", 18));
        await mockPyUSD.mint(user.address, ethers.parseUnits("100", 18));
        await mockUSDC.connect(user).approve(bankAddress, ethers.parseUnits("100", 18));
        await mockPyUSD.connect(user).approve(bankAddress, ethers.parseUnits("100", 18));
        await bank.connect(user).topUpWithUSDC(ethers.parseUnits("50", 18));
        await bank.connect(user).topUpWithPyUSD(ethers.parseUnits("50", 18));
        expect(await bank.balanceOf(user.address)).to.equal(ethers.parseUnits("100", 18));

        // 5. Someone calls convert to convert all PyUSD in bank to USDC
        await bank.connect(user).convert();
        expect(await mockPyUSD.balanceOf(bankAddress)).to.equal(0);
        expect(await mockUSDC.balanceOf(bankAddress)).to.equal(ethers.parseUnits("100", 18));

        // 6. Miner calls "spend" and make sure all the amounts are correct
        await bank.connect(miner).spend(user.address, 0, 0); // Use NFT 0 and Workflow 0

        // 7. Verify balances after spend
        const expectedUserBalance = ethers.parseUnits("100", 18) - ethers.parseUnits("0.15", 18) - ethers.parseUnits("0.01", 18);
        const expectedMinerBalance = ethers.parseUnits("0.15", 18);
        const expectedCreatorBalance = ethers.parseUnits("0.01", 18);

        expect(await bank.balanceOf(user.address)).to.equal(expectedUserBalance);
        expect(await bank.balanceOf(miner.address)).to.equal(expectedMinerBalance);
        expect(await bank.balanceOf(creator.address)).to.equal(expectedCreatorBalance);

        // 8. Both miner and creator withdraw their earned USDC
        await bank.connect(miner).withdrawWithUSDC(expectedMinerBalance);
        await bank.connect(creator).withdrawWithUSDC(expectedCreatorBalance);

        expect(await mockUSDC.balanceOf(miner.address)).to.equal(expectedMinerBalance);
        expect(await mockUSDC.balanceOf(creator.address)).to.equal(expectedCreatorBalance);
    });
});
