const { expect } = require("chai");
const { ethers , upgrades } = require("hardhat");

describe("Voter and winner in Voting", function () {
    let Voting, voting, SeminarNFT, seminarNFT, Whitelist, whitelist;
    let owner, admin, voter, speaker1, speaker2, speaker3, nonAdmin, voter1, voter2, voter3;

    beforeEach(async function () {
        [owner, admin, voter, speaker1, speaker2, speaker3, nonAdmin, voter1, voter2, voter3] = await ethers.getSigners();

        Whitelist = await ethers.getContractFactory("WhitelistUpgradeableV2");
        whitelist = await Whitelist.deploy();
        await whitelist.waitForDeployment();
        await whitelist.initialize(admin.address); // Cấp ADMIN_ROLE cho admin
        SeminarNFT = await ethers.getContractFactory("SeminarNFT");
        seminarNFT = await SeminarNFT.deploy();
        await seminarNFT.waitForDeployment();
        await seminarNFT.initialize(admin.address); // Cấp ADMIN_ROLE cho admin
        Voting = await ethers.getContractFactory("Voting");
        voting = await Voting.deploy();
        await voting.waitForDeployment();
        await voting.initialize(admin.address, seminarNFT.target, whitelist.target);
        
        await seminarNFT.connect(admin).mintSeminar(
            "Seminar 1",
            "Descrip 1",
            "image 1",
            "Speaker 1 ",
            "metadataURL 1",
            [speaker1.address, speaker2.address]
        );
        await seminarNFT.connect(admin).mintSeminar(
            "Seminar 2",
            "Descrip 2",
            "image 2",
            "Speaker 2 ",
            "metadataURL 2",
            [speaker2.address, speaker3.address]
        );
        await seminarNFT.connect(admin).mintSeminar(
            "Seminar 3",
            "Descrip 3",
            "image 3",
            "Speaker 3 ",
            "metadataURL 3",
            [speaker3.address, speaker1.address]
        );

        await seminarNFT.connect(admin).mintSeminar(
            "Seminar 4",
            "Descrip 4",
            "image 4",
            "Speaker 4 ",
            "metadataURL 4",
            [speaker1.address, speaker2.address]
        );
        
        const startTime = Math.floor(Date.now() / 1000);
        const endTime = startTime * 2;
        await voting.connect(admin).createVotingRound(startTime, endTime, 3, 3);
        
        await voting.connect(admin).addSeminarToRound(1, 1);
        await voting.connect(admin).addSeminarToRound(1, 2);
        await voting.connect(admin).addSeminarToRound(1, 4);
        await voting.connect(admin).addSeminarToRound(1, 3);
        await whitelist.connect(admin).addVoter(voter);
    });

    it(" Initialize thành công", async function () {
        expect(await voting.hasRole(await voting.ADMIN_ROLE(), admin.address)).to.equal(true);
        expect(await voting.seminarNFT()).to.equal(seminarNFT.target);
    });
    
    it("Test other voting", async function () {
        await expect(
            voting.connect(nonAdmin).vote(1, 1)
        ).to.be.reverted;
    });

    it("Test normal voting", async function () {
        await expect(
            voting.connect(voter).vote(1, 1)
        ).to.emit(voting, "Voted").withArgs(1, 1, voter.address);
        await expect(
            voting.connect(voter).vote(1, 2)
        ).to.emit(voting, "Voted").withArgs(1, 2, voter.address);
        await expect(
            voting.connect(voter).vote(1, 3)
        ).to.emit(voting, "Voted").withArgs(1, 3, voter.address);
    });

    it("Test double voting", async function () {
        await expect(
            voting.connect(voter).vote(1, 1)
        ).to.emit(voting, "Voted").withArgs(1, 1, voter.address);
        await expect(
            voting.connect(voter).vote(1, 1)
        ).to.be.revertedWith("You have already voted for this seminar");
    });

    it("Test number of votes exceeded the limit",async function () {
        await expect(
            voting.connect(voter).vote(1, 1)
        ).to.emit(voting, "Voted").withArgs(1, 1, voter.address);
        await expect(
            voting.connect(voter).vote(1, 2)
        ).to.emit(voting, "Voted").withArgs(1, 2, voter.address);
        await expect(
            voting.connect(voter).vote(1, 4)
        ).to.emit(voting, "Voted").withArgs(1, 4, voter.address);      
        await expect(
            voting.connect(voter).vote(1, 3)
        ).to.be.revertedWith("Max votes exceeded");     
    });

    it("Test get max speaker & seminar", async function () {
        await whitelist.connect(admin).addVoter(voter1);
        await whitelist.connect(admin).addVoter(voter2);
        await whitelist.connect(admin).addVoter(voter3);

        await voting.connect(voter1).vote(1, 1);
        await voting.connect(voter1).vote(1, 3);
        await voting.connect(voter1).vote(1, 4);
        await voting.connect(voter2).vote(1, 1);
        await voting.connect(voter2).vote(1, 2);
        await voting.connect(voter2).vote(1, 3);
        await voting.connect(voter3).vote(1, 1);
        await voting.connect(voter3).vote(1, 2);
        await voting.connect(voter3).vote(1, 3);

        await expect(voting.connect(nonAdmin).getWinnerSpeaker(1)).to.be.reverted;
        await expect(voting.connect(nonAdmin).getWinnerSeminar(1)).to.be.reverted;

        const speakerWin = await voting.connect(admin).getWinnerSpeaker(1);
        expect(speakerWin[0]).to.equal(speaker1);
        expect(speakerWin[1]).to.equal(7);

        const seminarWin = await voting.connect(admin).getWinnerSeminar(1);
        expect(seminarWin[0]).to.equal(1);
        expect(seminarWin[1]).to.equal(3);
    });

});