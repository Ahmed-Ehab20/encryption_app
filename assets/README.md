# Dictionary Attack for Vigenère Cipher

This directory contains the Python scripts used for dictionary-based attacks on Vigenère ciphers.

## Files

- `vigenere.py` - Implementation of the Vigenère cipher for encryption and decryption
- `dictionary-attack.py` - Script that performs dictionary attacks using the included dictionary
- `dictionary.txt` - Dictionary file containing common English words
- `test.py` - Simple test script for the Vigenère cipher implementation
- `test_encryption.py` - Test script to verify encryption and decryption
- `test_dictionary_attack.py` - Test script for the dictionary attack functionality
- `find_specific_key.py` - Tool to find keys for specific ciphertext-plaintext pairs

## Testing

To test the dictionary attack on the example ciphertexts, run:

```
python test_dictionary_attack.py
```

This will test our first example by default:
- Ciphertext: `lcejczt rh tm ftaklh gtvm.`
- Key: `python`
- Plaintext: `welcome to my secret text.`

To test the second example:

```
python test_dictionary_attack.py 2
```

- Ciphertext: `Altd hlbe tg lrncmwxpo kpxs evl ztrsuicp qptspf.`
- Key: `hello`
- Plaintext: `This text is encrypted with the vigenere cipher.`

## Using in Flutter

The Flutter app integrates with these Python scripts to provide dictionary-based attacks for Vigenère cipher cracking. The integration uses the `Process` class to invoke the Python scripts and parse the results.

## Examples

### Example 1
- Ciphertext: `lcejczt rh tm ftaklh gtvm.`
- Key: `python`
- Plaintext: `welcome to my secret text.`

### Example 2
- Ciphertext: `Altd hlbe tg lrncmwxpo kpxs evl ztrsuicp qptspf.`
- Key: `hello`
- Plaintext: `This text is encrypted with the vigenere cipher.` 