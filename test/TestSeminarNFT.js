const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");
const { ERROR_PREFIX } = require("hardhat/internal/core/errors-list");

describe("SeminarNFT", function () {
    let seminarNFT, owner, admin, other, speaker;

    beforeEach(async function () {
        [owner, admin, other, speaker] = await ethers.getSigners();

        const SeminarNFTFactory = await ethers.getContractFactory("SeminarNFT");
        seminarNFT = await upgrades.deployProxy(SeminarNFTFactory, [owner.address], { initializer: "initialize" });
    });

    it("Check quyền admin của owner, admin, other, speaker", async function () {
        const ADMIN_ROLE = await seminarNFT.ADMIN_ROLE();
        expect(await seminarNFT.hasRole(ADMIN_ROLE, owner.address)).to.equal(true);
        expect(await seminarNFT.hasRole(ADMIN_ROLE, admin.address)).to.equal(false);
        expect(await seminarNFT.hasRole(ADMIN_ROLE, other.address)).to.equal(false);
        expect(await seminarNFT.hasRole(ADMIN_ROLE, speaker.address)).to.equal(false);
    });

    it("Test mintSeminar", async function () {
        const ADMIN_ROLE = await seminarNFT.ADMIN_ROLE();
        expect(await seminarNFT.hasRole(ADMIN_ROLE, owner.address)).to.equal(true);

        const _name = "FzH";
        const _description = "Fauz Handsome";
        const _image = "Fauz's image";
        const _nameSpeaker = "Fauz";
        const _metadataURI = "hehehehe";
        const _speaker = speaker.address;

        await expect(
            seminarNFT.connect(owner).mintSeminar(
            _name, 
            _description, 
            _image, 
            _nameSpeaker, 
            _metadataURI, 
            _speaker
            )
        ).to.emit(seminarNFT, "SeminarMinted")
        .withArgs(0, owner.address, _name, _metadataURI, _speaker);

        await expect(
            seminarNFT.connect(owner).mintSeminar(
            _name, 
            _description, 
            _image, 
            _nameSpeaker, 
            _metadataURI, 
            _speaker
            )
        ).to.emit(seminarNFT, "SeminarMinted")
        .withArgs(1, owner.address, _name, _metadataURI, _speaker);

        const data = await seminarNFT.connect(owner).getSeminar(1);

        expect(data[0]).to.equal(_name);
        expect(data[1]).to.equal(_description);
        expect(data[2]).to.equal(_image);
        expect(data[3]).to.equal(_nameSpeaker);
        expect(data[4]).to.equal(_metadataURI);
        expect(data[5]).to.equal(_speaker);
    });

    it("Non-admin không thể mint seminarNFT", async function () {
        await expect(
            seminarNFT.connect(other).mintSeminar(
                "Seminar",
                "fail",
                "image",
                "other",
                "metadata",
                other.address
            )
        ).to.be.reverted;
    });

    it("Non-admin không thể update data", async function () {
        await expect(
            seminarNFT.connect(other).updateMetadata(0, "new data")
        ).to.be.reverted;
    });

});
