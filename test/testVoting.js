const { expect } = require("chai");
const { ethers , upgrades } = require("hardhat");

describe("Voting", function () {
    let Voting, voting, SeminarNFT, seminarNFT;
    let owner, admin, voter, speaker1, speaker2, speaker3, nonAdmin;

    beforeEach(async function () {
        [owner, admin, voter, speaker1, speaker2, speaker3, nonAdmin] = await ethers.getSigners();

        SeminarNFT = await ethers.getContractFactory("SeminarNFT");
        seminarNFT = await SeminarNFT.deploy();
        await seminarNFT.waitForDeployment();
        await seminarNFT.initialize(admin.address); // Cấp ADMIN_ROLE cho admin
        Voting = await ethers.getContractFactory("Voting");
        voting = await Voting.deploy();
        await voting.waitForDeployment();
        await voting.initialize(admin.address, seminarNFT.target);
        await seminarNFT.connect(admin).mintSeminar(
            "Seminar 1",
            "Descrip 1",
            "image 1",
            "Speaker 1 ",
            "metadataURL 1",
            speaker1.address
        );
        await seminarNFT.connect(admin).mintSeminar(
            "Seminar 2",
            "Descrip 2",
            "image 2",
            "Speaker 2 ",
            "metadataURL 2",
            speaker2.address
        );
        await seminarNFT.connect(admin).mintSeminar(
            "Seminar 3",
            "Descrip 3",
            "image 3",
            "Speaker 3 ",
            "metadataURL 3",
            speaker3.address
        );
    });

    it(" Initialize thành công", async function () {
        expect(await voting.hasRole(await voting.ADMIN_ROLE(), admin.address)).to.equal(true);
        expect(await voting.seminarNFT()).to.equal(seminarNFT.target);
    });

    it("Admin co the tao voting round", async function () {
        const startTime = Math.floor(Date.now() / 1000);
        const endTime = startTime + 3600;

        await voting.connect(admin).createVotingRound(startTime, endTime, 3);

        const round = await voting.votingRounds(1);
        expect(round.startTime).to.equal(startTime);
        expect(round.endTime).to.equal(endTime);
        expect(round.maxVotesPerVoter).to.equal(3);
        expect(round.isActive).to.equal(true);
    });

    it("Non-admin khong the tao voting round", async function () {
        const ADMIN_ROLE = await voting.ADMIN_ROLE();
        const startTime = Math.floor(Date.now() / 1000);
        const endTime = startTime + 3600;

        await expect(
            voting.connect(nonAdmin).createVotingRound(startTime, endTime, 3)
        ).to.be
        .revertedWithCustomError(voting, "AccessControlUnauthorizedAccount")
        .withArgs(nonAdmin.address, ADMIN_ROLE);
    });

    it("Admin co the add seminar vao 1 round", async function () {
        const startTime = Math.floor(Date.now() / 1000);
        const endTime = startTime + 3600;
        const  ADMIN_ROLE = await voting.ADMIN_ROLE();
        await voting.connect(admin).createVotingRound(startTime, endTime, 3);
        await voting.connect(admin).addSeminarToRound(1, 1);

        const seminars = await voting.getSeminarsInRound(1);
        expect(seminars).to.include(1);
    });

    it("Non-admin khong the add seminar vao 1 round", async function () {
        const startTime = Math.floor(Date.now() / 1000);
        const endTime = startTime + 3600;

        await voting.connect(admin).createVotingRound(startTime, endTime, 3);

        await expect(
            voting.connect(nonAdmin).addSeminarToRound(1, 1)
        ).to.be.revertedWith(
            `AccessControl: account ${nonAdmin.address.toLowerCase()} is missing role ${await voting.ADMIN_ROLE()}`
        );
    });

    it("Voter có thể vote in an active round", async function () {
        const startTime = Math.floor(Date.now() / 1000);
        const endTime = startTime + 3600;

        await voting.connect(admin).createVotingRound(startTime, endTime, 3);
        await voting.connect(admin).addSeminarToRound(1, 1);

        await voting.connect(voter).vote(1, 1);

        const userVotes = await voting.userVotes(1, voter.address);
        const totalVotes = await voting.totalVotes(1, 1);

        expect(userVotes).to.equal(1);
        expect(totalVotes).to.equal(1);
    });

    it("Voter không thể vote nhiều hơn maxVotes/Voter", async function () {
        const startTime = Math.floor(Date.now() / 1000);
        const endTime = startTime + 3600;

        await voting.connect(admin).createVotingRound(startTime, endTime, 1);
        await voting.connect(admin).addSeminarToRound(1, 1);

        await voting.connect(voter).vote(1, 1);

        await expect(voting.connect(voter).vote(1, 1)).to.be.revertedWith(
            "You have reached the maximum number of votes"
        );
    });

    it("Non-active round không  accept votes", async function () {
        const startTime = Math.floor(Date.now() / 1000);
        const endTime = startTime - 3600; 

        await voting.connect(admin).createVotingRound(startTime, endTime, 3);
        await voting.connect(admin).addSeminarToRound(1, 1);

        await expect(voting.connect(voter).vote(1, 1)).to.be.revertedWith("Voting round has ended");
    });

    it("Admin có thể kết thúc voting round", async function () {
        const startTime = Math.floor(Date.now() / 1000);
        const endTime = startTime + 3600;

        await voting.connect(admin).createVotingRound(startTime, endTime, 3);
        await voting.connect(admin).endVotingRound(1);

        const round = await voting.votingRounds(1);
        expect(round.isActive).to.equal(false);
    });

    it("Non-admin không thể end  voting round", async function () {
        const startTime = Math.floor(Date.now() / 1000);
        const endTime = startTime + 3600;

        await voting.connect(admin).createVotingRound(startTime, endTime, 3);

        await expect(
            voting.connect(nonAdmin).endVotingRound(1)
        ).to.be.revertedWith(
            `AccessControl: account ${nonAdmin.address.toLowerCase()} is missing role ${await voting.ADMIN_ROLE()}`
        );
    });
});
