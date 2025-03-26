# Cyphy - Cryptography Toolkit

A Flutter application for encryption, decryption, and cryptanalysis of various classical ciphers.

## Features

- **Encryption & Decryption**: Support for multiple cipher types including Caesar, Vigenère, and Rail Fence
- **Cryptanalysis**: Automatic cracking of encrypted messages
- **Dictionary Attack**: Vigenère cipher cracking using dictionary-based attacks
- **History Tracking**: Keep track of all encryption/decryption operations
- **Modern UI**: Clean, responsive user interface with light/dark mode support

## Cipher Types

### Caesar Cipher
Simple substitution cipher that shifts letters by a fixed number of positions.

### Vigenère Cipher
Polyalphabetic substitution cipher using a keyword to determine the shift for each letter.

### Rail Fence Cipher
Transposition cipher that writes text in a zigzag pattern across multiple "rails" and reads off by row.

## Cryptanalysis

The app includes advanced functionality for cracking encrypted messages:

### Dictionary Attack
For Vigenère ciphers, the app uses a Python script to perform dictionary-based attacks:

1. Tries each word in a dictionary as a potential key
2. Decrypts the ciphertext with each key
3. Analyzes the results to find readable plaintext
4. Returns keys sorted by likelihood

## Installation

1. Clone the repository
2. Ensure Flutter is installed and set up
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the app

## Python Integration

The app integrates with Python scripts for advanced cryptanalysis:

- **vigenere.py**: Implementation of the Vigenère cipher
- **dictionary-attack.py**: Script for dictionary-based attacks
- **dictionary.txt**: Dictionary file with common words

## Example

Try these built-in examples:

### Example 1
- Ciphertext: `lcejczt rh tm ftaklh gtvm.`
- Key: `python`
- Plaintext: `welcome to my secret text.`

### Example 2
- Ciphertext: `Altd hlbe tg lrncmwxpo kpxs evl ztrsuicp qptspf.`
- Key: `hello`
- Plaintext: `This text is encrypted with the vigenere cipher.`

## Technologies Used

- Flutter for cross-platform UI
- Dart for app logic
- Python for advanced cryptanalysis algorithms
