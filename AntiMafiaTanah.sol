// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract LandRegistryChain {
    // 0. INISIALISASI & TIPE DATA
    address public bpnAdmin; // Pejabat Berwenang / BPN

    enum StatusSertifikat { DIBATALKAN, AKTIF } // Urutan status tanah

    struct Sertifikat {
        string nib;
        address pemilik;
        string lokasi;
        uint256 luas;
        StatusSertifikat status;
        bool isExist;
    }

    struct BlokData {
        string aksi;           // "MINT", "TRANSFER", atau "REVOKE"
        string nib;
        address dari;
        address ke;
        string detailLain;     // Alasan Pembatalan / Keterangan
        bytes32 previousHash;  // Hash dari blok sebelumnya
        bytes32 currentHash;   // Hash dari blok ini
        uint256 timestamp;
    }

    // Penyimpanan chain (array) dan status_tanah (mapping)
    BlokData[] public chain;
    mapping(string => Sertifikat) public statusTanah;

    // Custom Errors (Sesuai dengan percabangan flowchart)
    error HanyaBPN();
    error SertifikatGanda();
    error NIBTidakDitemukanAtauTidakAktif();
    error IndikasiMafiaAtauPemilikTidakSah();

    modifier onlyBPN() {
        if (msg.sender != bpnAdmin) revert HanyaBPN();
        _;
    }

    constructor() {
        bpnAdmin = msg.sender;

        // Membuat Genesis Block (Blok Pertama di Rantai Blockchain)
        bytes32 genesisHash = keccak256(abi.encodePacked("GENESIS_BLOCK", block.timestamp));
        chain.push(BlokData({
            aksi: "GENESIS",
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

    // 1. FLOWCHART MINT CERTIFICATE (Dapat dipanggil oleh BPN/Pejabat Berwenang)
    function mintCertificate(
        string memory _nib,
        address _pemilik,
        string memory _lokasi,
        uint256 _luas
    ) external onlyBPN {
        // Percabangan: Cari NIB di status_tanah, Apakah NIB sudah AKTIF?
        if (statusTanah[_nib].isExist && statusTanah[_nib].status == StatusSertifikat.AKTIF) {
            revert SertifikatGanda();
        }

        // Ambil hash dari blok sebelumnya
        bytes32 prevHash = _getLastBlockHash();
        bytes32 newHash = keccak256(abi.encodePacked("MINT", _nib, _pemilik, prevHash, block.timestamp));

        // Buat data blok baru & Simpan blok ke blockchain
        chain.push(BlokData({
            aksi: "MINT",
            nib: _nib,
            dari: address(0),
            ke: _pemilik,
            detailLain: string(abi.encodePacked("Lokasi: ", _lokasi)),
            previousHash: prevHash,
            currentHash: newHash,
            timestamp: block.timestamp
        }));

        // Update status_tanah: NIB -> Pemilik, AKTIF
        statusTanah[_nib] = Sertifikat({
            nib: _nib,
            pemilik: _pemilik,
            lokasi: _lokasi,
            luas: _luas,
            status: StatusSertifikat.AKTIF,
            isExist: true
        });
    }

    // 2. FLOWCHART TRANSFER OWNERSHIP (Dapat dipanggil oleh Pemilik Sah)
    function transferOwnership(
        string memory _nib,
        address _pemilikLama,
        address _pemilikBaru
    ) external {
        Sertifikat storage sertifikat = statusTanah[_nib];

        // Percabangan: Apakah NIB ditemukan & status AKTIF?
        if (!sertifikat.isExist || sertifikat.status != StatusSertifikat.AKTIF) {
            revert NIBTidakDitemukanAtauTidakAktif();
        }

        // Percabangan: Apakah Pemilik Lama == Pemilik di database & Pengirim adalah Pemilik Sah?
        if (sertifikat.pemilik != _pemilikLama || msg.sender != _pemilikLama) {
            revert IndikasiMafiaAtauPemilikTidakSah();
        }

        // Ambil hash dari blok sebelumnya
        bytes32 prevHash = _getLastBlockHash();
        bytes32 newHash = keccak256(abi.encodePacked("TRANSFER", _nib, _pemilikLama, _pemilikBaru, prevHash, block.timestamp));

        // Buat data blok baru & Simpan blok ke blockchain
        chain.push(BlokData({
            aksi: "TRANSFER",
            nib: _nib,
            dari: _pemilikLama,
            ke: _pemilikBaru,
            detailLain: "Pemindahan Hak Kepemilikan",
            previousHash: prevHash,
            currentHash: newHash,
            timestamp: block.timestamp
        }));

        // Update status_tanah: Pemilik Baru
        sertifikat.pemilik = _pemilikBaru;
    }

    // 3. FLOWCHART REVOKE CERTIFICATE (Dapat dipanggil oleh BPN/Pejabat Berwenang)
    function revokeCertificate(
        string memory _nib,
        string memory _alasanPembatalan
    ) external onlyBPN {
        Sertifikat storage sertifikat = statusTanah[_nib];

        // Percabangan: Apakah NIB ditemukan & status AKTIF?
        if (!sertifikat.isExist || sertifikat.status != StatusSertifikat.AKTIF) {
            revert NIBTidakDitemukanAtauTidakAktif();
        }

        // Ambil hash dari blok sebelumnya
        bytes32 prevHash = _getLastBlockHash();
        bytes32 newHash = keccak256(abi.encodePacked("REVOKE", _nib, _alasanPembatalan, prevHash, block.timestamp));

        // Buat data blok baru & Simpan blok ke blockchain
        chain.push(BlokData({
            aksi: "REVOKE",
            nib: _nib,
            dari: sertifikat.pemilik,
            ke: address(0),
            detailLain: _alasanPembatalan,
            previousHash: prevHash,
            currentHash: newHash,
            timestamp: block.timestamp
        }));

        // Update status_tanah: Ubah status jadi DIBATALKAN
        sertifikat.status = StatusSertifikat.DIBATALKAN;
    }

    // 4. FLOWCHART GET HISTORY (Melihat Riwayat Tanah dengan Melakukan Looping pada Chain)
    function getHistory(string memory _nib) external view returns (BlokData[] memory) {
        // Hitung jumlah blok yang cocok dengan NIB yang dicari
        uint256 count = 0;
        for (uint256 i = 0; i < chain.length; i++) {
            if (keccak256(bytes(chain[i].nib)) == keccak256(bytes(_nib))) {
                count++;
            }
        }

        // Siapkan array list riwayat dengan ukuran pas
        BlokData[] memory riwayat = new BlokData[](count);
        uint256 index = 0;

        // Masukkan blok yang sesuai NIB ke dalam list riwayat
        for (uint256 i = 0; i < chain.length; i++) {
            if (keccak256(bytes(chain[i].nib)) == keccak256(bytes(_nib))) {
                riwayat[index] = chain[i];
                index++;
            }
        }

        // Tampilkan seluruh list riwayat
        return riwayat;
    }
}