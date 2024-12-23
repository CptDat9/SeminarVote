// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./SeminarNFT.sol";

contract Voting is Initializable, AccessControlUpgradeable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct VotingRound {
        uint256 startTime;
        uint256 endTime;
        uint256 maxVotesPerVoter;
        bool isActive;
        uint256[] seminarIds;
        mapping(address => uint256) speakerVotes;
    }

    SeminarNFT public seminarNFT;
    mapping(uint256 => VotingRound) public votingRounds;
    mapping(uint256 => mapping(address => uint256)) public userVotes;
    mapping(uint256 => mapping(uint256 => uint256)) public totalVotes;

    uint256 public nextRoundId;

    event VotingRoundCreated(uint256 indexed roundId, uint256 startTime, uint256 endTime, uint256 maxVotesPerVoter);
    event SeminarAddedToRound(uint256 indexed roundId, uint256 indexed seminarId);
    event Voted(uint256 indexed roundId, uint256 indexed seminarId, address indexed voter);
    event VotingRoundEnded(uint256 indexed roundId);

    function initialize(address admin, address seminarNFTAddress) public initializer {
        __AccessControl_init();
        _grantRole(ADMIN_ROLE, admin);

        seminarNFT = SeminarNFT(seminarNFTAddress);
    }

    modifier onlyActiveRound(uint256 roundId) {
        require(votingRounds[roundId].isActive, "Voting round is not active");
        require(block.timestamp >= votingRounds[roundId].startTime, "Voting round has not started yet");
        require(block.timestamp <= votingRounds[roundId].endTime, "Voting round has ended");
        _;
    }

    modifier seminarInRound(uint256 roundId, uint256 seminarId) {
        require(isSeminarInRound(roundId, seminarId), "Seminar is not in this round");
        _;
    }

    function createVotingRound(
        uint256 startTime,
        uint256 endTime,
        uint256 maxVotesPerVoter
    ) public onlyRole(ADMIN_ROLE) {
        require(endTime > startTime, "End time must be after start time");
        require(maxVotesPerVoter > 0, "Max votes per voter must be greater than 0");

        nextRoundId++;
        VotingRound storage newRound = votingRounds[nextRoundId];
        newRound.startTime = startTime;
        newRound.endTime = endTime;
        newRound.maxVotesPerVoter = maxVotesPerVoter;
        newRound.isActive = true;

        emit VotingRoundCreated(nextRoundId, startTime, endTime, maxVotesPerVoter);
    }

    function addSeminarToRound(uint256 roundId, uint256 seminarId) public onlyRole(ADMIN_ROLE) {
        require(votingRounds[roundId].isActive, "Voting round is not active");
        require(seminarNFT.ownerOf(seminarId) != address(0), "Seminar does not exist");
        require(!isSeminarInRound(roundId, seminarId), "Seminar is already in this round");

        VotingRound storage round = votingRounds[roundId];
        round.seminarIds.push(seminarId);
        emit SeminarAddedToRound(roundId, seminarId);
    }

    function vote(uint256 roundId, uint256 seminarId)
        public
        onlyActiveRound(roundId)
        seminarInRound(roundId, seminarId)
    {
        VotingRound storage round = votingRounds[roundId];
        require(userVotes[roundId][msg.sender] < round.maxVotesPerVoter, "You have reached the maximum number of votes");

        userVotes[roundId][msg.sender]++;
        totalVotes[roundId][seminarId]++;

        address speakerAddress = seminarNFT.ownerOf(seminarId);
        round.speakerVotes[speakerAddress]++;

        emit Voted(roundId, seminarId, msg.sender);
    }

    function isSeminarInRound(uint256 roundId, uint256 seminarId) public view returns (bool) {
        VotingRound storage round = votingRounds[roundId];
        for (uint256 i = 0; i < round.seminarIds.length; i++) {
            if (round.seminarIds[i] == seminarId) {
                return true;
            }
        }
        return false;
    }

    function getSeminarsInRound(uint256 roundId) public view returns (uint256[] memory) {
        return votingRounds[roundId].seminarIds;
    }

    function getSpeakerVotes(uint256 roundId, address speaker) public view returns (uint256) {
        return votingRounds[roundId].speakerVotes[speaker];
    }

    function checkAndEndRound(uint256 roundId) public {
        VotingRound storage round = votingRounds[roundId];
        require(round.isActive, "Voting round is already ended");

        if (block.timestamp > round.endTime) {
            round.isActive = false;
            emit VotingRoundEnded(roundId);
        }
    }

    function endVotingRound(uint256 roundId) public onlyRole(ADMIN_ROLE) {
        VotingRound storage round = votingRounds[roundId];
        require(round.isActive, "Voting round is already ended");

        round.isActive = false;
        emit VotingRoundEnded(roundId);
    }
}
