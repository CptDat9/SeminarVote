// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./SeminarNFT.sol";
import "./Whitelist.sol";

contract Voting is Initializable, AccessControlUpgradeable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant VOTER_ROLE = keccak256("VOTER_ROLE");

    struct VotingRound {
        uint256 startTime;
        uint256 endTime;
        uint256 maxVotesPerVoter; // max vote
        bool isActive;
        uint256[] seminarIds;
        address[] speakersInRound;
        mapping(address => uint256) speakerVotes;
        address[] voters;
        mapping(uint256 => bool) seminarExist; //seminarExist[seminarId] = true/false
        mapping(address => bool) speakerExist; //speakerExist[speakerAddress] = true/false
    }
    mapping(uint256 => mapping(address => bool)) public checkVoted; // checkVoted[seminarId][voter] = true/false

    SeminarNFT public seminarNFT;
    WhitelistUpgradeableV2 public whitelist;

    mapping(uint256 => VotingRound) public votingRounds; // roundId => VotingRound
    mapping(uint256 => mapping(address => uint256)) public userVotes; // userVotes[roundId][voter] = number of votes
    mapping(uint256 => mapping(uint256 => uint256)) public totalVotes; // totalVotes[roundId][seminarId] = number of votes

    uint256 public nextRoundId;

    event VotingRoundCreated(
        uint256 indexed roundId,
        uint256 startTime,
        uint256 endTime,
        uint256 maxVotesPerVoter
    );
    event SeminarAddedToRound(
        uint256 indexed roundId,
        uint256 indexed seminarId
    );
    event Voted(
        uint256 indexed roundId,
        uint256 indexed seminarId,
        address indexed voter
    );
    event VotingRoundEnded(uint256 indexed roundId);
    event RoleAdded(address indexed account, bytes32 role);
    event RoleRemoved(address indexed account, bytes32 role);

    function initialize(
        address admin,
        address seminarNFTAddress,
        address whitelistAddress
    ) public initializer {
        require(admin != address(0), "Invalid admin address");
        require(seminarNFTAddress != address(0), "Invalid seminar NFT address");

        __AccessControl_init();
        seminarNFT = SeminarNFT(seminarNFTAddress);
        whitelist = WhitelistUpgradeableV2(whitelistAddress);
    }

    function hasRole(
        bytes32 role,
        address account
    ) public view override returns (bool) {
        if (super.hasRole(role, account)) {
            return true;
        }
        return whitelist.hasRole(role, account);
    }

    modifier onlyActiveRound(uint256 roundId) {
        require(votingRounds[roundId].isActive, "Voting round is not active");
        require(
            block.timestamp >= votingRounds[roundId].startTime,
            "Voting has not started"
        );
        require(
            block.timestamp <= votingRounds[roundId].endTime,
            "Voting has ended"
        );
        _;
    }

    modifier onlySeminarInRound(uint256 roundId, uint256 seminarId) {
        require(
            votingRounds[roundId].seminarExist[seminarId],
            "Seminar not added to round"
        );
        _;
    }

    // Tạo mới vòng bỏ phiếu
    function createVotingRound(
        uint256 startTime,
        uint256 endTime,
        uint256 maxVotesPerVoter
    ) public onlyRole(ADMIN_ROLE) {
        require(endTime > startTime, "End time must be after start time");
        require(
            maxVotesPerVoter > 0,
            "Max votes per voter must be greater than 0"
        );

        nextRoundId++;
        VotingRound storage newRound = votingRounds[nextRoundId];
        newRound.startTime = startTime;
        newRound.endTime = endTime;
        newRound.maxVotesPerVoter = maxVotesPerVoter;
        newRound.isActive = true;

        emit VotingRoundCreated(
            nextRoundId,
            startTime,
            endTime,
            maxVotesPerVoter
        );
    }

    // Thêm seminar vào vòng bỏ phiếu
    function addSeminarToRound(
        uint256 roundId,
        uint256 seminarId
    ) public onlyRole(ADMIN_ROLE) {
        require(votingRounds[roundId].isActive, "Voting round is not active");
        require(
            !votingRounds[roundId].seminarExist[seminarId],
            "Seminar already added to round"
        );

        VotingRound storage round = votingRounds[roundId];
        round.seminarIds.push(seminarId);
        emit SeminarAddedToRound(roundId, seminarId);
        round.seminarExist[seminarId] = true;

        // Thêm speakers vào round
        address[] memory speakers = seminarNFT.getSeminarSpeakers(seminarId);
        uint256 limit = speakers.length;
        for (uint256 i = 0; i < limit; i++) {
            if (!round.speakerExist[speakers[i]]) {
                round.speakersInRound.push(speakers[i]);
                round.speakerExist[speakers[i]] = true;
            }
        }
    }

    // Hàm bỏ phiếu
    function vote(
        uint256 roundId,
        uint256 seminarId
    )
        public
        onlyActiveRound(roundId)
        onlySeminarInRound(roundId, seminarId)
        onlyRole(VOTER_ROLE)
    {
        VotingRound storage round = votingRounds[roundId];
        require(
            userVotes[roundId][msg.sender] < round.maxVotesPerVoter,
            "Max votes exceeded"
        );
        require(
            !checkVoted[seminarId][msg.sender],
            "You have already voted for this seminar"
        );

        userVotes[roundId][msg.sender]++;
        totalVotes[roundId][seminarId]++;
        checkVoted[seminarId][msg.sender] = true;
        round.voters.push(msg.sender);

        address[] memory speakers = seminarNFT.getSeminarSpeakers(seminarId);
        uint256 limit = speakers.length;
        for (uint256 i = 0; i < limit; i++) {
            address x = speakers[i];
            round.speakerVotes[x]++;
        }
        emit Voted(roundId, seminarId, msg.sender);
    }

    // Hàm kết thúc vòng bỏ phiếu
    function endVotingRound(uint256 roundId) public onlyRole(ADMIN_ROLE) {
        VotingRound storage round = votingRounds[roundId];
        require(round.isActive, "Voting round is already inactive");
        require(block.timestamp > round.endTime, "Voting period not yet ended");

        round.isActive = false;
        emit VotingRoundEnded(roundId);
    }

    // Add them 1 voter

    // Hàm lấy danh sách người bỏ phiếu cho seminar
    function getSeminarVoters(
        uint256 roundId
    ) public view onlyRole(ADMIN_ROLE) returns (address[] memory) {
        VotingRound storage round = votingRounds[roundId];
        return round.voters;
    }

    // Hàm lấy số phiếu của một speaker cụ thể
    function getSpeakerVotes(
        uint256 roundId,
        address speaker
    ) public view onlyRole(ADMIN_ROLE) returns (uint256) {
        VotingRound storage round = votingRounds[roundId];
        return round.speakerVotes[speaker];
    }

    // Hàm lấy người nói có số phiếu cao nhất
    function getWinnerSpeaker(
        uint256 roundId
    ) public view onlyRole(ADMIN_ROLE) returns (address, uint256) {
        return getMaxSpeaker(roundId);
    }

    // Hàm lấy seminar có số phiếu cao nhất
    function getWinnerSeminar(
        uint256 roundId
    ) public view onlyRole(ADMIN_ROLE) returns (uint256, uint256) {
        return getMaxSeminar(roundId);
    }

    // Hàm lấy tất cả speakers và seminars trong một vòng
    function getSpeakersAndSeminars(
        uint256 roundId
    ) public view returns (address[] memory, uint256[] memory) {
        VotingRound storage round = votingRounds[roundId];
        return (round.speakersInRound, round.seminarIds);
    }

    // Hàm nội bộ để lấy speaker có số phiếu cao nhất
    function getMaxSpeaker(
        uint256 roundId
    ) internal view returns (address max, uint256 maxVotes) {
        VotingRound storage round = votingRounds[roundId];
        address[] memory speakers = round.speakersInRound;
        require(speakers.length > 0, "No votes have been cast yet");

        maxVotes = 0;
        max = address(0);
        for (uint256 i = 0; i < speakers.length; i++) {
            if (round.speakerVotes[speakers[i]] > maxVotes) {
                maxVotes = round.speakerVotes[speakers[i]];
                max = speakers[i];
            }
        }
        return (max, maxVotes);
    }

    // Hàm nội bộ để lấy seminar có số phiếu cao nhất
    function getMaxSeminar(
        uint256 roundId
    ) internal view returns (uint256 maxSeminarId, uint256 maxVotes) {
        VotingRound storage round = votingRounds[roundId];
        uint256[] memory seminars = round.seminarIds;
        require(seminars.length > 0, "No votes have been cast yet");

        maxVotes = 0;
        maxSeminarId = 0;
        for (uint256 i = 0; i < seminars.length; i++) {
            if (totalVotes[roundId][seminars[i]] > maxVotes) {
                maxVotes = totalVotes[roundId][seminars[i]];
                maxSeminarId = seminars[i];
            }
        }
        return (maxSeminarId, maxVotes);
    }
    /// @dev Lấy danh sách speaker xếp từ vote cao xuống thấp

    function getResultWinner (uint256 roundId) public 
    view 
    onlyRole(ADMIN_ROLE) 
    returns (address[] memory sortedSpeakers, uint256[] memory sortedVotes)
    {
        VotingRound storage round = votingRounds[roundId];
        address[] memory speakers = round.speakersInRound;
        require(speakers.length > 0, "No votes and speaker yet.");
        uint256 speakerCount = speakers.length;
        sortedSpeakers = new address[](speakerCount);
        sortedVotes = new uint256[](speakerCount);
        for (uint256 i = 0; i < speakerCount; i++) {
            sortedSpeakers[i] = speakers[i];
            sortedVotes[i] = round.speakerVotes[speakers[i]];
        }
        for (uint256 i = 0; i < speakerCount; i++){
            for(uint256 j = i+1; j<speakerCount; j++){
                if (sortedVotes[i] < sortedVotes[j]) {
                uint256 temp = sortedVotes[i];
                sortedVotes[i] = sortedVotes[j];
                sortedVotes[j] = temp;
                address tempSpeaker = sortedSpeakers[i];
                sortedSpeakers[i] = sortedSpeakers[j];
                sortedSpeakers[j] = tempSpeaker;
            }
        }
        }
        return (sortedSpeakers, sortedVotes);

    }
    /// @dev change deadline
    function changeVotingDeadline(uint256 roundId, uint256 newEndTime) 
        public 
        onlyRole(ADMIN_ROLE) 
    {
        VotingRound storage round = votingRounds[roundId];
        require(round.isActive, "Voting round is not active");
        require(newEndTime > block.timestamp, "New end time must be in the future");
        require(newEndTime > round.startTime, "New end time must be after start time");

        round.endTime = newEndTime;
    }
}
