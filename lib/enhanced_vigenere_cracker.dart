import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'dart:collection';
import 'improved_vigenere.dart'; // Import existing Vigenere utility

class VigenereCrackingMethod {
  final String name;
  final String description;
  final IconData icon;
  final bool isDefaultEnabled;

  const VigenereCrackingMethod({
    required this.name,
    required this.description,
    required this.icon,
    this.isDefaultEnabled = false,
  });
}

class EnhancedVigenereCracker {
  // Available cracking methods
  static const List<VigenereCrackingMethod> availableMethods = [
    VigenereCrackingMethod(
      name: 'Dictionary Attack',
      description: 'Tries common words and phrases as potential keys',
      icon: Icons.menu_book,
      isDefaultEnabled: true,
    ),
    VigenereCrackingMethod(
      name: 'Key Length Analysis',
      description:
          'Attempts to determine the key length using Index of Coincidence',
      icon: Icons.straighten,
      isDefaultEnabled: true,
    ),
    VigenereCrackingMethod(
      name: 'Known Plaintext',
      description:
          'Uses expected words/patterns that might appear in the plaintext',
      icon: Icons.text_fields,
    ),
    VigenereCrackingMethod(
      name: 'Brute Force (Short Keys)',
      description:
          'Tests all possible combinations of short keys (1-3 characters)',
      icon: Icons.bolt,
    ),
    VigenereCrackingMethod(
      name: 'Smart Key Generation',
      description: 'Generates keys based on patterns and common substitutions',
      icon: Icons.psychology,
    ),
  ];

