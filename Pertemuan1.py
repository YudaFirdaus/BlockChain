# blockchain
# pendaftaran sertifikat tanah mencegah mafia tanah melalui sertifikat NFT digital
# https://www.blockchain.com/btc-explained

import hashlib
import json
from time import datetime

class Block:
    def __init__(self, index, timestamp, data, previous_hash):
        self.index = index
        self.timestamp = timestamp
        self.data = data
        self.previous_hash = previous_hash
        self.hash = self.calculate_hash()

    def calculate_hash(self):
        block_string = json.dumps(self.__dict__, sort_keys=True).encode()
        return hashlib.sha256(block_string).hexdigest()

class Blockchain:
    def __init__(self):
        self.chain = [self.create_genesis_block()]

    def create_genesis_block(self):
        return Block(0, datetime.now().strftime("%Y-%m-%d %H:%M:%S"), "Genesis Block", "0")