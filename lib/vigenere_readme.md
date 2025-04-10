# Vigenère Cipher Dictionary Attack

This feature allows you to crack Vigenère cipher encrypted text using a full dictionary attack approach.

## How It Works

1. The system loads a comprehensive dictionary file (`lib/dictionary.txt`) containing thousands of possible key words.
2. Each word in the dictionary is used as a potential key to decrypt the provided ciphertext.
3. A readability score is calculated for each decrypted result, measuring how likely the text is to be valid English.
4. Results above a certain threshold are presented in order of their readability score.

## Usage Instructions

1. Navigate to the "Vigenère Cipher Tools" section from the main app.
2. Select the "Attack" tab.
3. Enter the Vigenère encrypted text you want to crack.
4. Click "Run Dictionary Attack".
5. The system will try all words in the dictionary and display the most promising results.

## Technical Details

- The dictionary attack process uses the full dictionary.txt file (not just a small set of words).
- For each potential key, the system:
  - Decrypts the text using the standard Vigenère algorithm
  - Analyzes letter frequencies in the result
  - Counts spaces and checks for English-like patterns
  - Calculates a readability score between 0-100%
- Results are sorted by score with the most readable results shown first

## Tips for Best Results

1. Provide enough ciphertext (at least a few sentences) for better accuracy.
2. Longer ciphertexts generally yield more accurate results.
3. The attack works best when the original plaintext is in standard English.
4. If you know the approximate length of the key, you can edit the dictionary file to focus on similar length words. 