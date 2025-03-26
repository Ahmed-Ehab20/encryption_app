#!/usr/bin/env python3
"""Simple test script for Vigenère cipher and dictionary attack."""

from vigenere import vigenere
import os

def main():
    """Run a simple test of Vigenère cipher with known key."""
    # Example text used in the dictionary-attack.py
    ciphertext = "lcejczt rh tm ftaklh gtvm."
    known_key = "python"
    
    # The expected plaintext for verification
    expected = "welcome to my secret text."
    
    # Decrypt with known key
    decrypted = vigenere(ciphertext, known_key, "decrypt")
    
    print(f"\nVigenère Cipher Test")
    print(f"===================")
    print(f"Ciphertext: {ciphertext}")
    print(f"Key: {known_key}")
    print(f"Decrypted: {decrypted}")
    print(f"Expected:  {expected}")
    print(f"Match? {'Yes' if decrypted.lower() == expected.lower() else 'No'}")
    
    # Check if dictionary.txt exists
    dict_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'dictionary.txt')
    if os.path.exists(dict_path):
        print(f"\nThe dictionary file exists at: {dict_path}")
        
        # Count words in dictionary
        try:
            with open(dict_path, 'r') as f:
                words = f.readlines()
            print(f"Dictionary contains {len(words)} words")
            print(f"First few words: {', '.join(w.strip() for w in words[:5])}")
            
            # Check if 'python' is in the dictionary
            python_found = any(word.strip().lower() == 'python' for word in words)
            print(f"Is 'python' in the dictionary? {'Yes' if python_found else 'No'}")
        except Exception as e:
            print(f"Error reading dictionary: {e}")
    else:
        print(f"\nWarning: Dictionary file not found at {dict_path}")

if __name__ == "__main__":
    main() 