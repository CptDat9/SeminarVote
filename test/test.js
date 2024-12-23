const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("WhitelistUpgradeableV2", function () {
    let whitelist, owner, admin, voter, other, nonAdmin;

    beforeEach(async function () {
        [owner, admin, voter, other, nonAdmin] = await ethers.getSigners();

        const WhitelistFactory = await ethers.getContractFactory("WhitelistUpgradeableV2");
        whitelist = await upgrades.deployProxy(WhitelistFactory, [owner.address], { initializer: "initialize" });
    });

    it("Owner có admin role ?", async function () {
        const ADMIN_ROLE = await whitelist.ADMIN_ROLE();
        expect(await whitelist.hasRole(ADMIN_ROLE, owner.address)).to.equal(true);
    });

    it("Admin co the add voter, voter có role hợp lệ.", async function () {
        const ADMIN_ROLE = await whitelist.ADMIN_ROLE();
        const VOTER_ROLE = await whitelist.VOTER_ROLE();
        await whitelist.connect(owner).addAdmin(admin.address);
        expect(await whitelist.hasRole(ADMIN_ROLE, admin.address)).to.equal(true);
        await whitelist.connect(admin).addVoter(voter.address);
        expect(await whitelist.hasRole(VOTER_ROLE, voter.address)).to.equal(true);
        expect(await whitelist.isVoter(voter.address)).to.equal(true);
    });
});