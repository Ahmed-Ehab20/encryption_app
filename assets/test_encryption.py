#!/usr/bin/env python3
"""Test script to verify Vigenère encryption matches expected values."""

from vigenere import vigenere

def main():
    """Verify Vigenère encryption and decryption."""
    # The example from the dictionary-attack.py
    ciphertext = "lcejczt rh tm ftaklh gtvm."
    expected_plaintext = "welcome to my secret text."
    key = "python"
    
    # Try both encryption and decryption
    try_encrypt = vigenere(expected_plaintext, key, "encrypt")
    try_decrypt = vigenere(ciphertext, key, "decrypt")
    
    print("\nEncryption Test:")
    print(f"Plaintext: {expected_plaintext}")
    print(f"Key: {key}")
    print(f"Encrypted: {try_encrypt}")
    print(f"Expected Ciphertext: {ciphertext}")
    print(f"Match? {'Yes' if try_encrypt == ciphertext else 'No'}")
    
    print("\nDecryption Test:")
    print(f"Ciphertext: {ciphertext}")
    print(f"Key: {key}")
    print(f"Decrypted: {try_decrypt}")
    print(f"Expected Plaintext: {expected_plaintext}")
    print(f"Match? {'Yes' if try_decrypt == expected_plaintext else 'No'}")
    
    # If they don't match, see if the issue is case sensitivity or whitespace
    if try_decrypt != expected_plaintext:
        print("\nDetailed comparison:")
        if try_decrypt.lower() == expected_plaintext.lower():
            print("Issue is case sensitivity")
        elif try_decrypt.replace(" ", "") == expected_plaintext.replace(" ", ""):
            print("Issue is whitespace")
        else:
            print("Characters differ")
            print(f"Length of decrypted: {len(try_decrypt)}")
            print(f"Length of expected: {len(expected_plaintext)}")
            for i, (d, e) in enumerate(zip(try_decrypt, expected_plaintext)):
                if d != e:
                    print(f"Difference at position {i}: '{d}' vs '{e}'")

if __name__ == "__main__":
    main() 