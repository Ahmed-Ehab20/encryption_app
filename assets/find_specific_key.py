#!/usr/bin/env python3
"""Script to find the Vigenère key for a specific ciphertext-plaintext pair."""

from vigenere import vigenere

def find_key(ciphertext, plaintext):
    """
    Find the Vigenère key given a ciphertext and its plaintext.
    
    Args:
        ciphertext (str): The encrypted text
        plaintext (str): The known plaintext (decrypted text)
    
    Returns:
        str: The key that transforms plaintext to ciphertext
    """
    # Clean and normalize the texts
    plaintext = plaintext.lower()
    ciphertext = ciphertext.lower()
    
    ALPHABET = "abcdefghijklmnopqrstuvwxyz"
    key = ""
    
    plaintext_idx = 0
    
    # For each letter in the ciphertext
    for i in range(len(ciphertext)):
        # Skip non-alphabetic characters
        if not ciphertext[i].isalpha():
            continue
            
        # Skip if we've reached the end of plaintext
        while plaintext_idx < len(plaintext) and not plaintext[plaintext_idx].isalpha():
            plaintext_idx += 1
            
        if plaintext_idx >= len(plaintext):
            break
            
        # Get the positions in the alphabet
        cipher_pos = ALPHABET.find(ciphertext[i])
        plain_pos = ALPHABET.find(plaintext[plaintext_idx])
        
        # The key letter shifts the plaintext to the ciphertext
        # For encryption: (plain + key) % 26 = cipher
        # So: key = (cipher - plain) % 26
        key_pos = (cipher_pos - plain_pos) % 26
        key += ALPHABET[key_pos]
        
        plaintext_idx += 1
    
    # Try to find a repeating pattern in the key
    for length in range(1, len(key) // 2 + 1):
        if key[:length] * (len(key) // length) + key[:len(key) % length] == key:
            return key[:length]
    
    return key

def main():
    """Run the key finding algorithm on the provided texts."""
    ciphertext = "Altd hlbe tg lrncmwxpo kpxs evl ztrsuicp qptspf."
    plaintext = "This text is encrypted with the vigenere cipher."
    
    # Find the key
    key = find_key(ciphertext, plaintext)
    print(f"\nAnalyzing Ciphertext:")
    print(f"Ciphertext: {ciphertext}")
    print(f"Known Plaintext: {plaintext}")
    print(f"\nFound key: '{key}'")
    
    # Verify the key works
    decrypted = vigenere(ciphertext, key, "decrypt")
    print(f"\nDecrypted with key '{key}':")
    print(f"Result: {decrypted}")
    print(f"Match with known plaintext? {'Yes' if decrypted.lower() == plaintext.lower() else 'No'}")
    
    # If doesn't match, try to encrypt the plaintext to see what should be the ciphertext
    encrypted = vigenere(plaintext, key, "encrypt")
    print(f"\nEncrypted plaintext with key '{key}':")
    print(f"Result: {encrypted}")
    print(f"Match with provided ciphertext? {'Yes' if encrypted.lower() == ciphertext.lower() else 'No'}")
    
    # Try with various case combinations
    print("\nTrying alternative approaches...")
    test_with_manual_alignment(ciphertext, plaintext)

def test_with_manual_alignment(ciphertext, plaintext):
    """Try to align the texts manually to handle spaces and punctuation."""
    # Extract only letters for alignment
    clean_cipher = ''.join(c.lower() for c in ciphertext if c.isalpha())
    clean_plain = ''.join(c.lower() for c in plaintext if c.isalpha())
    
    if len(clean_cipher) != len(clean_plain):
        print(f"Warning: Letter counts don't match after cleaning.")
        print(f"Cipher has {len(clean_cipher)} letters, Plain has {len(clean_plain)} letters")
    
    # Try to find key with cleaned text
    ALPHABET = "abcdefghijklmnopqrstuvwxyz"
    key_letters = []
    
    for i in range(min(len(clean_cipher), len(clean_plain))):
        cipher_pos = ALPHABET.find(clean_cipher[i])
        plain_pos = ALPHABET.find(clean_plain[i])
        
        key_pos = (cipher_pos - plain_pos) % 26
        key_letters.append(ALPHABET[key_pos])
    
    # Look for repeating patterns
    potential_key = ''.join(key_letters)
    print(f"Full derived key stream: {potential_key}")
    
    # Check common key lengths
    for length in range(1, 11):  # Check keys up to 10 characters
        if len(potential_key) >= length*2:
            test_key = potential_key[:length]
            
            # Test if this key length repeats
            reconstructed = ""
            for i in range(0, len(potential_key), length):
                reconstructed += test_key[:min(length, len(potential_key) - i)]
                
            match_rate = sum(a == b for a, b in zip(potential_key, reconstructed)) / len(potential_key)
            
            if match_rate > 0.7:  # Allow for some errors
                print(f"Potential key (length {length}): '{test_key}' - Match rate: {match_rate:.2f}")
                
                # Test decryption with this key
                decrypted = vigenere(ciphertext, test_key, "decrypt")
                plain_match = sum(a.lower() == b.lower() for a, b in zip(
                    ''.join(c for c in decrypted if c.isalpha()),
                    ''.join(c for c in plaintext if c.isalpha())
                )) / len(''.join(c for c in plaintext if c.isalpha()))
                
                print(f"  Decryption match rate: {plain_match:.2f}")
                print(f"  Decrypted: {decrypted}")

if __name__ == "__main__":
    main() 