  // Improved method specifically for short texts (1-2 sentences)
  static Future<List<Map<String, dynamic>>> crackShortText({
    required String ciphertext,
    required List<String> enabledMethods,
    required List<String> dictionary,
    required List<String> savedKeys,
    required Function(String) progressCallback,
    required Function(double) progressValueCallback,
  }) async {
    List<Map<String, dynamic>> results = [];

    // Clean the ciphertext
    final String cleanText = ciphertext.trim();
    if (cleanText.isEmpty) return [];

    double overallProgress = 0.0;
    final int methodCount = enabledMethods.length;
    final double methodWeight = 1.0 / methodCount;

    // Keep track of already tried keys to avoid duplicates
    Set<String> triedKeys = {};

    // First try saved keys regardless of enabled methods
    if (savedKeys.isNotEmpty) {
      progressCallback('Checking saved keys...');

      for (final key in savedKeys) {
        if (!triedKeys.contains(key)) {
          triedKeys.add(key);
          final result = _evaluateKey(cleanText, key);
          if (result != null) {
            results.add(result);
          }
        }
      }

      // Sort initial results
      results.sort((a, b) => b['score'].compareTo(a['score']));
    }

    // Method 1: Dictionary Attack
    if (enabledMethods.contains('Dictionary Attack')) {
      progressCallback('Running dictionary attack...');

      int wordCount = 0;
      final totalWords = dictionary.length;

      for (final word in dictionary) {
        // Update progress
        wordCount++;
        if (wordCount % 10 == 0) {
          progressValueCallback(
              overallProgress + (wordCount / totalWords) * methodWeight);
          progressCallback(
              'Dictionary attack: ${(wordCount * 100 ~/ totalWords)}%');
        }

        if (!triedKeys.contains(word)) {
          triedKeys.add(word);
          final result = _evaluateKey(cleanText, word);
          if (result != null) {
            results.add(result);
          }
        }
      }

      overallProgress += methodWeight;
      progressValueCallback(overallProgress);
    }

    // Method 2: Key Length Analysis (Index of Coincidence)
    if (enabledMethods.contains('Key Length Analysis')) {
      progressCallback('Analyzing possible key lengths...');

      // For short texts, we limit key length search to reasonable sizes
      final int maxKeyLength = min(10, cleanText.length ~/ 2);
      final Map<int, double> keyLengthScores = {};

      // Calculate Index of Coincidence for different key lengths
      for (int keyLength = 1; keyLength <= maxKeyLength; keyLength++) {
        final double ioc = _calculateIndexOfCoincidence(cleanText, keyLength);
        keyLengthScores[keyLength] = ioc;

        progressValueCallback(
            overallProgress + (keyLength / maxKeyLength) * methodWeight * 0.3);
      }

      // Sort key lengths by their IoC score (higher is better)
      final List<int> likelyKeyLengths = keyLengthScores.keys.toList()
        ..sort((a, b) => keyLengthScores[b]!.compareTo(keyLengthScores[a]!));

      // Take top 3 most likely key lengths
      final likelyLengths = likelyKeyLengths.take(3).toList();

      progressCallback(
          'Testing probable key lengths: ${likelyLengths.join(', ')}');

      // For each likely key length, try to determine the key using frequency analysis
      int lengthIndex = 0;
      for (final keyLength in likelyLengths) {
        final String probableKey =
            _determineKeyByFrequency(cleanText, keyLength);

        if (!triedKeys.contains(probableKey)) {
          triedKeys.add(probableKey);
          final result = _evaluateKey(cleanText, probableKey);
          if (result != null) {
            result['method'] = 'Key Length Analysis (IoC)';
            results.add(result);
          }
        }

        // Also try some variations of the probable key
        final List<String> keyVariations = _generateKeyVariations(probableKey);
        for (final variation in keyVariations) {
          if (!triedKeys.contains(variation)) {
            triedKeys.add(variation);
            final result = _evaluateKey(cleanText, variation);
            if (result != null) {
              result['method'] = 'Key Variation';
              results.add(result);
            }
          }
        }

        lengthIndex++;
        progressValueCallback(overallProgress +
            0.3 * methodWeight +
            (lengthIndex / likelyLengths.length) * methodWeight * 0.7);
      }

      overallProgress += methodWeight;
      progressValueCallback(overallProgress);
    }

    // Method 3: Known Plaintext Attack
    if (enabledMethods.contains('Known Plaintext')) {
      progressCallback('Applying known plaintext analysis...');

      // List of common words/phrases that might appear in the text
      final commonPhrases = [
        'the',
        'and',
        'that',
        'have',
        'for',
        'not',
        'with',
        'you',
        'this',
        'but',
        'his',
        'from',
        'they',
        'she',
        'will',
        'would',
        'there',
        'their',
        'what',
        'about',
        'which',
        'when',
        'make',
        'like',
        'time',
        'just',
        'know',
        'people',
        'year',
        'your',
        'good',
        'some',
        'could',
        'them',
        'see',
        'other',
        'than',
        'then',
        'now',
        'look',
        'only',
        'come',
        'its',
        'over',
        'think',
        'also',
        'back',
        'after',
        'use',
        'two',
        'how',
        'first',
        'well',
        'way',
        'even',
        'new',
        'want',
        'because',
        'these',
        'Hello',
        'World',
        'Dear',
        'Please',
        'Thanks',
        'The',
        'This',
        'Here',
        'Today',
        'Tomorrow',
        'Yesterday',
        'We',
        'They',
        'I am',
        'It is',
      ];

      int phraseCount = 0;
      final totalPhrases = commonPhrases.length;

      for (final phrase in commonPhrases) {
        // For each phrase, we try to find it at different positions in the text
        final int maxPosition = min(15, cleanText.length - phrase.length);

        for (int position = 0; position < maxPosition; position++) {
          // Create a "crib" - we assume the phrase appears at this position
          final String potentialKey =
              _deriveKeyFromKnownPlaintext(cleanText, phrase, position);

          if (potentialKey.isNotEmpty && !triedKeys.contains(potentialKey)) {
            triedKeys.add(potentialKey);
            final result = _evaluateKey(cleanText, potentialKey);
            if (result != null) {
              result['method'] = 'Known Plaintext';
              results.add(result);
            }
          }
        }

        phraseCount++;
        progressValueCallback(
            overallProgress + (phraseCount / totalPhrases) * methodWeight);
      }

      overallProgress += methodWeight;
      progressValueCallback(overallProgress);
    }

    // Method 4: Brute Force (for short keys only)
    if (enabledMethods.contains('Brute Force (Short Keys)')) {
      progressCallback('Trying brute force for short keys...');

      // For a short text, we can try all 1 and 2 letter keys, and some 3 letter keys
      List<String> alphabet = 'abcdefghijklmnopqrstuvwxyz'.split('');

      // 1-letter keys
      for (final letter in alphabet) {
        if (!triedKeys.contains(letter)) {
          triedKeys.add(letter);
          final result = _evaluateKey(cleanText, letter);
          if (result != null) {
            result['method'] = 'Brute Force';
            results.add(result);
          }
        }
      }

      progressValueCallback(overallProgress + 0.2 * methodWeight);

      // 2-letter keys
      int count2Letter = 0;
      final total2Letter = alphabet.length * alphabet.length;

      for (final letter1 in alphabet) {
        for (final letter2 in alphabet) {
          final key = letter1 + letter2;

          if (!triedKeys.contains(key)) {
            triedKeys.add(key);
            final result = _evaluateKey(cleanText, key);
            if (result != null) {
              result['method'] = 'Brute Force';
              results.add(result);
            }
          }

          count2Letter++;
          if (count2Letter % 50 == 0) {
            progressValueCallback(overallProgress +
                0.2 * methodWeight +
                (count2Letter / total2Letter) * 0.6 * methodWeight);
          }
        }
      }

      progressValueCallback(overallProgress + 0.8 * methodWeight);

      // 3-letter keys (limited to common prefixes to save time)
      List<String> common3LetterPrefixes = [
        'the',
        'and',
        'for',
        'key',
        'abc',
        'xyz',
        'cat',
        'dog',
        'aaa',
        'bbb',
        'ttt'
      ];

      for (final prefix in common3LetterPrefixes) {
        if (!triedKeys.contains(prefix)) {
          triedKeys.add(prefix);
          final result = _evaluateKey(cleanText, prefix);
          if (result != null) {
            result['method'] = 'Brute Force';
            results.add(result);
          }
        }
      }

      overallProgress += methodWeight;
      progressValueCallback(overallProgress);
    }

    // Method 5: Smart Key Generation
    if (enabledMethods.contains('Smart Key Generation')) {
      progressCallback('Generating smart keys...');

      // Generate keys based on patterns and transformations
      List<String> smartKeys = _generateSmartKeys();

      int smartKeyCount = 0;
      final totalSmartKeys = smartKeys.length;

      for (final key in smartKeys) {
        if (!triedKeys.contains(key)) {
          triedKeys.add(key);
          final result = _evaluateKey(cleanText, key);
          if (result != null) {
            result['method'] = 'Smart Key Generation';
            results.add(result);
          }
        }

        smartKeyCount++;
        if (smartKeyCount % 10 == 0) {
          progressValueCallback(overallProgress +
              (smartKeyCount / totalSmartKeys) * methodWeight);
        }
      }

      overallProgress += methodWeight;
      progressValueCallback(overallProgress);
    }

    // Sort all results by score
    results.sort((a, b) => b['score'].compareTo(a['score']));

    // Take top results (limited to reasonably good ones)
    List<Map<String, dynamic>> finalResults = [];
    for (final result in results) {
      if (result['score'] > 20 || finalResults.length < 5) {
        finalResults.add(result);
      }

      if (finalResults.length >= 10) break;
    }

    progressCallback('Analysis complete');
    progressValueCallback(1.0);

    return finalResults;
  }

