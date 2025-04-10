# Vigenère Cipher Attack Methods

This feature allows you to crack Vigenère cipher encrypted text using multiple methods. Choose the appropriate method based on your specific ciphertext and available information.

## Attack Methods Overview

### 1. Dictionary Attack
- **Description**: Tries each word in the dictionary as a potential key and evaluates readability.
- **How it works**: Each dictionary word is used as a key to decrypt the text, then the result is scored based on readability.
- **Best for**: When you suspect the key is a common word or phrase.
- **Requirements**: A good dictionary file with likely key words.

### 2. Frequency Tables
- **Description**: Uses letter frequency analysis to determine likely key letters.
- **How it works**: Splits ciphertext into columns based on key length, then analyzes letter frequencies in each column.
- **Best for**: Longer ciphertexts where statistical patterns emerge clearly.
- **Requirements**: Knowing or accurately estimating the key length helps significantly.

### 3. Fitness
- **Description**: Compares decryption fitness against standard English patterns.
- **How it works**: Uses statistical metrics to evaluate how closely decrypted text matches natural language patterns.
- **Best for**: When you have a good language model or set of expected patterns.
- **Requirements**: Sufficient ciphertext length for pattern analysis.

### 4. Using a Crib
- **Description**: Uses a known piece of plaintext (crib) to find the key.
- **How it works**: Tests where in the ciphertext the known plaintext might occur, then derives key letters.
- **Best for**: When you know or can guess a portion of the plaintext.
- **Requirements**: A reliable crib (known plaintext segment).

### 5. Variational Methods
- **Chi-squared Statistic**: Uses chi-squared statistics to compare with expected distributions.
- **Inner Product**: Uses inner product calculations to detect language patterns.
- **Best for**: More sophisticated statistical analysis when other methods fail.
- **Requirements**: Good statistical models of the expected plaintext language.

### 6. Statistics-only Attack
- **Description**: Uses statistical analysis without a dictionary.
- **How it works**: Relies solely on statistical properties of the ciphertext.
- **Best for**: When dictionary attacks are not feasible or dictionary words unlikely to be the key.
- **Requirements**: Sufficient ciphertext to extract meaningful statistics.

### 7. Index of Coincidence
- **Description**: Uses coincidence counting to determine key length and letters.
- **How it works**: Analyzes repeated patterns in the ciphertext to estimate key length, then uses frequency analysis.
- **Best for**: First step in breaking a Vigenère cipher when key length is unknown.
- **Requirements**: Enough ciphertext to calculate meaningful coincidence statistics.

## Usage Tips

1. **Start with Index of Coincidence** to determine the key length.
2. **Try Frequency Tables** next for a first attempt at the key.
3. **Use Dictionary Attack** if you suspect the key is a common word.
4. **Try Crib attack** if you know part of the plaintext.
5. **For complex cases**, the advanced statistical methods may yield better results.

## Key Length Estimation

Most methods work better if you know the key length. The system can attempt to estimate this using the Index of Coincidence (IoC):

1. Higher IoC values (~0.067 for English) indicate more pattern repetition
2. IoC peaks at multiples of the actual key length
3. The first significant peak typically corresponds to the actual key length

When in doubt, provide more ciphertext - longer text yields more accurate statistical analysis. 