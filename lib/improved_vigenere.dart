import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'file_utils.dart';

/// An improved implementation of the Vigenère cipher that supports both encryption and decryption.
/// Combines the best parts of the existing code with the new implementation provided.

/// Enum defining different Vigenère cipher attack methods
enum VigenereAttackMethod {
  dictionaryAttack,
  frequencyTables,
  fitness,
  crib,
  variationalChiSquared,
  variationalInnerProduct,
  statisticsOnly,
  indexOfCoincidence
}

/// Helper extension to get display names for attack methods
extension AttackMethodExtension on VigenereAttackMethod {
  String get displayName {
    switch (this) {
      case VigenereAttackMethod.dictionaryAttack:
        return 'Dictionary Attack';
      case VigenereAttackMethod.frequencyTables:
        return 'Frequency Tables';
      case VigenereAttackMethod.fitness:
        return 'Fitness';
      case VigenereAttackMethod.crib:
        return 'Using a Crib';
      case VigenereAttackMethod.variationalChiSquared:
        return 'Variational (Chi-squared)';
      case VigenereAttackMethod.variationalInnerProduct:
        return 'Variational (Inner product)';
      case VigenereAttackMethod.statisticsOnly:
        return 'Statistics-only Attack';
      case VigenereAttackMethod.indexOfCoincidence:
        return 'Index of Coincidence';
    }
  }

  String get description {
    switch (this) {
      case VigenereAttackMethod.dictionaryAttack:
        return 'Tries each word in a dictionary as a potential key and evaluates readability.';
      case VigenereAttackMethod.frequencyTables:
        return 'Uses letter frequency analysis to determine likely key letters.';
      case VigenereAttackMethod.fitness:
        return 'Compares decryption fitness against standard English patterns.';
      case VigenereAttackMethod.crib:
        return 'Uses a known piece of plaintext (crib) to find the key.';
      case VigenereAttackMethod.variationalChiSquared:
        return 'Uses chi-squared statistics to compare with expected distributions.';
      case VigenereAttackMethod.variationalInnerProduct:
        return 'Uses inner product calculations to detect language patterns.';
      case VigenereAttackMethod.statisticsOnly:
        return 'Uses statistical analysis without a dictionary.';
      case VigenereAttackMethod.indexOfCoincidence:
        return 'Uses coincidence counting to determine key length and letters.';
    }
  }
}

class VigenereUtil {
  /// Process text using the Vigenère cipher
  ///
  /// Parameters:
  /// - [text]: The text to be processed (encrypted or decrypted)
  /// - [key]: The key to use for encryption/decryption
  /// - [mode]: Either "encrypt" or "decrypt"
  ///
  /// Returns the processed text
  static String process(String text, String key, String mode) {
    if (key.isEmpty) return text;

    key = key.toLowerCase(); // Ensure key is lowercase for consistency
    String processedText = '';
    int keyIndex = 0;

    for (int i = 0; i < text.length; i++) {
      if (RegExp(r'[A-Za-z]').hasMatch(text[i])) {
        // Check if character is a letter
        int shift = key[keyIndex % key.length].codeUnitAt(0) -
            'a'.codeUnitAt(0); // key shift

        // Apply shift in correct direction based on mode
        if (mode == "decrypt") {
          shift = -shift;
        }

        int charCode = text[i].codeUnitAt(0);
        if (charCode >= 'a'.codeUnitAt(0) && charCode <= 'z'.codeUnitAt(0)) {
          charCode = ((charCode - 'a'.codeUnitAt(0) + shift + 26) % 26) +
              'a'.codeUnitAt(0);
        } else {
          charCode = ((charCode - 'A'.codeUnitAt(0) + shift + 26) % 26) +
              'A'.codeUnitAt(0);
        }

        processedText += String.fromCharCode(charCode);
        keyIndex++;
      } else {
        processedText += text[i]; // Include non-letters unchanged
      }
    }
    return processedText;
  }