  // Helper method to evaluate a potential key
  static Map<String, dynamic>? _evaluateKey(String ciphertext, String key) {
    if (key.isEmpty) return null;

    // Decrypt with this key
    final String decrypted = VigenereUtil.decrypt(ciphertext, key);

    // Calculate readability score
    final double score = _calculateReadabilityScore(decrypted);

    // Only return results with reasonable scores
    if (score > 0.15) {
      return {
        'key': key,
        'decrypted': decrypted,
        'score': score * 100, // Convert to percentage
        'method':
            'Dictionary Attack', // Default method, may be overridden later
      };
    }

    return null;
  }

  // Calculate Index of Coincidence for a given key length
  static double _calculateIndexOfCoincidence(String text, int keyLength) {
    if (text.isEmpty || keyLength <= 0) return 0.0;

    List<String> columns = List.generate(keyLength, (_) => '');

    // Split text into columns based on key length
    for (int i = 0; i < text.length; i++) {
      final int col = i % keyLength;
      if (RegExp(r'[A-Za-z]').hasMatch(text[i])) {
        columns[col] += text[i].toLowerCase();
      }
    }

    // Calculate average IoC across all columns
    double totalIoC = 0.0;
    int validColumns = 0;

    for (final column in columns) {
      if (column.length > 1) {
        // Need at least 2 characters for meaningful IoC
        Map<String, int> freqs = {};

        // Count character frequencies
        for (int i = 0; i < column.length; i++) {
          freqs[column[i]] = (freqs[column[i]] ?? 0) + 1;
        }

        // Calculate IoC for this column
        double sumFreqs = 0.0;
        for (final count in freqs.values) {
          sumFreqs += count * (count - 1);
        }

        double ioc = sumFreqs / (column.length * (column.length - 1));
        totalIoC += ioc;
        validColumns++;
      }
    }

    // English text has an IoC of around 0.067
    // Return average IoC if we have valid columns, otherwise 0
    return validColumns > 0 ? (totalIoC / validColumns) : 0.0;
  }

