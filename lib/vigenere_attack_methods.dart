import 'dart:math';
import 'package:flutter/material.dart';
import 'improved_vigenere.dart';

/// VigenereMethodSelector widget provides a toggleable interface for selecting
/// which Vigenère cipher attack method to use
class VigenereMethodSelector extends StatefulWidget {
  final Function(VigenereAttackMethod) onMethodSelected;
  final VigenereAttackMethod initialMethod;

  const VigenereMethodSelector({
    Key? key,
    required this.onMethodSelected,
    this.initialMethod = VigenereAttackMethod.dictionaryAttack,
  }) : super(key: key);

  @override
  State<VigenereMethodSelector> createState() => _VigenereMethodSelectorState();
}

class _VigenereMethodSelectorState extends State<VigenereMethodSelector> {
  late VigenereAttackMethod _selectedMethod;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.initialMethod;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attack Method',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: VigenereAttackMethod.values.map((method) {
                return ChoiceChip(
                  label: Text(method.displayName),
                  selected: _selectedMethod == method,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedMethod = method;
                      });
                      widget.onMethodSelected(method);
                    }
                  },
                  tooltip: method.description,
                );
              }).toList(),
            ),
            SizedBox(height: 8),
            Text(
              _selectedMethod.description,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Class containing implementations of different Vigenère attack methods
class VigenereAttacker {
  /// Estimate key length using Index of Coincidence
  static Future<int> estimateKeyLength(String cipherText) async {
    // Keep only letters for analysis
    String cleanText = '';
    for (int i = 0; i < cipherText.length; i++) {
      if (RegExp(r'[A-Za-z]').hasMatch(cipherText[i])) {
        cleanText += cipherText[i].toLowerCase();
      }
    }

    if (cleanText.length < 20) {
      return -1; // Not enough text for reliable analysis
    }

    // Try different key lengths and measure Index of Coincidence
    Map<int, double> iocScores = {};
    for (int length = 1; length <= 20; length++) {
      // Test reasonable key lengths
      double avgIoc = 0.0;

      // Split text into columns
      List<String> columns = List.generate(length, (i) => '');
      for (int i = 0; i < cleanText.length; i++) {
        columns[i % length] += cleanText[i];
      }

      // Calculate IoC for each column
      for (String col in columns) {
        if (col.length < 2) continue;

        // Count letter frequencies
        Map<String, int> freqCount = {};
        for (int i = 0; i < col.length; i++) {
          freqCount[col[i]] = (freqCount[col[i]] ?? 0) + 1;
        }

        // Calculate IoC
        double ioc = 0.0;
        int sum = 0;

        for (int count in freqCount.values) {
          ioc += count * (count - 1);
          sum += count;
        }

        if (sum > 1) {
          ioc /= (sum * (sum - 1));
          avgIoc += ioc;
        }
      }

      if (columns.isNotEmpty) {
        avgIoc /= columns.length;
        iocScores[length] = avgIoc;
      }
    }

    // English text has IoC around 0.067, while random text is around 0.038
    // Find the key length with highest IoC
    double highestIoc = 0.0;
    int bestLength = 0;

    for (final entry in iocScores.entries) {
      if (entry.value > highestIoc) {
        highestIoc = entry.value;
        bestLength = entry.key;
      }
    }

    // Only return if the IoC is reasonable for English-like text
    return (highestIoc > 0.055) ? bestLength : -1;
  }

  /// Attack using frequency tables
  static Future<List<Map<String, dynamic>>> frequencyTableAttack(
      String cipherText,
      int keyLength,
      Function(double progress, String status) updateProgress) async {
    if (keyLength <= 0) {
      keyLength = await estimateKeyLength(cipherText);
      if (keyLength <= 0) {
        return [];
      }
    }

    updateProgress(0.1, 'Using key length: $keyLength');

    // English letter frequency (from most to least common)
    const String englishFreq = 'etaoinsrhdlucmfywgpbvkxqjz';

    // Split the ciphertext into columns by key length
    List<String> columns = List.generate(keyLength, (i) => '');
    for (int i = 0; i < cipherText.length; i++) {
      if (RegExp(r'[A-Za-z]').hasMatch(cipherText[i])) {
        columns[i % keyLength] += cipherText[i].toLowerCase();
      }
    }

    // Analyze frequency in each column and determine most likely key letter
    String key = '';
    for (int i = 0; i < keyLength; i++) {
      final col = columns[i];
      Map<String, int> freqCount = {};

      // Count frequencies
      for (int j = 0; j < col.length; j++) {
        final char = col[j];
        freqCount[char] = (freqCount[char] ?? 0) + 1;
      }

      // Sort by frequency (descending)
      List<MapEntry<String, int>> sortedFreq = freqCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Determine most likely shift based on assuming 'e' is most common
      if (sortedFreq.isNotEmpty) {
        String mostCommon = sortedFreq.first.key;
        int mostCommonCode = mostCommon.codeUnitAt(0);
        int eCode = 'e'.codeUnitAt(0);
        int shift = (mostCommonCode - eCode + 26) % 26;
        key += String.fromCharCode('a'.codeUnitAt(0) + shift);
      } else {
        key += 'a'; // Default if column is empty
      }

      // Update progress
      updateProgress(
          (i + 1) / keyLength * 0.8, 'Analyzing column ${i + 1}/$keyLength...');

      await Future.delayed(Duration(milliseconds: 50));
    }

    updateProgress(0.9, 'Testing generated key...');

    // Test the generated key
    String decrypted = VigenereUtil.decrypt(cipherText, key);

    return [
      {
        'key': key,
        'decrypted': decrypted,
        'score': 70.0, // Estimated score
        'method': 'Frequency Analysis'
      }
    ];
  }

  /// Attack using a crib (known plaintext)
  static Future<List<Map<String, dynamic>>> cribAttack(
      String cipherText,
      String crib,
      Function(double progress, String status) updateProgress,
      Future<double> Function(String) scoreText) async {
    if (crib.isEmpty) {
      return [];
    }

    List<Map<String, dynamic>> results = [];

    // Try the crib at each position in the ciphertext
    for (int i = 0; i <= cipherText.length - crib.length; i++) {
      String cipherSegment = cipherText.substring(i, i + crib.length);

      // Try to find a key that makes this segment decrypt to the crib
      String key = '';
      bool validKey = true;

      for (int j = 0; j < crib.length; j++) {
        // Only process letters
        if (!RegExp(r'[A-Za-z]').hasMatch(crib[j]) ||
            !RegExp(r'[A-Za-z]').hasMatch(cipherSegment[j])) {
          continue;
        }

        int cipherCode =
            cipherSegment[j].toLowerCase().codeUnitAt(0) - 'a'.codeUnitAt(0);
        int cribCode = crib[j].toLowerCase().codeUnitAt(0) - 'a'.codeUnitAt(0);
        int shift = (cipherCode - cribCode + 26) % 26;

        // Add this letter to our key
        if (key.isEmpty) {
          key += String.fromCharCode('a'.codeUnitAt(0) + shift);
        } else {
          // Check if this position confirms our existing key pattern
          int expectedShift =
              key[j % key.length].codeUnitAt(0) - 'a'.codeUnitAt(0);
          if (shift != expectedShift) {
            // Try adding to the key
            key += String.fromCharCode('a'.codeUnitAt(0) + shift);
          }
        }
      }

      if (key.isNotEmpty) {
        // Test the key on the whole ciphertext
        String decrypted = VigenereUtil.decrypt(cipherText, key);
        double score = await scoreText(decrypted);

        // Check if the crib appears in the decrypted text
        if (decrypted.toLowerCase().contains(crib.toLowerCase())) {
          results.add({
            'key': key,
            'decrypted': decrypted,
            'score': score * 100,
            'method': 'Crib Attack'
          });
        }
      }

      // Update progress
      if (i % 5 == 0) {
        updateProgress(i / (cipherText.length - crib.length),
            'Testing crib at position $i...');
        await Future.delayed(Duration(milliseconds: 1));
      }
    }

    // Sort results by score
    results.sort((a, b) => b['score'].compareTo(a['score']));
    return results;
  }

  /// Attack using Index of Coincidence
  static Future<List<Map<String, dynamic>>> iocAttack(
      String cipherText,
      Function(double progress, String status) updateProgress,
      Future<double> Function(String) scoreText) async {
    // First estimate key length
    updateProgress(0.1, 'Estimating key length...');
    int keyLength = await estimateKeyLength(cipherText);

    if (keyLength <= 0) {
      return [];
    }

    updateProgress(
        0.2, 'Estimated key length: $keyLength. Running frequency analysis...');

    // Now use frequency analysis with this key length
    return await frequencyTableAttack(cipherText, keyLength,
        (progress, status) => updateProgress(0.2 + progress * 0.8, status));
  }

  /// Placeholder for Fitness Attack
  static Future<List<Map<String, dynamic>>> fitnessAttack(
      String cipherText,
      Function(double progress, String status) updateProgress,
      Future<double> Function(String) scoreText) async {
    // First estimate key length
    updateProgress(0.1, 'Estimating key length...');
    int keyLength = await estimateKeyLength(cipherText);

    if (keyLength <= 0) {
      return [];
    }

    updateProgress(0.2, 'Using key length: $keyLength');

    // Generate potential keys
    List<Map<String, dynamic>> results = [];

    // Try some random keys as a placeholder
    for (int i = 0; i < 10; i++) {
      String key = _generateRandomKey(keyLength);
      String decrypted = VigenereUtil.decrypt(cipherText, key);
      double score = await scoreText(decrypted);

      if (score > 0.2) {
        results.add({
          'key': key,
          'decrypted': decrypted,
          'score': score * 100,
          'method': 'Fitness Attack'
        });
      }

      updateProgress(0.2 + (i + 1) / 10 * 0.8, 'Testing key: $key');
      await Future.delayed(Duration(milliseconds: 50));
    }

    results.sort((a, b) => b['score'].compareTo(a['score']));
    return results;
  }

  /// Generate a random key of specified length
  static String _generateRandomKey(int length) {
    final random = Random();
    String key = '';

    for (int i = 0; i < length; i++) {
      key += String.fromCharCode('a'.codeUnitAt(0) + random.nextInt(26));
    }

    return key;
  }
}