  /// Encrypt text using the Vigenère cipher
  static String encrypt(String text, String key) {
    return process(text, key, "encrypt");
  }

  /// Decrypt text using the Vigenère cipher
  static String decrypt(String text, String key) {
    return process(text, key, "decrypt");
  }

  /// Perform a dictionary attack on Vigenère encrypted text
  ///
  /// This method tries to decrypt the text using each word in the provided dictionary
  /// and returns the most likely candidates based on readability scores.
  ///
  /// Parameters:
  /// - [cipherText]: The encrypted text to attack
  /// - [dictionary]: List of possible key words
  /// - [readabilityChecker]: Function that calculates readability score (0.0-1.0)
  /// - [threshold]: Minimum readability score to consider a result (0.0-1.0)
  /// - [maxResults]: Maximum number of results to return
  /// - [progressCallback]: Optional callback for progress updates (0.0-1.0)
  ///
  /// Returns a list of maps containing key, decrypted text, and score
  static Future<List<Map<String, dynamic>>> dictionaryAttack({
    required String cipherText,
    required List<String> dictionary,
    required Future<double> Function(String) readabilityChecker,
    double threshold = 0.2,
    int maxResults = 5,
    Function(double progress, String currentKey)? progressCallback,
  }) async {
    List<Map<String, dynamic>> results = [];
    int totalWords = dictionary.length;

    for (int i = 0; i < dictionary.length; i++) {
      final String key = dictionary[i];

      // Provide progress updates
      if (progressCallback != null) {
        progressCallback(i / totalWords, key);
      }

      // Decrypt with this key
      String decrypted = decrypt(cipherText, key);

      // Calculate readability score
      double score = await readabilityChecker(decrypted);

      // Only keep results above the threshold
      if (score > threshold) {
        results.add({
          'key': key,
          'decrypted': decrypted,
          'score': score * 100,
        });
      }

      // Allow UI to update
      await Future.delayed(Duration(milliseconds: 1));
    }

    // Sort results by score (highest first)
    results.sort((a, b) => b['score'].compareTo(a['score']));

    // Limit number of results if needed
    if (results.length > maxResults) {
      results = results.sublist(0, maxResults);
    }

    return results;
  }
}

/// A reusable widget for performing Vigenère cipher dictionary attacks
class VigenereAttackWidget extends StatefulWidget {
  final List<String>? dictionary;
  final String? dictionaryAssetPath;
  final Function(List<Map<String, dynamic>> results)? onResultsFound;

  const VigenereAttackWidget({
    Key? key,
    this.dictionary,
    this.dictionaryAssetPath,
    this.onResultsFound,
  }) : super(key: key);

  @override
  State<VigenereAttackWidget> createState() => _VigenereAttackWidgetState();
}

class _VigenereAttackWidgetState extends State<VigenereAttackWidget> {
  final TextEditingController _cipherTextController = TextEditingController();
  final TextEditingController _cribController =
      TextEditingController(); // For crib-based attack
  List<String> _dictionaryWords = [];
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  double _progress = 0.0;
  String _statusMessage = '';
  VigenereAttackMethod _selectedMethod = VigenereAttackMethod.dictionaryAttack;
  int _keyLengthHint = 0; // For methods that need key length hint

  @override
  void initState() {
    super.initState();
    _loadDictionary();
  }

