# Index of Coincidence (IoC) Implementation

This folder contains several files that implement Index of Coincidence (IoC) analysis for cryptanalysis, particularly focusing on Vigenère ciphers.

## Files Overview

1. **`ioc_utils.dart`**: Core utility functions for IoC calculations.
2. **`index_of_coincidence_visualizer.dart`**: Interactive visualization tool for IoC analysis.
3. **`index_of_coincidence_page.dart`**: Complete analysis page with UI for decryption.
4. **`vigenere_attack_readme.md`**: Detailed explanation of the IoC method.
5. **`main_integration.dart`**: Guide for integrating with the main app.

## Implementation Details

### Core IoC Functions

The `ioc_utils.dart` file contains standalone functions for working with IoC:

- `calculateIndexOfCoincidence()`: Calculates basic IoC for any text.
- `calculateIoCForKeyLengths()`: Analyzes multiple potential key lengths.
- `estimateKeyLength()`: Determines most likely key length based on IoC.
- `generateKeyFromFrequencyAnalysis()`: Uses frequency analysis to derive a key.

### Visualization

The visualizer is a Flutter widget that shows IoC values across different key lengths, helping users understand the analysis process visually. It includes:

- Bar chart of IoC values for key lengths 1-20
- Reference lines for English text and random distributions
- Column-by-column frequency analysis
- Interactive selection of key length

### Full Analysis Page

The main analysis page provides a complete workflow:

1. Input encrypted text
2. Analyze using IoC to find key length
3. Generate potential keys
4. Decrypt text with suggested or custom keys
5. Validate decryption quality

## How to Use

### Direct Usage

You can directly navigate to the Index of Coincidence page from anywhere in your app:

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => IndexOfCoincidencePage(
      onBackPressed: () => Navigator.of(context).pop(),
    ),
  ),
);
```

### Integration

Follow the instructions in `main_integration.dart` to integrate these tools with your main app. Options include:

- Adding a card to your home screen
- Adding a button to your cipher tools section
- Adding a menu item to your app's drawer
- Integrating with existing Vigenère cipher tools

## Example

The IoC analysis tools come with a sample encrypted text that demonstrates the effectiveness of the method. This sample is a Vigenère-encrypted text with the key "CIPHER".

## Dependencies

The implementation uses basic Flutter widgets and doesn't require external packages for the core functionality.

## Educational Value

These tools are designed to be both practical and educational. They:

1. Visualize how cryptanalysis works
2. Demonstrate statistical methods in cryptography
3. Show step-by-step process of breaking a polyalphabetic cipher
4. Provide immediate feedback on decryption quality

## Further Reading

For more detailed information about the IoC method and its applications in cryptanalysis, refer to the included `vigenere_attack_readme.md` file. 