  // Determine a likely key based on frequency analysis for each position
  static String _determineKeyByFrequency(String ciphertext, int keyLength) {
    if (ciphertext.isEmpty || keyLength <= 0) return '';

    // English letter frequency order (most to least common)
    const String englishFreq = 'etaoinsrhdlucmfywgpbvkxqjz';

    List<String> columns = List.generate(keyLength, (_) => '');

    // Split ciphertext into columns based on key length
    for (int i = 0; i < ciphertext.length; i++) {
      if (RegExp(r'[A-Za-z]').hasMatch(ciphertext[i])) {
        columns[i % keyLength] += ciphertext[i].toLowerCase();
      }
    }

    // Determine the most likely shift for each column
    String key = '';
    for (final column in columns) {
      if (column.isEmpty) {
        key += 'a'; // Default if we don't have data
        continue;
      }

      // Count frequencies
      Map<String, int> freqs = {};
      for (int i = 0; i < column.length; i++) {
        freqs[column[i]] = (freqs[column[i]] ?? 0) + 1;
      }

      // Sort by frequency
      List<MapEntry<String, int>> sortedFreqs = freqs.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Most common char in this column
      String mostCommon = sortedFreqs.first.key;

      // Assume 'e' is the most common letter in English
      // Calculate the shift that would make the most common cipher letter decrypt to 'e'
      int charCode = mostCommon.codeUnitAt(0) - 'a'.codeUnitAt(0);
      int eCode = 'e'.codeUnitAt(0) - 'a'.codeUnitAt(0);
      int shift = (charCode - eCode + 26) % 26;

      // Convert the shift to a key character
      key += String.fromCharCode(shift + 'a'.codeUnitAt(0));
    }

    return key;
  }

  // Generate variations of a key for testing
  static List<String> _generateKeyVariations(String key) {
    if (key.isEmpty) return [];

    List<String> variations = [];

    // Add the original key
    variations.add(key);

    // Add uppercase
    variations.add(key.toUpperCase());

    // Add reverse
    variations.add(key.split('').reversed.join(''));

    // Add common substitutions
    Map<String, String> substitutions = {
      'a': '4',
      'e': '3',
      'i': '1',
      'o': '0',
      's': '5',
      't': '7',
      'l': '1'
    };

    String leetKey = '';
    for (int i = 0; i < key.length; i++) {
      leetKey += substitutions[key[i]] ?? key[i];
    }
    if (leetKey != key) variations.add(leetKey);

    // Double the key if it's short
    if (key.length < 4) variations.add(key + key);

    // Slice the key if it's long
    if (key.length > 3) {
      variations.add(key.substring(0, key.length ~/ 2));
      variations.add(key.substring(key.length ~/ 2));
    }

    return variations;
  }

  // Derive a potential key from assuming a known plaintext at a specific position
  static String _deriveKeyFromKnownPlaintext(
      String ciphertext, String knownText, int position) {
    if (ciphertext.length < position + knownText.length) return '';

    // Extract the portion of ciphertext that would correspond to the known text
    String relevantCipher =
        ciphertext.substring(position, position + knownText.length);

    // Derive the key
    String derivedKey = '';
    for (int i = 0; i < knownText.length; i++) {
      if (!RegExp(r'[A-Za-z]').hasMatch(relevantCipher[i]) ||
          !RegExp(r'[A-Za-z]').hasMatch(knownText[i])) {
        continue;
      }

      int cipherChar =
          relevantCipher[i].toLowerCase().codeUnitAt(0) - 'a'.codeUnitAt(0);
      int plainChar =
          knownText[i].toLowerCase().codeUnitAt(0) - 'a'.codeUnitAt(0);

      // Calculate the key character that would transform plainChar to cipherChar
      int keyChar = (cipherChar - plainChar + 26) % 26;
      derivedKey += String.fromCharCode(keyChar + 'a'.codeUnitAt(0));
    }

    return derivedKey;
  }

  // Generate smart keys based on patterns and common techniques
  static List<String> _generateSmartKeys() {
    List<String> keys = [];

    // Basic patterns
    keys.addAll(['key', 'password', 'secret', 'cipher', 'vigenere', 'crypto']);

    // Adjacent keyboard characters
    keys.addAll(['qwerty', 'asdfgh', 'zxcvbn', 'qazwsx']);

    // Common replacements
    keys.addAll(['p@ssw0rd', 's3cr3t', 'k3y', 'v1g3n3r3']);

    // Repetitions of single/double characters
    for (String c in 'abcdefghijklmnopqrstuvwxyz'.split('')) {
      keys.add(c * 3); // aaa, bbb, etc.
    }

    for (String c1 in 'aeiou'.split('')) {
      for (String c2 in 'bcdfghjklmnpqrstvwxyz'.split('')) {
        keys.add(c1 + c2 + c1 + c2); // abab, acac, etc.
      }
    }

    // Common names
    keys.addAll(['john', 'mary', 'david', 'alice', 'bob', 'charlie']);

    // Calendar-based keys
    keys.addAll([
      'jan',
      'feb',
      'mar',
      'apr',
      'may',
      'jun',
      'jul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec'
    ]);
    keys.addAll(['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun']);

    // Numeric patterns
    keys.addAll(['one', 'two', 'three', 'four', 'five']);
    keys.addAll(['first', 'second', 'third', 'fourth', 'fifth']);

    return keys;
  }

