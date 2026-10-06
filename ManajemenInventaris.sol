// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ManajemenInventaris {
    address public owner;

    // 1. Struct Tipe Data Kustom
    struct Barang {
        uint256 id;
        string nama;
        uint256 stok;
        uint256 harga;
    }

    // Custom Error untuk efisiensi gas
    error HanyaOwner();
    error StokTidakCukup(uint256 diminta, uint256 tersedia);
    error BarangTidakAda(uint256 id);

    // 2. Mappings dan Arrays
    mapping(uint256 => Barang) public daftarBarang;
    uint256[] public listIdBarang;

    // 3. Events
    event BarangDitambahkan(uint256 indexed id, string nama, uint256 stok);
    event BarangDibeli(uint256 indexed id, address indexed pembeli, uint256 jumlah);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert HanyaOwner();
        _;
    }

    // Menambah Barang Baru
    function tambahBarang(
        uint256 id, 
        string memory nama, 
        uint256 stok, 
        uint256 harga
    ) external onlyOwner {
        // Validasi dengan require
        require(daftarBarang[id].id == 0, "ID Barang sudah terdaftar");
        require(stok > 0, "Stok awal harus lebih dari 0");

        daftarBarang[id] = Barang(id, nama, stok, harga);
        listIdBarang.push(id);

        emit BarangDitambahkan(id, nama, stok);
    }

    // Membeli Barang
    function beliBarang(uint256 id, uint256 jumlah) external payable {
        Barang storage item = daftarBarang[id];

        // Validasi menggunakan Custom Revert
        if (item.id == 0) revert BarangTidakAda(id);
        if (item.stok < jumlah) revert StokTidakCukup(jumlah, item.stok);
        require(msg.value >= item.harga * jumlah, "Pembayaran Ether kurang");

        // Pembaruan State
        item.stok -= jumlah;

        emit BarangDibeli(id, msg.sender, jumlah);
    }

    
}