"""Vigenere cipher implementation for encryption and decryption."""

def vigenere(message, key, direction):
    """
    Encrypt or decrypt a message using the Vigenere cipher.
    
    Args:
        message (str): The text to encrypt or decrypt
        key (str): The encryption/decryption key
        direction (str): Either "encrypt" or "decrypt"
    
    Returns:
        str: The encrypted or decrypted text
    """
    # Setup
    ALPHABET = "abcdefghijklmnopqrstuvwxyz"
    message = message.lower()
    key = key.lower()
    
    # Adjust key for message length
    while len(key) < len(message):
        key = key + key
        
    # Process the message
    result = ""
    i = 0  # Index for message
    j = 0  # Index for key (separate to handle non-alphabet chars)
    
    while i < len(message):
        # Ignore non-letter characters
        if not message[i].isalpha():
            result = result + message[i]
        else:
            # Get positions in alphabet
            letter_m = message[i]
            letter_k = key[j % len(key)]  # Use modulo to avoid index issues
            
            row = ALPHABET.find(letter_m)
            column = ALPHABET.find(letter_k)
            
            # Encrypt or decrypt based on direction
            if direction == "encrypt":
                result = result + ALPHABET[(row + column) % 26]
            elif direction == "decrypt":
                result = result + ALPHABET[(row - column + 26) % 26]  # +26 to avoid negative
                
            j += 1  # Only increment key index for alphabet characters
        
        i += 1
        
    return result

# Test functions (for debug)
if __name__ == "__main__":
    original = "Hello World"
    key = "KEY"
    encrypted = vigenere(original, key, "encrypt")
    decrypted = vigenere(encrypted, key, "decrypt")
    
    print(f"Original: {original}")
    print(f"Encrypted: {encrypted}")
    print(f"Decrypted: {decrypted}") 