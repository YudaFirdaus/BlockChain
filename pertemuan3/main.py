from block import Block
from pow import proof_of_work
from pos import proof_of_stake

print("PROOF OF WORK")

block = Block(
    index=1,
    data="Kopi dari Farmer",
    previous_hash="0",
)

dificulty = 4  # Jumlah leading zeros yang diinginkan

print("\nData Block     : ", block.data)
print("Difificultu      : ", dificulty)

proof_of_work(block, dificulty)

print("Nonce            : ", block.nonce)
print("Hash             : ", block.hash)

print("\nPROOF OF STAKE")

validators = {
    "Farmer": 10,
    "Distributor": 20,
    "warehouse": 30,
    "Retailer": 40,
}

print("\nValidator:")
for validator, stake in validators.items():
    print(f"{validator}: {stake} stake")

selected = proof_of_stake(validators)
print("\nValidator terpilih untuk memvalidasi blok: ", selected)

