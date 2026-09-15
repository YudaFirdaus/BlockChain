import hashlib
import time

def proof_of_work(block, difficulty):
    """
    Fungsi untuk melakukan proof-of-work pada sebuah blok.
    Blok akan diubah nonce-nya hingga hash-nya memenuhi kriteria kesulitan (difficulty).
    """

    # Membuat target string yang harus dicapai oleh hash
    target = '0' * difficulty

    start_time = time.time()
    
    while not block.hash.startswith(target):
        block.nonce += 1
        block.hash = hashlib.sha256(
            (
            str(block.index)
            + block.data
            + block.previous_hash
            + str(block.nonce)
        ) .encode()
        ).hexdigest()

    end_time = time.time()

    print("\nMining selesai!")
    print("Nonce : ", block.nonce)
    print("Waktu : ", round(end_time - start_time, 4), "detik")
