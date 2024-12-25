const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Voting Contract", function () {
  let Voting, SeminarNFT, Whitelist, voting, seminarNFT, whitelist;
  let admin, voter1, voter2, speaker1, speaker2, speaker3, speaker4;

  beforeEach(async function () {
    [admin, voter1, voter2, speaker1, speaker2, speaker3, speaker4] = await ethers.getSigners();

    const SeminarNFTFactory = await ethers.getContractFactory("SeminarNFT");
    seminarNFT = await SeminarNFTFactory.deploy();
    await seminarNFT.waitForDeployment();
    await seminarNFT.initialize(admin.address);

    const WhitelistFactory = await ethers.getContractFactory("WhitelistUpgradeableV2");
    whitelist = await WhitelistFactory.deploy();
    await whitelist.waitForDeployment();
    const ADMIN_ROLE = ethers.keccak256(ethers.toUtf8Bytes("ADMIN_ROLE"));
    await whitelist.connect(admin).initialize(admin.address);

    const VotingContract = await ethers.getContractFactory("Voting");
    voting = await VotingContract.deploy();
    await voting.waitForDeployment();
    await voting.initialize(admin.address, seminarNFT.target, whitelist.target);

    await whitelist.connect(admin).grantRole(ADMIN_ROLE, admin.address);

    const VOTER_ROLE = await voting.VOTER_ROLE();
    await whitelist.connect(admin).grantRole(VOTER_ROLE, voter1.address);
    await whitelist.connect(admin).grantRole(VOTER_ROLE, voter2.address);

    await seminarNFT.connect(admin).mintSeminar(
      "Seminar 1",
      "Mô tả 1",
      "Hình ảnh 1",
      "Speaker 1",
      "metadataURL 1",
      [speaker1.address, speaker2.address]
    );
    await seminarNFT.connect(admin).mintSeminar(
      "Seminar 2",
      "Mô tả 2",
      "Hình ảnh 2",
      "Speaker 2",
      "metadataURL 2",
      [speaker2.address, speaker3.address]
    );
    await seminarNFT.connect(admin).mintSeminar(
      "Seminar 3",
      "Mô tả 3",
      "Hình ảnh 3",
      "Speaker 3",
      "metadataURL 3",
      [speaker3.address, speaker4.address]
    );
    await seminarNFT.connect(admin).mintSeminar(
      "Seminar 4",
      "Mô tả 4",
      "Hình ảnh 4",
      "Speaker 4",
      "metadataURL 4",
      [speaker4.address, speaker1.address]
    );

    const maxVotes = 2;
    const startTime = Math.floor(Date.now() / 1000);
    const endTime = startTime + 3600;

    await voting.connect(admin).createVotingRound(startTime, endTime, maxVotes);
    await voting.connect(admin).addSeminarToRound(1, 1);
    await voting.connect(admin).addSeminarToRound(1, 2);
    await voting.connect(admin).addSeminarToRound(1, 3);
    await voting.connect(admin).addSeminarToRound(1, 4);
  });

  it("Có thể tạo một voting round mới", async function () {
    const maxVotes = 2;
    const startTime = Math.floor(Date.now() / 1000);
    const endTime = startTime + 3600;

    await expect(voting.connect(admin).createVotingRound(startTime, endTime, maxVotes))
      .to.emit(voting, "VotingRoundCreated")
      .withArgs(2, startTime, endTime, maxVotes);

    const round = await voting.votingRounds(2);
    expect(round.isActive).to.equal(true);
    expect(round.maxVotesPerVoter).to.equal(maxVotes);
  });

  it("Có thể thêm seminar vào voting round", async function () {
    const startTime = Math.floor(Date.now() / 1000) + 10;
    const endTime = startTime + 3600;

    await voting.connect(admin).createVotingRound(startTime, endTime, 2);
    await expect(voting.connect(admin).addSeminarToRound(2, 1))
      .to.emit(voting, "SeminarAddedToRound")
      .withArgs(2, 1);

    const seminar = await seminarNFT.getSeminar(1);
    expect(seminar[0]).to.equal("Seminar 1");
  });

  it("Có thể cho phép voter bỏ phiếu cho seminar", async function () {
    await expect(voting.connect(voter1).vote(1, 1))
      .to.emit(voting, "Voted")
      .withArgs(1, 1, voter1.address);

    const votes = await voting.totalVotes(1, 1);
    expect(votes).to.equal(1);
    const hasVoted = await voting.checkVoted(1, voter1.address);
    expect(hasVoted).to.be.true;
  });

  it("Tránh double-vote cho cùng một seminar", async function () {
    await voting.connect(voter1).vote(1, 1);
    await expect(voting.connect(voter1).vote(1, 1))
      .to.be.revertedWith("You have already voted for this seminar");
  });

  it("Kết thúc một voting round", async function () {
    const startTime = Math.floor(Date.now() / 1000);
    const endTime = startTime + 10;
  
    await voting.connect(admin).createVotingRound(startTime, endTime, 2);
  
    await ethers.provider.send("evm_increaseTime", [15]);
    await ethers.provider.send("evm_mine");
  
    await expect(voting.connect(admin).endVotingRound(2))
      .to.emit(voting, "VotingRoundEnded")
      .withArgs(2);
  
    const round = await voting.votingRounds(2);
    expect(round.isActive).to.be.false;
  });
  

  it("Kiểm tra giới hạn số lần vote", async function () {
    await voting.connect(voter1).vote(1, 1);
    await voting.connect(voter1).vote(1, 2);

    await expect(voting.connect(voter1).vote(1, 3))
      .to.be.revertedWith("Max votes exceeded");
  });
  it("Có thể thay đổi thời gian kết thúc của một voting round", async function () {
    const newEndTime = Math.floor(Date.now() / 1000) + 7200; 
    const oldEndTime = Math.floor(Date.now() / 1000) + 3600;
    await expect(voting.connect(admin).changeVotingEndtime(1, newEndTime))
      .to.emit(voting, "VotingEndTimeChanged")
      .withArgs(1, oldEndTime, newEndTime);

    const round = await voting.votingRounds(1);
    expect(round.endTime).to.equal(newEndTime);
  });

});
