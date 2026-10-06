=======================================================================
PSEUDOCODE SMART CONTRACT: LAND REGISTRY (ANTI-MAFIA TANAH)MULAI Buat Smart Contract "LandRegistryChain"

// 0. INISIALISASI
Siapkan array 'chain' untuk menyimpan rantai blok
Siapkan dictionary 'status_tanah' untuk melacak status NIB terkiniBuat Genesis Block (Blok Pertama)
Simpan Genesis Block ke dalam 'chain'

// 1. MENERBITKAN SERTIFIKAT BARU (MINT_CERTIFICATE)
// Mencegah penerbitan sertifikat ganda untuk tanah yang sama
FUNGSI MintCertificate(NIB, Pemilik, Lokasi, Luas, Aktor):
Cari NIB di dalam 'status_tanah'JIKA NIB ditemukan DAN statusnya == "AKTIF":
TOLAK TRANSAKSI (Error: DuplicateCertificateError)
Tampilkan pesan "Sertifikat ganda terdeteksi!"
SEBALIKNYA:
Buat Data Blok berisi aksi "MINT", NIB, Pemilik, Lokasi, Luas
Ambil Hash dari blok terakhir di 'chain' sebagai PreviousHash
Buat Blok Baru (Data Blok, PreviousHash)
Hitung Hash untuk Blok Baru

Tambahkan Blok Baru ke dalam 'chain'
Perbarui 'status_tanah'[NIB] menjadi -> Pemilik Baru, Status: "AKTIF"

// 2. MENTRANSFER KEPEMILIKAN (TRANSFER_OWNERSHIP)
// Mencegah pemalsuan dokumen jual-beli oleh pihak yang bukan pemilik
FUNGSI TransferOwnership(NIB, PemilikLama, PemilikBaru, Aktor, JenisTransfer):
Ambil data sertifikat berdasarkan NIB dari 'status_tanah'JIKA data tidak ditemukan ATAU status != "AKTIF":
TOLAK TRANSAKSI (Error: Tidak ada sertifikat aktif)

JIKA PemilikLama TIDAK SAMA DENGAN Pemilik di 'status_tanah':
TOLAK TRANSAKSI (Error: InvalidOwnerError)
Tampilkan pesan "Penjual bukan pemilik sah menurut blockchain!"

SEBALIKNYA JIKA VALID:
Buat Data Blok berisi aksi "TRANSFER", NIB, PemilikLama, PemilikBaru, JenisTransfer
Ambil Hash dari blok terakhir di 'chain' sebagai PreviousHash
Buat Blok Baru (Data Blok, PreviousHash)
Hitung Hash untuk Blok Baru

Tambahkan Blok Baru ke dalam 'chain'
Perbarui 'status_tanah'[NIB]['Pemilik'] menjadi -> PemilikBaru

// 3. MEMBATALKAN SERTIFIKAT (REVOKE_CERTIFICATE)
FUNGSI RevokeCertificate(NIB, Alasan, Aktor):
Ambil data sertifikat berdasarkan NIB dari 'status_tanah'JIKA data tidak ditemukan ATAU status != "AKTIF":
TOLAK TRANSAKSI (Error: Sertifikat tidak dapat dibatalkan)

SEBALIKNYA JIKA VALID:
Buat Data Blok berisi aksi "REVOKE", NIB, Alasan
Ambil Hash dari blok terakhir di 'chain' sebagai PreviousHash
Buat Blok Baru (Data Blok, PreviousHash)
Hitung Hash untuk Blok Baru

Tambahkan Blok Baru ke dalam 'chain'
Perbarui 'status_tanah'[NIB]['Status'] menjadi -> "DIBATALKAN"

// 4. MELIHAT RIWAYAT KEPEMILIKAN (GET_CERTIFICATE_HISTORY)
FUNGSI GetCertificateHistory(NIB):
Siapkan list 'riwayat_tanah'UNTUK SETIAP blok di dalam 'chain':
JIKA NIB di dalam data blok == NIB yang dicari:
Tambahkan blok tersebut ke 'riwayat_tanah'

KEMBALIKAN 'riwayat_tanah'

// 5. MEMVALIDASI INTEGRITAS BLOCKCHAIN (IS_VALID)
FUNGSI IsValid():
UNTUK indeks dari 1 sampai panjang 'chain' - 1:
CurrentBlock = chain

        indeks

PreviousBlock = chain

        indeks - 1

JIKA CurrentBlock.Hash TIDAK SAMA DENGAN hitung_ulang_hash(CurrentBlock):
KEMBALIKAN False (Blok telah dimanipulasi!)

JIKA CurrentBlock.PreviousHash TIDAK SAMA DENGAN PreviousBlock.Hash:
KEMBALIKAN False (Rantai terputus!)

KEMBALIKAN True (Rantai valid dan aman)

SELESAI
