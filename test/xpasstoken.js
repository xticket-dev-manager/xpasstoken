describe("XPASSToken contract", function () {
    let chai;
    let expect;
    let Token;
    let xpass;
    let owner;
    let addr1;
    let addr2;
    let addrs;

    before(async function () {
        chai = await import("chai");
        const { solidity } = require("ethereum-waffle")
        chai.use(solidity)        
        expect = chai.expect;
    });

    beforeEach(async function () {
        Token = await ethers.getContractFactory("XPASSToken");
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
        xpass = await Token.deploy();
        await xpass.deployed();
        await xpass.enableTransfer();
    });

    describe("Deployment", function () {
        it("Should set the right owner", async function () {
            expect(await xpass.owner()).to.equal(owner.address);
        });

        it("Should assign the total supply of tokens to the owner", async function () {
            const ownerBalance = await xpass.balanceOf(owner.address);
            expect(ownerBalance.eq(await xpass.totalSupply())).to.be.true;       
        });

        it("Should have the correct symbol", async function () {
            expect(await xpass.symbol()).to.equal("XPASS");
        });

        it("Should have the correct name", async function () {
            expect(await xpass.name()).to.equal("X-PASS");
        });

        it("Should have the correct decimals", async function () {
            expect(await xpass.decimals()).to.equal(18);
        });

        it("Should have the correct total supply", async function () {
            const totalSupply = await xpass.totalSupply();
            const expectedSupply = ethers.BigNumber.from("1000000000").mul(ethers.BigNumber.from("10").pow(18)); // 10억 개
            expect(totalSupply.eq(expectedSupply)).to.be.true;
        });
    });

    describe("Transactions", function () {
        it("Should transfer tokens between accounts", async function () {
            const transferAmount = ethers.BigNumber.from("50").mul(ethers.BigNumber.from("10").pow(18));

            // Transfer 50 tokens from owner to addr1
            await xpass.transfer(addr1.address, transferAmount);
            const addr1Balance = await xpass.balanceOf(addr1.address);

            expect(addr1Balance.eq(transferAmount)).to.be.true;

            // Transfer 50 tokens from addr1 to addr2
            await xpass.connect(addr1).transfer(addr2.address, transferAmount);
            const addr2Balance = await xpass.balanceOf(addr2.address);
            expect(addr2Balance.eq(transferAmount)).to.be.true;
        });

        it("Should fail if sender doesn’t have enough tokens", async function () {
            const transferAmount = ethers.BigNumber.from("1").mul(ethers.BigNumber.from("10").pow(18));
            const initialOwnerBalance = await xpass.balanceOf(owner.address);

            // Try to send 1 token from addr1 (0 tokens) to owner.
            await expect(
                xpass.connect(addr1).transfer(owner.address, transferAmount)
            ).to.be.reverted;

            // Owner balance shouldn't have changed.
            expect(await xpass.balanceOf(owner.address)).to.equal(initialOwnerBalance);
        });

        it("Should update balances after transfers", async function () {
            const initialOwnerBalance = await xpass.balanceOf(owner.address);
            const transferAmount1 = ethers.BigNumber.from("100").mul(ethers.BigNumber.from("10").pow(18));
            const transferAmount2 = ethers.BigNumber.from("50").mul(ethers.BigNumber.from("10").pow(18));

            // Transfer 100 tokens from owner to addr1
            await xpass.transfer(addr1.address, transferAmount1);

            // Transfer another 50 tokens from owner to addr2
            await xpass.transfer(addr2.address, transferAmount2);

            const finalOwnerBalance = await xpass.balanceOf(owner.address);
            expect(finalOwnerBalance.eq(initialOwnerBalance.sub(transferAmount1.add(transferAmount2)))).to.be.true;

            const addr1Balance = await xpass.balanceOf(addr1.address);
            expect(addr1Balance.eq(transferAmount1)).to.be.true;

            const addr2Balance = await xpass.balanceOf(addr2.address);
            expect(addr2Balance.eq(transferAmount2)).to.be.true;
        });

        it("Should approve tokens for delegated transfer", async function () {
            const approveAmount = ethers.BigNumber.from("100").mul(ethers.BigNumber.from("10").pow(18));
            await xpass.approve(addr1.address, approveAmount);
            const allowanceAddr1 = await xpass.allowance(owner.address, addr1.address);
            expect(allowanceAddr1.eq(approveAmount)).to.be.true;
        });

        it("Should handle delegated token transfers", async function () {
            const transferAmount = ethers.BigNumber.from("100").mul(ethers.BigNumber.from("10").pow(18));
            await xpass.approve(addr1.address, transferAmount);
            await xpass.connect(addr1).transferFrom(owner.address, addr2.address, transferAmount);

            const addr2Balance = await xpass.balanceOf(addr2.address);
            expect(addr2Balance.eq(transferAmount)).to.be.true;
            expect((await xpass.allowance(owner.address, addr1.address)).eq(0)).to.be.true;
        });

        it("Should burn tokens", async function () {
            const burnAmount = ethers.BigNumber.from("100").mul(ethers.BigNumber.from("10").pow(18));
            const totalSupply1 = await xpass.totalSupply();
            await xpass.burn(burnAmount);
            const totalSupply2 = await xpass.totalSupply();
            
            expect(totalSupply1.sub(burnAmount).eq(totalSupply2)).to.be.true;
        });

        it("Should transfer ownership", async function () {
            await xpass.transferOwnership(addr1.address);
            expect(await xpass.owner()).to.equal(addr1.address);
        });

        it("Should not allow transfers when transfers are disabled", async function () {
            await xpass.disableTransfer();
            await expect(xpass.transfer(addr1.address, 100)).to.not.be.reverted;
            expect((await xpass.balanceOf(addr1.address)).eq(100)).to.be.true;

            await expect(xpass.connect(addr1).transfer(addr2.address, 100)).to.be.revertedWith("No transfers");
            expect((await xpass.balanceOf(addr1.address)).eq(100)).to.be.true;

            await xpass.enableTransfer();
            await expect(xpass.connect(addr1).transfer(addr2.address, 100)).to.not.be.reverted;
            expect((await xpass.balanceOf(addr1.address)).eq(0)).to.be.true;
            expect((await xpass.balanceOf(addr2.address)).eq(100)).to.be.true;
        });

        it("Should lock and unlock accounts", async function () {
            const lockAmount = ethers.BigNumber.from("100").mul(ethers.BigNumber.from("10").pow(18));
            await xpass.transfer(addr1.address, lockAmount);
            await xpass.lockAccount(addr1.address, lockAmount);
            await expect(xpass.connect(addr1).transfer(addr2.address, lockAmount)).to.be.revertedWith("Exceeds locked");
            await xpass.unlockAccount(addr1.address);
            await xpass.connect(addr1).transfer(addr2.address, lockAmount);
            expect((await xpass.balanceOf(addr2.address)).eq(lockAmount)).to.be.true;
        });

        it("Should change admin address", async function () {
            await xpass.changeAdminAddr(addr1.address);
            expect(await xpass.adminAddr()).to.equal(addr1.address);
        });

        it("Should not allow transfers to invalid destinations", async function () {
            await expect(xpass.transfer(ethers.constants.AddressZero, 100)).to.be.revertedWith("Invalid dest");
            await expect(xpass.transfer(xpass.address, 100)).to.be.revertedWith("Invalid dest");
            await expect(xpass.transfer(owner.address, 100)).to.be.revertedWith("Invalid dest");
        });

        it("Should handle transfer from locked accounts correctly", async function () {
            const lockAmount = ethers.BigNumber.from("100").mul(ethers.BigNumber.from("10").pow(18));
            await xpass.transfer(addr1.address, lockAmount);
            await xpass.lockAccount(addr1.address, lockAmount.div(2));

            await expect(xpass.connect(addr1).transfer(addr2.address, lockAmount)).to.be.revertedWith("Exceeds locked");
            await xpass.connect(addr1).transfer(addr2.address, lockAmount.div(2));

            expect((await xpass.balanceOf(addr2.address)).eq(lockAmount.div(2))).to.be.true;
        });

        it("Should handle transferFrom with locked accounts correctly", async function () {
            const lockAmount = ethers.BigNumber.from("100").mul(ethers.BigNumber.from("10").pow(18));
            await xpass.transfer(addr1.address, lockAmount);
            await xpass.lockAccount(addr1.address, lockAmount.div(2));
            await xpass.connect(addr1).approve(addr2.address, lockAmount.div(2));
        
            await expect(xpass.connect(addr2).transferFrom(addr1.address, addr2.address, lockAmount)).to.be.revertedWith("Exceeds locked");
            await xpass.connect(addr2).transferFrom(addr1.address, addr2.address, lockAmount.div(2));
        
            expect((await xpass.balanceOf(addr2.address)).eq(lockAmount.div(2))).to.be.true;
        });
    });
});
