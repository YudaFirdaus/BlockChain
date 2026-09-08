from block import Block


class DuplicateCertificateError(Exception):
    """Dilempar saat ada percobaan menerbitkan sertifikat baru
    untuk NIB (Nomor Induk Bidang) tanah yang sudah punya sertifikat NFT aktif.
    Ini adalah inti dari fitur anti mafia tanah: satu bidang tanah
    hanya boleh punya SATU sertifikat NFT yang sah dan aktif."""
    pass


class InvalidOwnerError(Exception):
    """Dilempar saat pihak yang mengajukan transfer bukan pemilik sah
    menurut riwayat blockchain (mencegah pemalsuan pengalihan hak)."""
    pass


class LandRegistryChain:
    """
    Blockchain untuk pendaftaran sertifikat tanah berbasis NFT digital.

    Konsep NFT di sini: setiap bidang tanah punya token_id unik (NIB).
    Token itu "non-fungible" karena setiap bidang tanah punya lokasi,
    luas, dan riwayat kepemilikan yang unik dan tidak bisa dipertukarkan
    begitu saja dengan bidang tanah lain.

    Fitur anti mafia tanah:
    - Tidak bisa menerbitkan 2 sertifikat aktif untuk NIB yang sama (anti sertifikat ganda).
    - Transfer hanya sah jika pengaju adalah owner_saat_ini menurut riwayat rantai (anti pemalsuan AJB/waris).
    - Seluruh riwayat (mint, transfer, revoke) tersimpan permanen & bisa diverifikasi (is_valid).
    """

    def __init__(self):
        self.chain = [
            self.create_genesis_block()
        ]
        # status_tanah: NIB -> {"owner": ..., "status": "AKTIF"/"DIBATALKAN", "token_id": NIB}
        self.status_tanah = {}

    def create_genesis_block(self):
        return Block(
            index=0,
            data={
                "action": "GENESIS",
                "message": "Genesis Block - Land Registry NFT Chain"
            },
            previous_hash="0"
        )

    def _add_block(self, data: dict):
        previous_block = self.chain[-1]

        new_block = Block(
            index=len(self.chain),
            data=data,
            previous_hash=previous_block.hash
        )

        self.chain.append(new_block)
        return new_block

    # ---------- MINT: Penerbitan sertifikat tanah baru sebagai NFT ----------
    def mint_certificate(
        self,
        nib: str,
        owner: str,
        location: str,
        area_m2: float,
        actor: str,
        actor_role: str = "BPN"
    ):
        """
        Menerbitkan (mint) sertifikat tanah baru sebagai NFT.
        NIB = Nomor Induk Bidang, dipakai sebagai token_id unik.
        """
        existing = self.status_tanah.get(nib)
        if existing and existing["status"] == "AKTIF":
            raise DuplicateCertificateError(
                f"NIB {nib} sudah memiliki sertifikat NFT AKTIF atas nama "
                f"{existing['owner']}. Penerbitan ganda ditolak (indikasi mafia tanah)."
            )

        block = self._add_block({
            "action": "MINT_CERTIFICATE",
            "token_id": nib,
            "nib": nib,
            "owner": owner,
            "location": location,
            "area_m2": area_m2,
            "actor": actor,
            "actor_role": actor_role,
        })

        self.status_tanah[nib] = {
            "owner": owner,
            "status": "AKTIF",
            "token_id": nib,
        }
        return block

    # ---------- TRANSFER: Jual beli / waris / hibah tanah ----------
    def transfer_ownership(
        self,
        nib: str,
        current_owner: str,
        new_owner: str,
        actor: str,
        actor_role: str = "Notaris",
        transfer_type: str = "Jual Beli"
    ):
        """
        Mentransfer kepemilikan NFT sertifikat tanah ke pemilik baru.
        Ditolak apabila current_owner tidak sesuai dengan pemilik sah
        menurut riwayat blockchain -> mencegah pemalsuan dokumen peralihan.
        """
        record = self.status_tanah.get(nib)

        if not record or record["status"] != "AKTIF":
            raise DuplicateCertificateError(
                f"NIB {nib} tidak memiliki sertifikat NFT aktif, transfer ditolak."
            )

        if record["owner"] != current_owner:
            raise InvalidOwnerError(
                f"Penjual '{current_owner}' bukan pemilik sah NIB {nib}. "
                f"Pemilik sah menurut blockchain: '{record['owner']}'. "
                f"Transfer dicurigai sebagai upaya mafia tanah dan ditolak."
            )

        block = self._add_block({
            "action": "TRANSFER_OWNERSHIP",
            "token_id": nib,
            "nib": nib,
            "from_owner": current_owner,
            "to_owner": new_owner,
            "transfer_type": transfer_type,
            "actor": actor,
            "actor_role": actor_role,
        })

        self.status_tanah[nib]["owner"] = new_owner
        return block

    # ---------- REVOKE: Pembatalan sertifikat (misal terbukti palsu) ----------
    def revoke_certificate(self, nib: str, reason: str, actor: str, actor_role: str = "BPN"):
        record = self.status_tanah.get(nib)
        if not record or record["status"] != "AKTIF":
            raise DuplicateCertificateError(
                f"NIB {nib} tidak memiliki sertifikat aktif untuk dibatalkan."
            )

        block = self._add_block({
            "action": "REVOKE_CERTIFICATE",
            "token_id": nib,
            "nib": nib,
            "reason": reason,
            "actor": actor,
            "actor_role": actor_role,
        })

        self.status_tanah[nib]["status"] = "DIBATALKAN"
        return block

    # ---------- Query riwayat kepemilikan satu bidang tanah ----------
    def get_certificate_history(self, nib: str):
        return [
            block for block in self.chain
            if block.data.get("nib") == nib
        ]

    # ---------- Validasi integritas seluruh rantai ----------
    def is_valid(self):
        for i in range(1, len(self.chain)):
            current = self.chain[i]
            previous = self.chain[i - 1]

            if current.hash != current.calculate_hash():
                return False

            if current.previous_hash != previous.hash:
                return False

        return True