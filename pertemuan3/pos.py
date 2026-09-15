import random

def proof_of_stake(validators):
    """
    Fungsi untuk melakukan proof-of-stake pada sebuah blok.
    Validator dipilih secara acak berdasarkan jumlah stake yang dimiliki.
    """

    # Menghitung total stake dari semua validator
    total_stake = sum(validators.values())

    # Memilih validator secara acak
    random_number = random.uniform(0, total_stake)
    current = 0

    for validator, stake in validators.items():
        current += stake
        if current >= random_number:
            return validator