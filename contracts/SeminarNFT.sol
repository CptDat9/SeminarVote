// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract SeminarNFT is Initializable, ERC721URIStorageUpgradeable, AccessControlUpgradeable {
    uint256 public nextTokenId;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct SeminarData {
        uint256 seminarId;
        string name;
        string description;
        string image;
        string nameSpeaker;
        string metadataURI;
        address speaker;
    }

    mapping(uint256 => SeminarData) public seminars; 
    mapping(uint256 => address) public seminarSpeakers; // seminar do speaker nói

    event SeminarMinted(
        uint256 indexed tokenId,
        address indexed owner,
        string name,
        string metadataURI,
        address speaker
    );

    event MetadataUpdated(uint256 indexed tokenId, string metadataURI);

    function initialize(address admin) public initializer {
        __ERC721_init("SeminarNFT", "SNFT");
        __AccessControl_init();
        _grantRole(ADMIN_ROLE, admin);
    }
    // vì hợp đồng này kế thừa từ 2 hợp đồng ERC721URIStorageUpgradeable và AccessControlUpgradeable mà cả 2 lớp này đều có hàm này nên cần phải ghi đè hàm supportsInterface
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721URIStorageUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mintSeminar(
        string memory name,
        string memory description,
        string memory image,
        string memory nameSpeaker,
        string memory metadataURI,
        address speaker
    ) public onlyRole(ADMIN_ROLE) {
        require(speaker != address(0), "Speaker address cannot be zero");

        uint256 tokenId = nextTokenId;
        nextTokenId++;

        require(seminars[tokenId].seminarId == 0, "Seminar with this ID already exists");

        seminars[tokenId] = SeminarData({
            seminarId: tokenId,
            name: name,
            description: description,
            image: image,
            nameSpeaker: nameSpeaker,
            metadataURI: metadataURI,
            speaker: speaker
        });
        seminarSpeakers[tokenId] = speaker;

        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, metadataURI);

        emit SeminarMinted(tokenId, msg.sender, name, metadataURI, speaker);
    }

    function getSeminar(uint256 tokenId)
        public
        view
        returns (string memory, string memory, string memory, string memory, string memory, address)
    {
        require(seminars[tokenId].seminarId != 0, "Seminar does not exist");
        SeminarData memory seminar = seminars[tokenId];
        return (
            seminar.name,
            seminar.description,
            seminar.image,
            seminar.nameSpeaker,
            seminar.metadataURI,
            seminar.speaker
        );
    }
    //nếu thay đổi trên IPFS thì cần phải cập nhật lại metadataURI
    function updateMetadata(uint256 tokenId, string memory metadataURI)
        public
        onlyRole(ADMIN_ROLE)
    {
        require(seminars[tokenId].seminarId != 0, "Seminar does not exist");
        _setTokenURI(tokenId, metadataURI);
        emit MetadataUpdated(tokenId, metadataURI);
    }
}
