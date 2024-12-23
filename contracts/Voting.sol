// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./SeminarNFT.sol";
// các seminar được lưu thông qua những id khác nhau (tokenid) và những người nói cũng được mã hóa từ tên qua địa chỉ
contract Voting is Initializable, AccessControlUpgradeable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct VotingRound {
        uint256 startTime;
        uint256 endTime;
        uint256 maxVotesPerVoter;
        bool isActive;
        uint256[] seminarIds; // danh sách seminar trong round
        mapping(address => uint256) speakerVotes; 
    }

    SeminarNFT public seminarNFT; //kế thừa từ hợp đồng SeminarNFT để lấy vài dữ liệu
    mapping(uint256 => VotingRound) public votingRounds;
    mapping(uint256 => mapping(address => uint256)) public userVotes;
    mapping(uint256 => mapping(uint256 => uint256)) public totalVotes;

    uint256 public nextRoundId; //id của round 

    event VotingRoundCreated(uint256 indexed roundId, uint256 startTime, uint256 endTime, uint256 maxVotesPerVoter);
    event SeminarAddedToRound(uint256 indexed roundId, uint256 indexed seminarId);
    event Voted(uint256 indexed roundId, uint256 indexed seminarId, address indexed voter);
    event VotingRoundEnded(uint256 indexed roundId);

    function initialize(address admin, address seminarNFTAddress) public initializer {
        __AccessControl_init();
        _grantRole(ADMIN_ROLE, admin);
        seminarNFT = SeminarNFT(seminarNFTAddress);
    }
    // kiểm tra round này còn hoạt động không
    modifier onlyActiveRound(uint256 roundId) {
        require(votingRounds[roundId].isActive, "Voting round is not active");
        require(block.timestamp >= votingRounds[roundId].startTime, "Voting round has not started yet");
        require(block.timestamp <= votingRounds[roundId].endTime, "Voting round has ended");
        _;
    }
    // kiểm tra seminar này có trong round không thoogn qua roundId và seminarId
    modifier seminarInRound(uint256 roundId, uint256 seminarId) {
        require(isSeminarInRound(roundId, seminarId), "Seminar is not in this round");
        _;
    }
    // tạo ra một round mới
    function createVotingRound(
        uint256 startTime,
        uint256 endTime,
        uint256 maxVotesPerVoter
    ) public onlyRole(ADMIN_ROLE) {
        require(endTime > startTime, "End time must be after start time");
        require(maxVotesPerVoter > 0, "Max votes per voter must be greater than 0");

        nextRoundId++; // tăng id lên
        VotingRound storage newRound = votingRounds[nextRoundId];
        newRound.startTime = startTime;
        newRound.endTime = endTime;
        newRound.maxVotesPerVoter = maxVotesPerVoter; // số lượng vote tối đa mà mỗi người có thể vote
        newRound.isActive = true;

        emit VotingRoundCreated(nextRoundId, startTime, endTime, maxVotesPerVoter);
    }
    // thêm seminar vào round
    function addSeminarToRound(uint256 roundId, uint256 seminarId) public onlyRole(ADMIN_ROLE) {
        require(votingRounds[roundId].isActive, "Voting round is not active");
        require(seminarNFT.ownerOf(seminarId) != address(0), "Seminar does not exist"); // kiểm tra seminar có tồn tại không
        require(!isSeminarInRound(roundId, seminarId), "Seminar is already in this round"); // kiểm tra seminar đã có trong round chưa

        VotingRound storage round = votingRounds[roundId];
        round.seminarIds.push(seminarId); // thêm seminar vào round
        emit SeminarAddedToRound(roundId, seminarId);
    }

    function vote(uint256 roundId, uint256 seminarId)
        public
        onlyActiveRound(roundId)
        seminarInRound(roundId, seminarId)
    {
        VotingRound storage round = votingRounds[roundId];
        require(userVotes[roundId][msg.sender] < round.maxVotesPerVoter, "You have reached the maximum number of votes"); // người vote không được vượt quá số lượng vote tối đa

        userVotes[roundId][msg.sender]++;
        totalVotes[roundId][seminarId]++;

        address speakerAddress = seminarNFT.ownerOf(seminarId); // lấy địa chỉ của người nói
        round.speakerVotes[speakerAddress]++; // tăng số lượng vote của người nói trong 1 round khi vote +1

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

    // hàm này hơi thừa thì phải

    function checkAndEndRound(uint256 roundId) public {
        VotingRound storage round = votingRounds[roundId];
        require(round.isActive, "Voting round is already ended");

        if (block.timestamp > round.endTime) {
            round.isActive = false;
            emit VotingRoundEnded(roundId);
        }
    }
    // chủ động hủy round khi chưa tới thời hạn
    function endVotingRound(uint256 roundId) public onlyRole(ADMIN_ROLE) {
        VotingRound storage round = votingRounds[roundId];
        require(round.isActive, "Voting round is already ended");

        round.isActive = false;
        emit VotingRoundEnded(roundId);
    }
}
