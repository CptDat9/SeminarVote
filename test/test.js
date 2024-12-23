const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("Contracts Deployment and Functionality Test", function () {
    let admin, voter1, voter2, speaker;
    let whitelist, seminarNFT, voting;

    before(async function () {
        [admin, voter1, voter2, speaker] = await ethers.getSigners();
    });

    it("Deploy Contracts", async function () {
        // Deploy WhitelistUpgradeableV2
        const Whitelist = await ethers.getContractFactory("WhitelistUpgradeableV2");
        whitelist = await upgrades.deployProxy(Whitelist, [admin.address], { initializer: "initialize" });
        await whitelist.waitForDeployment();
        expect(whitelist.target).to.properAddress;

        // Deploy SeminarNFT
        const SeminarNFT = await ethers.getContractFactory("SeminarNFT");
        seminarNFT = await upgrades.deployProxy(SeminarNFT, [admin.address], { initializer: "initialize" });
        await seminarNFT.waitForDeployment();
        expect(seminarNFT.target).to.properAddress;

        // Deploy Voting
        const Voting = await ethers.getContractFactory("Voting");
        voting = await upgrades.deployProxy(Voting, [admin.address, seminarNFT.target], { initializer: "initialize" });
        await voting.waitForDeployment();
        expect(voting.target).to.properAddress;
    });

    it("WhitelistUpgradeableV2: Should allow admin to add and remove voters", async function () {
        await whitelist.addVoter(voter1.address);
        expect(await whitelist.isVoter(voter1.address)).to.be.true;

        await whitelist.removeVoter(voter1.address);
        expect(await whitelist.isVoter(voter1.address)).to.be.false;
    });

    it("SeminarNFT: Should mint a seminar and retrieve its details", async function () {
        const tx = await seminarNFT.mintSeminar(
            "Seminar 1",
            "A description",
            "ImageURL",
            "Speaker 1",
            "MetadataURL",
            speaker.address
        );
        await tx.wait();

        const seminarDetails = await seminarNFT.getSeminar(0);
        expect(seminarDetails[0]).to.equal("Seminar 1");
        expect(seminarDetails[5]).to.equal(speaker.address);
    });

    it("Voting: Should create a voting round and allow voting", async function () {
        const startTime = Math.floor(Date.now() / 1000);
        const endTime = startTime + 3600; // 1 hour from now

        await voting.createVotingRound(startTime, endTime, 3);
        const roundDetails = await voting.votingRounds(1);
        expect(roundDetails.startTime).to.equal(startTime);
        expect(roundDetails.endTime).to.equal(endTime);

        await voting.addSeminarToRound(1, 0);
        const seminars = await voting.getSeminarsInRound(1);
        expect(seminars[0]).to.equal(0);

        await voting.connect(voter1).vote(1, 0);
        const totalVotes = await voting.totalVotes(1, 0);
        expect(totalVotes).to.equal(1);
    });

    it("Voting: Should calculate speaker votes correctly", async function () {
        const speakerVotesBefore = await voting.getSpeakerVotes(1, speaker.address);
        expect(speakerVotesBefore).to.equal(0);

        await voting.connect(voter2).vote(1, 0);
        const speakerVotesAfter = await voting.getSpeakerVotes(1, speaker.address);
        expect(speakerVotesAfter).to.equal(1);
    });

    it("Voting: Should end a voting round", async function () {
        await voting.checkAndEndRound(1);
        const roundDetails = await voting.votingRounds(1);
        expect(roundDetails.isActive).to.be.false;
    });
});
