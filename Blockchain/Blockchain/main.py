from blockchain import LandRegistryChain, DuplicateCertificateError, InvalidOwnerError

registry = LandRegistryChain()

# 1. BPN (Badan Pertanahan Nasional) menerbitkan sertifikat tanah sebagai NFT
registry.mint_certificate(
    nib="NIB-32.09.010203.0001",
    owner="fadhila itmamul fiqri",
    location="Kel. sampih, Cirebon",
    area_m2=250,
    actor="Petugas BPN Cirebon",
    actor_role="BPN"
)

# 2. Notaris memproses jual beli tanah dari Ahmad ke Siti (aktor tambahan #1)
registry.transfer_ownership(
    nib="NIB-32.09.010203.0001",
    current_owner="fadhila itmamul fiqri",
    new_owner="yuda firdaus",
    actor="Notaris fadhila itmamul fiqri",
    actor_role="Notaris",
    transfer_type="Jual Beli"
)

# 3. Siti menghibahkan tanah ke anaknya, diproses oleh PPAT (aktor tambahan #2)
registry.transfer_ownership(
    nib="NIB-32.09.010203.0001",
    current_owner="yuda firdaus",
    new_owner="taohid",
    actor="PPAT yuda firdaus",
    actor_role="PPAT",
    transfer_type="Hibah"
)

# 4. PERCOBAAN MAFIA TANAH #1: pihak lain mencoba menerbitkan sertifikat
#    kedua untuk NIB yang sama (sertifikat ganda / tumpang tindih)
print("Percobaan penerbitan sertifikat ganda (mafia tanah):")
try:
    registry.mint_certificate(
        nib="NIB-32.09.010203.0001",
        owner="Joko Palsu",
        location="Kel. Kejaksan, Cirebon",
        area_m2=250,
        actor="Oknum Calo Tanah",
        actor_role="Tidak Dikenal"
    )
except DuplicateCertificateError as e:
    print("  DITOLAK:", e)

# 5. PERCOBAAN MAFIA TANAH #2: seseorang yang bukan pemilik sah
#    mencoba menjual tanah milik orang lain memakai dokumen palsu
print("\nPercobaan transfer oleh pihak yang bukan pemilik sah:")
try:
    registry.transfer_ownership(
        nib="NIB-32.09.010203.0001",
        current_owner="Ahmad Sutrisno",   # sudah bukan pemilik sah saat ini
        new_owner="Pembeli Tanpa Curiga",
        actor="Calo Tanah",
        actor_role="Tidak Dikenal",
        transfer_type="Jual Beli"
    )
except InvalidOwnerError as e:
    print("  DITOLAK:", e)

# ---------------- Cetak seluruh riwayat blockchain ----------------
print("\n" + "=" * 70)
print("RIWAYAT LENGKAP BLOCKCHAIN SERTIFIKAT TANAH")
print("=" * 70)

for block in registry.chain:
    print("=" * 70)
    print("INDEX      :", block.index)
    print("TIMESTAMP  :", block.timestamp)
    print("DATA       :", block.data)
    print("PREV HASH  :", block.previous_hash)
    print("HASH       :", block.hash)

# ---------------- Riwayat kepemilikan satu NFT tanah tertentu ----------------
print("\n" + "=" * 70)
print("RIWAYAT KEPEMILIKAN NIB-32.09.010203.0001 (Rantai Kepemilikan NFT)")
print("=" * 70)
for block in registry.get_certificate_history("NIB-32.09.010203.0001"):
    print(f"- [{block.data['action']}] {block.data}")

# ---------------- Cek status kepemilikan saat ini ----------------
print("\nPemilik sah saat ini:", registry.status_tanah["NIB-32.09.010203.0001"]["owner"])

# ---------------- Validasi integritas rantai ----------------
print("\nBlockchain valid:", registry.is_valid())