  // Calculate readability score (simplified version of the one in main.dart)
  static double _calculateReadabilityScore(String text) {
    if (text.isEmpty) return 0.0;

    // Common English words
    final commonEnglishWords = {
      'the',
      'and',
      'that',
      'have',
      'for',
      'not',
      'with',
      'you',
      'this',
      'but',
      'his',
      'from',
      'they',
      'say',
      'she',
      'will',
      'one',
      'all',
      'would',
      'there',
      'their',
      'what',
      'out',
      'about',
      'who',
      'get',
      'which',
      'when',
      'make',
      'can',
      'like',
      'time',
      'just',
      'him',
      'know',
      'take',
      'people',
      'into',
      'year',
      'your',
      'good',
      'some',
      'could',
      'them',
      'see',
      'other',
      'than',
      'then',
      'now',
      'look',
      'only',
      'come',
      'its',
      'over',
      'think',
      'also',
      'back',
      'after',
      'use',
      'two',
      'how',
      'our',
      'work',
      'first',
      'well',
      'way',
      'even',
      'new',
      'want',
      'because',
      'any',
      'these',
      'give',
      'day',
      'most',
      'been',
      'very',
      'was',
      'has',
      'had',
      'are',
    };

    // Common English bigrams
    final commonBigrams = [
      'th',
      'he',
      'in',
      'er',
      'an',
      're',
      'on',
      'at',
      'en',
      'nd',
      'ti',
      'es',
      'or',
      'te',
      'of',
      'ed',
      'is',
      'it',
      'al',
      'ar',
      'st',
      'to',
      'nt',
      'ng',
      'se',
      'ha',
      'as',
      'ou',
      'io',
      'le',
      'co',
      'me',
      'de',
      'hi',
      'ri',
      'ro',
    ];

    // Convert text to lowercase for analysis
    final String cleanText = text.toLowerCase();

    // Split the text into words and count how many are in our common words list
    final List<String> words = cleanText
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) return 0.0;

    // Count common words
    int commonWordCount = 0;
    for (final word in words) {
      if (commonEnglishWords.contains(word)) {
        commonWordCount++;
      }
    }

    // Calculate word score
    double wordScore = words.isEmpty ? 0.0 : commonWordCount / words.length;

    // Calculate bigram score
    int bigramMatches = 0;
    int totalBigrams = 0;

    // Check for bigrams
    for (int i = 0; i < cleanText.length - 1; i++) {
      final String bigram = cleanText.substring(i, i + 2);
      if (RegExp(r'^[a-z]{2}$').hasMatch(bigram)) {
        totalBigrams++;
        if (commonBigrams.contains(bigram)) {
          bigramMatches++;
        }
      }
    }

    double bigramScore = totalBigrams > 0 ? bigramMatches / totalBigrams : 0.0;

    // Check for repeated characters (indication of non-meaningful text)
    int repeats = 0;
    for (int i = 0; i < cleanText.length - 3; i++) {
      if (cleanText[i] == cleanText[i + 1] &&
          cleanText[i] == cleanText[i + 2] &&
          cleanText[i] == cleanText[i + 3]) {
        repeats++;
      }
    }
    double repeatPenalty =
        repeats > 0 ? 1.0 - (repeats / cleanText.length).clamp(0.0, 0.5) : 1.0;

    // Calculate space ratio (meaningful text typically has about 1 space per 5-6 characters)
    int spaceCount = text.split(' ').length - 1;
    double spaceRatio = spaceCount / text.length;
    double spaceScore = 1.0 - (spaceRatio - 0.17).abs() / 0.17;
    spaceScore = spaceScore.clamp(0.0, 1.0);

    // Combine all scores with appropriate weights
    final double combinedScore =
        (wordScore * 0.45 + // Common words are strongest indicator
            bigramScore * 0.25 + // Bigram frequency
            spaceScore * 0.10 + // Space distribution
            repeatPenalty * 0.20); // Penalty for repeating characters

    return combinedScore.clamp(0.0, 1.0);
  }
}