  // Load dictionary from provided list or asset file
  Future<void> _loadDictionary() async {
    if (widget.dictionary != null) {
      setState(() {
        _dictionaryWords = widget.dictionary!;
        _statusMessage =
            'Using provided dictionary with ${_dictionaryWords.length} words';
      });
      return;
    }

    if (widget.dictionaryAssetPath != null) {
      try {
        // Use our FileUtils to load the dictionary file
        final String content =
            await FileUtils.loadTextFile(widget.dictionaryAssetPath!);

        // Process the dictionary content into a list of words
        final List<String> words = content
            .split('\n')
            .map((s) => s.trim().toLowerCase())
            .where((s) => s.isNotEmpty)
            .toList();

        print('Successfully loaded ${words.length} words from dictionary');

        setState(() {
          _dictionaryWords = words;
          _statusMessage = 'Loaded ${words.length} words from dictionary';
        });
      } catch (e) {
        print('Error loading dictionary: $e');
        setState(() {
          _statusMessage = 'Error loading dictionary: $e';
        });
        // Fallback to basic common words
        _dictionaryWords = [
          'the',
          'and',
          'for',
          'key',
          'test',
          'code',
          'hello',
          'secret',
          'password',
          'vigenere',
          'cipher',
          'flutter',
          'mobile',
          'security',
        ];
        print('Using fallback word list with ${_dictionaryWords.length} words');
      }
    }
  }

  // Simple readability checker
  Future<double> _checkReadability(String text) async {
    // Count spaces as a basic measure
    int spaces = text.split(' ').length - 1;
    double spaceRatio = text.isEmpty ? 0 : spaces / text.length;

    // Count letter frequencies that match English
    Map<String, double> englishFreq = {
      'e': 0.12,
      't': 0.09,
      'a': 0.08,
      'o': 0.07,
      'i': 0.07,
      'n': 0.07,
      's': 0.06,
      'h': 0.06,
      'r': 0.06,
      'd': 0.04,
      'l': 0.04,
      'u': 0.03,
      'c': 0.03,
      'm': 0.03,
      'w': 0.02,
    };

    Map<String, int> letterCounts = {};
    for (int i = 0; i < text.length; i++) {
      String char = text[i].toLowerCase();
      if (RegExp(r'[a-z]').hasMatch(char)) {
        letterCounts[char] = (letterCounts[char] ?? 0) + 1;
      }
    }

    int totalLetters = letterCounts.values.fold(0, (sum, count) => sum + count);
    double freqScore = 0.0;
    if (totalLetters > 0) {
      for (var entry in englishFreq.entries) {
        double expected = entry.value;
        double actual = (letterCounts[entry.key] ?? 0) / totalLetters;
        // Closer is better
        freqScore += (1.0 - (expected - actual).abs() * 5);
      }
      freqScore /= englishFreq.length;
    }

    // Combine scores (60% letter frequency, 40% space distribution)
    return (freqScore * 0.6) + (spaceRatio * 0.4);
  }

  // Run the attack based on selected method
  Future<void> _runAttack() async {
    final String cipherText = _cipherTextController.text.trim();
    if (cipherText.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter cipher text';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _progress = 0.0;
      _results = [];
      _statusMessage = 'Starting ${_selectedMethod.displayName}...';
    });

