// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 1. IMPORT LIBRARY ERC-721 / ERC721URISTORAGE
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

// 2. INHERITANCE / PEWARISAN CONTRACT ERC721URISTORAGE
contract LandRegistryChain is ERC721URIStorage {
    // 0. INISIALISASI & TIPE DATA
    address public bpnAdmin; // Pejabat Berwenang / BPN

    enum StatusSertifikat { DIBATALKAN, AKTIF } // Status sertifikat tanah

    // 7. HUBUNGKAN NFT DENGAN DATA PROJECT (Menambahkan tokenId pada struct)
    struct Sertifikat {
        uint256 tokenId;
        string nib;
        address pemilik;
        string lokasi;
        uint256 luas;
        StatusSertifikat status;
        bool isExist;
    }

    struct BlokData {
        string aksi;           // "MINT", "TRANSFER", atau "REVOKE"
        uint256 tokenId;
        string nib;
        address dari;
        address ke;
        string detailLain;     // Alasan Pembatalan / Keterangan
        bytes32 previousHash;  // Hash dari blok sebelumnya
        bytes32 currentHash;   // Hash dari blok ini
        uint256 timestamp;
    }

    // 4. PENYIMPANAN TOKEN ID & MAPPING
    uint256 private nextTokenId = 1; // Auto-increment Token ID

    // Mapping Token ID -> Data Sertifikat
    mapping(uint256 => Sertifikat) public sertifikats;
    // Mapping NIB -> Token ID (untuk mempermudah validasi duplikasi NIB)
    mapping(string => uint256) public nibToTokenId;

    // Chain histori audit internal
    BlokData[] public chain;

    // Custom Errors
    error HanyaBPN();
    error SertifikatGanda();
    error SertifikatTidakDitemukanAtauTidakAktif();
    error IndikasiMafiaAtauPemilikTidakSah();

    modifier onlyBPN() {
        if (msg.sender != bpnAdmin) revert HanyaBPN();
        _;
    }

    // 3. CONSTRUCTOR ERC-721
    constructor() ERC721("Sertifikat Tanah NFT", "LAND") {
        bpnAdmin = msg.sender;

        // Membuat Genesis Block
        bytes32 genesisHash = keccak256(abi.encodePacked("GENESIS_BLOCK", block.timestamp));
        chain.push(BlokData({
            aksi: "GENESIS",
            tokenId: 0,
            nib: "0",
            dari: address(0),
            ke: address(0),
            detailLain: "Genesis Block Land Registry",
            previousHash: bytes32(0),
            currentHash: genesisHash,
            timestamp: block.timestamp
        }));
    }

    // Helper untuk mengambil hash blok terakhir
    function _getLastBlockHash() internal view returns (bytes32) {
        return chain[chain.length - 1].currentHash;
    }

    // 5. FUNGSI MINT INTERNAL
    function mintNFT(
        address to,
        uint256 tokenId,
        string memory metadataURI
    ) internal {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, metadataURI);
    }

    // 6. FUNGSI CEK PEMILIK NFT
    function getSertifikatOwner(uint256 tokenId) public view returns (address) {
        require(_ownerOf(tokenId) != address(0), "NFT Sertifikat tidak ditemukan");
        return ownerOf(tokenId);
    }

    // 8. INTEGRASI MINT DENGAN FUNGSI PROJECT (mintCertificate)
    function mintCertificate(
        string memory _nib,
        address _pemilik,
        string memory _lokasi,
        uint256 _luas,
        string memory _metadataURI
    ) external onlyBPN returns (uint256) {
        // Cek apakah NIB sudah terdaftar dan AKTIF
        uint256 existingTokenId = nibToTokenId[_nib];
        if (existingTokenId != 0 && sertifikats[existingTokenId].status == StatusSertifikat.AKTIF) {
            revert SertifikatGanda();
        }

        // Ambil Token ID saat ini
        uint256 tokenId = nextTokenId;

        // Mint NFT ERC-721 ke wallet pemilik
        mintNFT(_pemilik, tokenId, _metadataURI);

        // Increment Token ID berikutnya
        nextTokenId++;

        // Simpan data sertifikat terhubung dengan Token ID
        sertifikats[tokenId] = Sertifikat({
            tokenId: tokenId,
            nib: _nib,
            pemilik: _pemilik,
            lokasi: _lokasi,
            luas: _luas,
            status: StatusSertifikat.AKTIF,
            isExist: true
        });

        nibToTokenId[_nib] = tokenId;

        // Catat ke dalam Rantai Blok Histori
        bytes32 prevHash = _getLastBlockHash();
        bytes32 newHash = keccak256(abi.encodePacked("MINT", tokenId, _nib, _pemilik, prevHash, block.timestamp));

        chain.push(BlokData({
            aksi: "MINT",
            tokenId: tokenId,
            nib: _nib,
            dari: address(0),
            ke: _pemilik,
            detailLain: string(abi.encodePacked("Lokasi: ", _lokasi)),
            previousHash: prevHash,
            currentHash: newHash,
            timestamp: block.timestamp
        }));

        return tokenId;
    }

    // 9. TRANSFER OWNERSHIP & SINKRONISASI ERC-721 NFT
    function transferCertificateOwnership(
        uint256 _tokenId,
        address _pemilikBaru
    ) external {
        Sertifikat storage sertifikat = sertifikats[_tokenId];

        // Validasi keberadaan sertifikat & status aktif
        if (!sertifikat.isExist || sertifikat.status != StatusSertifikat.AKTIF) {
            revert SertifikatTidakDitemukanAtauTidakAktif();
        }

        // Validasi bahwa pengirim adalah pemilik sah NFT di ERC-721 & database
        address pemilikSaatIni = ownerOf(_tokenId);
        if (pemilikSaatIni != msg.sender || sertifikat.pemilik != msg.sender) {
            revert IndikasiMafiaAtauPemilikTidakSah();
        }

        // Transfer Token NFT ERC-721 dari pemilik lama ke pemilik baru
        _transfer(msg.sender, _pemilikBaru, _tokenId);

        // Update data pemilik di dalam struct
        sertifikat.pemilik = _pemilikBaru;

        // Catat ke histori blockchain
        bytes32 prevHash = _getLastBlockHash();
        bytes32 newHash = keccak256(abi.encodePacked("TRANSFER", _tokenId, sertifikat.nib, msg.sender, _pemilikBaru, prevHash, block.timestamp));

        chain.push(BlokData({
            aksi: "TRANSFER",
            tokenId: _tokenId,
            nib: sertifikat.nib,
            dari: msg.sender,
            ke: _pemilikBaru,
            detailLain: "Pemindahan Hak Kepemilikan Sertifikat Tanah",
            previousHash: prevHash,
            currentHash: newHash,
            timestamp: block.timestamp
        }));
    }

    // REVOKE CERTIFICATE (Pembatalan Sertifikat oleh BPN)
    function revokeCertificate(
        uint256 _tokenId,
        string memory _alasanPembatalan
    ) external onlyBPN {
        Sertifikat storage sertifikat = sertifikats[_tokenId];

        if (!sertifikat.isExist || sertifikat.status != StatusSertifikat.AKTIF) {
            revert SertifikatTidakDitemukanAtauTidakAktif();
        }

        bytes32 prevHash = _getLastBlockHash();
        bytes32 newHash = keccak256(abi.encodePacked("REVOKE", _tokenId, sertifikat.nib, _alasanPembatalan, prevHash, block.timestamp));

        chain.push(BlokData({
            aksi: "REVOKE",
            tokenId: _tokenId,
            nib: sertifikat.nib,
            dari: sertifikat.pemilik,
            ke: address(0),
            detailLain: _alasanPembatalan,
            previousHash: prevHash,
            currentHash: newHash,
            timestamp: block.timestamp
        }));

        sertifikat.status = StatusSertifikat.DIBATALKAN;
    }

    // RIWAYAT BERDASARKAN TOKEN ID
    function getHistoryByTokenId(uint256 _tokenId) external view returns (BlokData[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < chain.length; i++) {
            if (chain[i].tokenId == _tokenId) {
                count++;
            }
        }

        BlokData[] memory riwayat = new BlokData[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < chain.length; i++) {
            if (chain[i].tokenId == _tokenId) {
                riwayat[index] = chain[i];
                index++;
            }
        }

        return riwayat;
    }
}