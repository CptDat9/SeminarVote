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

    it("Non-admin ko the add voters", async function () {
        await whitelist.connect(owner).addAdmin(admin.address);
        await whitelist.connect(admin).addVoter(voter.address);

        await expect(whitelist.connect(nonAdmin).addVoter(voter.address))
            .to.be.revertedWith(
                `AccessControl: account ${nonAdmin.address.toLowerCase()} is missing role ${await whitelist.ADMIN_ROLE()}`
            );
    });

    it("Owner co the remove admin", async function () {
        const ADMIN_ROLE = await whitelist.ADMIN_ROLE();

        await whitelist.connect(owner).addAdmin(admin.address);
        expect(await whitelist.hasRole(ADMIN_ROLE, admin.address)).to.equal(true);

        await whitelist.connect(owner).removeAdmin(admin.address);
        expect(await whitelist.hasRole(ADMIN_ROLE, admin.address)).to.equal(false);
    });

    it("Admin co the remove voters", async function () {
        const VOTER_ROLE = await whitelist.VOTER_ROLE();

        await whitelist.connect(owner).addAdmin(admin.address);
        await whitelist.connect(admin).addVoter(voter.address);
        expect(await whitelist.hasRole(VOTER_ROLE, voter.address)).to.equal(true);

        await whitelist.connect(admin).removeVoter(voter.address);
        expect(await whitelist.hasRole(VOTER_ROLE, voter.address)).to.equal(false);
    });

    it("Phat ra su kien (emit) RoleAdded and RoleRemoved ", async function () {
        const ADMIN_ROLE = await whitelist.ADMIN_ROLE();

        await expect(whitelist.connect(owner).addAdmin(admin.address))
            .to.emit(whitelist, "RoleAdded")
            .withArgs(admin.address, ADMIN_ROLE);

        await expect(whitelist.connect(owner).removeAdmin(admin.address))
            .to.emit(whitelist, "RoleRemoved")
            .withArgs(admin.address, ADMIN_ROLE);
    });
});
