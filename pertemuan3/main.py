from block import Block
from pow import proof_of_work
from pos import proof_of_stake

print("PROOF OF WORK")

block = Block(
    index=1,
    data="Kopi dari Farmer",
    previous_hash="0",
)

dificulty = 3  # Jumlah leading zeros yang diinginkan

print("\nData Block     : ", block.data)
print("Difificulty    : ", dificulty)

proof_of_work(block, dificulty)

print("Nonce : ", block.nonce)
print("Hash  : ", block.hash)

print("\nPROOF OF STAKE")

validators = {
    "Farmer": 70,
    "Distributor": 10,
    "warehouse": 10,
    "Retailer": 10,
}

print("\nValidator:")
for validator, stake in validators.items():
    print(f"{validator}: {stake} stake")

selected = proof_of_stake(validators)
print("\nValidator terpilih untuk memvalidasi blok: ", selected)

