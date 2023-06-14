import hashlib
import binascii

def token_name(txHash: str, index: int, prefix: str) -> str:
    """
    Given a tx hash, the index, and a prefix generate a unique token name.
    
    >>> token_name("1e637fd4b1a6a633261a1ba463577d65209dbbe0f7e8ec1fbfedb4c6b1bb926b", 1, "000643b0")
    000643b00138c741df813afd1e2ba521d6b798dcabbc813ac7ba84467080b9b6
    >>> token_name("1e637fd4b1a6a633261a1ba463577d65209dbbe0f7e8ec1fbfedb4c6b1bb926b", 1, "000de140")
    000de1400138c741df813afd1e2ba521d6b798dcabbc813ac7ba84467080b9b6
    >>> token_name("", 0, "")
    00a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f843
    """
    txBytes = binascii.unhexlify(txHash)
    h = hashlib.new('sha3_256')
    h.update(txBytes)
    txHash = h.hexdigest()
    x = hex(index)[-2:]
    if "x" in x:
        x = x.replace("x", "0")
    txHash = prefix + x + txHash
    print(txHash[0:64])

if __name__ == "__main__":
    import doctest
    doctest.testmod()
