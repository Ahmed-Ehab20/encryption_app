#!/usr/bin/env python3
import sys
import re
from collections import Counter
import string

# English letter frequencies
ENGLISH_FREQS = {
    'A': 0.08167, 'B': 0.01492, 'C': 0.02802, 'D': 0.04271, 'E': 0.12702,
    'F': 0.02228, 'G': 0.02015, 'H': 0.06094, 'I': 0.06966, 'J': 0.00153,
    'K': 0.00772, 'L': 0.04025, 'M': 0.02406, 'N': 0.06749, 'O': 0.07507,
    'P': 0.01929, 'Q': 0.00095, 'R': 0.05987, 'S': 0.06327, 'T': 0.09056,
    'U': 0.02758, 'V': 0.00978, 'W': 0.02360, 'X': 0.00150, 'Y': 0.01974,
    'Z': 0.00074
}

def vigenere_decrypt(text, key):
    """Decrypt text using the Vigenère cipher with the given key."""
    result = []
    key = key.upper()
    i = 0
    
    for char in text:
        if char.isalpha():
            # For each alphabet character, shift it by the corresponding character in the key
            is_upper = char.isupper()
            char_code = ord(char.upper()) - ord('A')
            key_code = ord(key[i % len(key)]) - ord('A')
            
            # Apply Vigenère formula: (char_code - key_code) % 26
            decrypted_code = (char_code - key_code) % 26
            decrypted_char = chr(decrypted_code + ord('A'))
            
            # Preserve original case
            if not is_upper:
                decrypted_char = decrypted_char.lower()
                
            result.append(decrypted_char)
            i += 1
        else:
            # Pass through non-alphabet characters unchanged
            result.append(char)
    
    return ''.join(result)

def get_letter_frequency(text):
    """Calculate frequency of each letter in the text."""
    text = text.upper()
    text = re.sub(r'[^A-Z]', '', text)
    letter_count = Counter(text)
    total_letters = len(text)
    
    frequencies = {}
    for letter in string.ascii_uppercase:
        frequencies[letter] = letter_count.get(letter, 0) / total_letters
    
    return frequencies

def chi_squared(observed, expected):
    """Calculate chi-squared statistic for comparing letter frequencies."""
    return sum((observed.get(letter, 0) - expected.get(letter, 0))**2 / expected.get(letter, 0.01) 
               for letter in string.ascii_uppercase)

def find_key_letter(text):
    """Find the most likely shift for a single letter based on frequency analysis."""
    best_shift = 0
    best_score = float('inf')
    
    for shift in range(26):
        # Apply the shift
        shifted_text = ''.join(chr(((ord(c.upper()) - ord('A') + shift) % 26) + ord('A')) 
                             if c.isalpha() else c for c in text)
        
        # Get frequencies of the shifted text
        obs_freqs = get_letter_frequency(shifted_text)
        
        # Calculate chi-squared statistic against expected English frequencies
        score = chi_squared(obs_freqs, ENGLISH_FREQS)
        
        if score < best_score:
            best_score = score
            best_shift = shift
    
    # Convert the shift to its corresponding letter
    return chr(((26 - best_shift) % 26) + ord('A'))

def find_repeated_sequences(text, min_length=3, max_length=5):
    """Find repeated sequences in text and their positions."""
    text = text.upper()
    
    results = {}
    for length in range(min_length, max_length + 1):
        for i in range(len(text) - length + 1):
            seq = text[i:i+length]
            
            # Skip sequences that contain non-alphabetic characters
            if not seq.isalpha():
                continue
                
            # If we've already seen this sequence, record the spacing
            if seq in results:
                results[seq].append(i)
            else:
                results[seq] = [i]
    
    # Filter to keep only sequences that appear more than once
    return {seq: positions for seq, positions in results.items() if len(positions) > 1}

def get_spacings(positions):
    """Get the spacings between positions."""
    return [positions[i] - positions[i-1] for i in range(1, len(positions))]

def get_factors(number):
    """Get all factors of a number."""
    factors = []
    for i in range(2, int(number**0.5) + 1):
        if number % i == 0:
            factors.append(i)
            if i != number // i:
                factors.append(number // i)
    return sorted(factors)

def find_key_length(text, max_length=20):
    """Find the most likely key length based on repeated sequences."""
    repeated = find_repeated_sequences(text)
    
    # Collect all spacings
    all_spacings = []
    for seq, positions in repeated.items():
        all_spacings.extend(get_spacings(positions))
    
    # Count factors of spacings
    factor_counts = Counter()
    for spacing in all_spacings:
        factors = get_factors(spacing)
        factor_counts.update(factors)
    
    # Limit to reasonable key lengths
    candidates = [f for f, count in factor_counts.most_common() 
                 if f <= max_length]
    
    return candidates[:3] if candidates else [5, 6, 7]  # Default lengths if no good candidates

def get_nth_letters(text, key_length, nth):
    """Extract every nth letter for a specific position in the key."""
    text = ''.join(c.upper() for c in text if c.isalpha())
    return text[nth::key_length]

def crack_vigenere(text):
    """Attempt to crack a Vigenère cipher by finding the key."""
    # Try common words first
    common_keys = ["THE", "KEY", "VIGENERE", "CIPHER", "PASSWORD", "SECRET"]
    best_results = []
    
    for key in common_keys:
        decrypted = vigenere_decrypt(text, key)
        # Quick check if the text looks like English
        freq = get_letter_frequency(decrypted)
        score = chi_squared(freq, ENGLISH_FREQS)
        
        if score < 300:  # Threshold for "good enough" English text
            best_results.append((key, decrypted, score))
    
    # If we found good results with common keys, return them
    if best_results:
        best_results.sort(key=lambda x: x[2])
        return best_results[:3]
    
    # Otherwise, analyze the text to find the key
    likely_key_lengths = find_key_length(text)
    results = []
    
    for key_length in likely_key_lengths:
        key = ''
        for i in range(key_length):
            nth_letters = get_nth_letters(text, key_length, i)
            key_letter = find_key_letter(nth_letters)
            key += key_letter
        
        decrypted = vigenere_decrypt(text, key)
        
        # Check if the text looks like English
        freq = get_letter_frequency(decrypted)
        score = chi_squared(freq, ENGLISH_FREQS)
        
        results.append((key, decrypted, score))
    
    # Sort by chi-squared score (lower is better)
    results.sort(key=lambda x: x[2])
    return results[:3]

def main():
    # Get ciphertext from file or stdin
    if len(sys.argv) > 1:
        with open(sys.argv[1], 'r') as f:
            ciphertext = f.read().strip()
    else:
        ciphertext = input("Enter ciphertext: ").strip()
    
    # Skip if empty
    if not ciphertext:
        print("No ciphertext provided!")
        return
    
    # Attempt to crack
    results = crack_vigenere(ciphertext)
    
    # Print results
    for key, decrypted, score in results:
        print(f"{key}: {decrypted[:100]}")  # Print only first 100 chars to keep output reasonable
    
if __name__ == "__main__":
    main() 