    try {
      switch (_selectedMethod) {
        case VigenereAttackMethod.dictionaryAttack:
          await _runDictionaryAttack(cipherText);
          break;
        case VigenereAttackMethod.frequencyTables:
          await _runFrequencyTablesAttack(cipherText);
          break;
        case VigenereAttackMethod.fitness:
          await _runFitnessAttack(cipherText);
          break;
        case VigenereAttackMethod.crib:
          await _runCribAttack(cipherText);
          break;
        case VigenereAttackMethod.variationalChiSquared:
          await _runVariationalAttack(cipherText, useChiSquared: true);
          break;
        case VigenereAttackMethod.variationalInnerProduct:
          await _runVariationalAttack(cipherText, useChiSquared: false);
          break;
        case VigenereAttackMethod.statisticsOnly:
          await _runStatisticsOnlyAttack(cipherText);
          break;
        case VigenereAttackMethod.indexOfCoincidence:
          await _runIoCAttack(cipherText);
          break;
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error during attack: $e';
      });
    }
  }

  Future<void> _runDictionaryAttack(String cipherText) async {
    if (_dictionaryWords.isEmpty) {
      setState(() {
        _statusMessage = 'Dictionary not loaded';
        _isLoading = false;
      });
      return;
    }

    final results = await VigenereUtil.dictionaryAttack(
        cipherText: cipherText,
        dictionary: _dictionaryWords,
        readabilityChecker: _checkReadability,
        threshold: 0.4, // Only show fairly good matches
        progressCallback: (progress, key) {
          setState(() {
            _progress = progress;
            _statusMessage = 'Testing key: $key (${(progress * 100).toInt()}%)';
          });
        });

    setState(() {
      _results = results;
      _isLoading = false;
      _statusMessage = results.isEmpty
          ? 'No matches found'
          : 'Found ${results.length} potential matches';
    });

    if (widget.onResultsFound != null) {
      widget.onResultsFound!(_results);
    }
  }

  // Frequency tables attack
  Future<void> _runFrequencyTablesAttack(String cipherText) async {
    // Get estimated key length using Index of Coincidence if not provided
    int keyLength = _keyLengthHint > 0
        ? _keyLengthHint
        : await _estimateKeyLength(cipherText);
    if (keyLength <= 0) {
      setState(() {
        _statusMessage =
            'Could not determine key length. Try setting it manually.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _statusMessage = 'Using key length: $keyLength';
    });

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
      setState(() {
        _progress = (i + 1) / keyLength;
        _statusMessage = 'Analyzing column ${i + 1}/$keyLength...';
      });

      await Future.delayed(Duration(milliseconds: 50));
    }

    // Test the generated key
    String decrypted = VigenereUtil.decrypt(cipherText, key);
    double score = await _checkReadability(decrypted);

    setState(() {
      _results = [
        {
          'key': key,
          'decrypted': decrypted,
          'score': score * 100,
          'method': 'Frequency Analysis'
        }
      ];
      _isLoading = false;
      _statusMessage = 'Found potential key: $key';
    });

    if (widget.onResultsFound != null) {
      widget.onResultsFound!(_results);
    }
  }

  // Placeholder for other attack methods
  Future<void> _runFitnessAttack(String cipherText) async {
    // Implement fitness-based attack logic
    await Future.delayed(Duration(seconds: 2)); // Simulate work
    setState(() {
      _results = [];
      _isLoading = false;
      _statusMessage = 'Fitness attack not fully implemented yet';
    });
  }

  Future<void> _runCribAttack(String cipherText) async {
    String crib = _cribController.text.trim();
    if (crib.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter a crib (known plaintext)';
        _isLoading = false;
      });
      return;
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
        double score = await _checkReadability(decrypted);

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
        setState(() {
          _progress = i / (cipherText.length - crib.length);
          _statusMessage = 'Testing crib at position $i...';
        });
        await Future.delayed(Duration(milliseconds: 1));
      }
    }

    // Sort results by score
    results.sort((a, b) => b['score'].compareTo(a['score']));

    setState(() {
      _results = results;
      _isLoading = false;
      _statusMessage = results.isEmpty
          ? 'No matches found'
          : 'Found ${results.length} potential matches';
    });

    if (widget.onResultsFound != null) {
      widget.onResultsFound!(_results);
    }
  }

  Future<void> _runVariationalAttack(String cipherText,
      {required bool useChiSquared}) async {
    // Placeholder for variational attack (chi-squared or inner product)
    await Future.delayed(Duration(seconds: 2)); // Simulate work
    setState(() {
      _results = [];
      _isLoading = false;
      _statusMessage =
          '${useChiSquared ? "Chi-squared" : "Inner product"} attack not fully implemented yet';
    });
  }

  Future<void> _runStatisticsOnlyAttack(String cipherText) async {
    // Placeholder for statistics-only attack
    await Future.delayed(Duration(seconds: 2)); // Simulate work
    setState(() {
      _results = [];
      _isLoading = false;
      _statusMessage = 'Statistics-only attack not fully implemented yet';
    });
  }

  Future<void> _runIoCAttack(String cipherText) async {
    // First, estimate key length using Index of Coincidence
    int keyLength = await _estimateKeyLength(cipherText);
    if (keyLength <= 0) {
      setState(() {
        _statusMessage = 'Could not determine key length';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _statusMessage = 'Estimated key length: $keyLength. Analyzing...';
    });

    // Now run frequency analysis using this key length
    await _runFrequencyTablesAttack(cipherText);
  }

  // Helper method to estimate key length using Index of Coincidence
  Future<int> _estimateKeyLength(String cipherText) async {
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

      setState(() {
        _progress = length / 20;
        _statusMessage = 'Testing key length $length...';
      });

      await Future.delayed(Duration(milliseconds: 50));
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

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Attack method selection
        Card(
          margin: EdgeInsets.all(16),
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
                DropdownButtonFormField<VigenereAttackMethod>(
                  value: _selectedMethod,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  items: VigenereAttackMethod.values.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(method.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedMethod = value;
                      });
                    }
                  },
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
        ),

        // Method-specific input fields
        if (_selectedMethod == VigenereAttackMethod.crib)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _cribController,
              decoration: InputDecoration(
                labelText: 'Known Plaintext (Crib)',
                border: OutlineInputBorder(),
                hintText: 'Enter a word or phrase you expect in the plaintext',
              ),
            ),
          ),

        if (_selectedMethod != VigenereAttackMethod.dictionaryAttack)
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Key Length Hint (Optional)',
                      border: OutlineInputBorder(),
                      hintText: 'If known, enter key length',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      int? length = int.tryParse(value);
                      if (length != null && length > 0) {
                        setState(() {
                          _keyLengthHint = length;
                        });
                      } else {
                        setState(() {
                          _keyLengthHint = 0; // Auto-detect
                        });
                      }
                    },
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: Icon(Icons.calculate),
                  label: Text('Estimate'),
                  onPressed: () async {
                    final text = _cipherTextController.text.trim();
                    if (text.isNotEmpty) {
                      setState(() {
                        _isLoading = true;
                        _statusMessage = 'Estimating key length...';
                      });

                      int length = await _estimateKeyLength(text);

                      setState(() {
                        _isLoading = false;
                        _keyLengthHint = length > 0 ? length : 0;
                        _statusMessage = length > 0
                            ? 'Estimated key length: $length'
                            : 'Could not estimate key length';
                      });
                    }
                  },
                ),
              ],
            ),
          ),

        // Ciphertext input area
        Padding(
          padding: EdgeInsets.all(16),
          child: TextField(
            controller: _cipherTextController,
            decoration: InputDecoration(
              labelText: 'Enter Vigenère Encrypted Text',
              border: OutlineInputBorder(),
              hintText: 'Paste the encrypted text here',
            ),
            maxLines: 4,
          ),
        ),

        // Progress indicator when loading
        if (_isLoading)
          Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: LinearProgressIndicator(value: _progress),
              ),
              SizedBox(height: 8),
              Text(_statusMessage),
            ],
          )
        else
          ElevatedButton.icon(
            icon: Icon(Icons.security),
            label: Text('Run ${_selectedMethod.displayName}'),
            onPressed:
                _cipherTextController.text.trim().isEmpty ? null : _runAttack,
          ),

        SizedBox(height: 16),

        // Results section
        if (_results.isNotEmpty)
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final result = _results[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text('Key: ${result['key']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Score: ${result['score'].toStringAsFixed(1)}%'),
                        SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black.withOpacity(0.8)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            result['decrypted'],
                            style: TextStyle(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                            text:
                                'Key: ${result['key']}\n\n${result['decrypted']}'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Copied to clipboard')),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          )
        else if (!_isLoading && _statusMessage.isNotEmpty)
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(_statusMessage),
          ),
      ],
    );
  }
}
