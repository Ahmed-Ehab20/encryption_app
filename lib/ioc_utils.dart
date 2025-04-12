/// Utility functions for calculating Index of Coincidence (IoC) and performing
/// frequency analysis for cryptanalysis, particularly for Vigenère ciphers.

/// Calculates the Index of Coincidence for a given text.
///
/// The Index of Coincidence (IoC) measures the probability that two randomly
/// selected letters from a text are the same. It's useful for distinguishing
/// between natural language text and random text, and for determining the
/// key length of polyalphabetic ciphers like Vigenère.
///
/// Returns a value typically between 0.03 and 0.08, where:
/// - English text: ~0.067
/// - Random text: ~0.038
double calculateIndexOfCoincidence(String text) {
  // Clean the text - keep only letters
  String cleanText = '';
  for (int i = 0; i < text.length; i++) {
    if (RegExp(r'[A-Za-z]').hasMatch(text[i])) {
      cleanText += text[i].toLowerCase();
    }
  }

  if (cleanText.length < 2) {
    return 0.0; // Not enough text to calculate
  }

  // Count letter frequencies
  Map<String, int> freqCount = {};
  for (int i = 0; i < cleanText.length; i++) {
    freqCount[cleanText[i]] = (freqCount[cleanText[i]] ?? 0) + 1;
  }

  // Calculate IoC
  double ioc = 0.0;
  int sum = cleanText.length;

  for (int count in freqCount.values) {
    ioc += count * (count - 1);
  }

  return ioc / (sum * (sum - 1));
}

/// Calculates the average Index of Coincidence when text is split into columns.
///
/// This is useful for estimating the key length in Vigenère ciphers.
/// When the text is split into the correct number of columns (matching the key length),
/// each column will have a higher IoC closer to natural language.
///
/// Returns a map of potential key lengths and their associated IoC scores.
Map<int, double> calculateIoCForKeyLengths(String text,
    {int maxKeyLength = 20}) {
  // Clean the text - keep only letters
  String cleanText = '';
  for (int i = 0; i < text.length; i++) {
    if (RegExp(r'[A-Za-z]').hasMatch(text[i])) {
      cleanText += text[i].toLowerCase();
    }
  }

  if (cleanText.length < 20) {
    return {}; // Not enough text for reliable analysis
  }

  // Try different key lengths and measure Index of Coincidence
  Map<int, double> iocScores = {};

  for (int length = 1; length <= maxKeyLength; length++) {
    double avgIoC = 0.0;

    // Split text into columns
    List<String> columns = List.generate(length, (i) => '');
    for (int i = 0; i < cleanText.length; i++) {
      columns[i % length] += cleanText[i];
    }

    // Calculate IoC for each column
    int validColumns = 0;
    for (String col in columns) {
      if (col.length < 2) continue;

      final colIoC = calculateIndexOfCoincidence(col);
      if (colIoC > 0) {
        avgIoC += colIoC;
        validColumns++;
      }
    }

    if (validColumns > 0) {
      avgIoC /= validColumns;
      iocScores[length] = avgIoC;
    }
  }

  return iocScores;
}

/// Estimates the most likely key length for a Vigenère cipher using IoC analysis.
///
/// Returns the estimated key length, or -1 if no reliable estimate could be made.
Future<int> estimateKeyLength(String cipherText,
    {double threshold = 0.055}) async {
  final iocScores = calculateIoCForKeyLengths(cipherText);

  // Find the key length with highest IoC
  double highestIoC = 0.0;
  int bestLength = 0;

  for (final entry in iocScores.entries) {
    if (entry.value > highestIoC) {
      highestIoC = entry.value;
      bestLength = entry.key;
    }
  }

  // Only return if the IoC is reasonable for English-like text
  return (highestIoC > threshold) ? bestLength : -1;
}

/// A data class to hold frequency analysis results for a column of text
class ColumnFrequencyAnalysis {
  final int columnIndex;
  final Map<String, int> frequencies;
  final List<MapEntry<String, int>> sortedFrequencies;
  final String mostCommonLetter;
  final int totalChars;
  final double indexOfCoincidence;

  ColumnFrequencyAnalysis({
    required this.columnIndex,
    required this.frequencies,
    required this.sortedFrequencies,
    required this.mostCommonLetter,
    required this.totalChars,
    required this.indexOfCoincidence,
  });

  /// Creates a frequency analysis for a given column of text
  factory ColumnFrequencyAnalysis.fromText(String text, int columnIndex) {
    // Count letter frequencies
    Map<String, int> freqCount = {};
    for (int i = 0; i < text.length; i++) {
      if (RegExp(r'[A-Za-z]').hasMatch(text[i])) {
        final char = text[i].toLowerCase();
        freqCount[char] = (freqCount[char] ?? 0) + 1;
      }
    }

    // Sort by frequency (descending)
    List<MapEntry<String, int>> sortedFreq = freqCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    String mostCommon = sortedFreq.isNotEmpty ? sortedFreq.first.key : '';

    return ColumnFrequencyAnalysis(
      columnIndex: columnIndex,
      frequencies: freqCount,
      sortedFrequencies: sortedFreq,
      mostCommonLetter: mostCommon,
      totalChars: text.length,
      indexOfCoincidence: calculateIndexOfCoincidence(text),
    );
  }
}

/// Analyzes the frequency of each column when text is split by key length.
///
/// This is useful for determining the individual letters of a Vigenère key
/// once the key length is known.
List<ColumnFrequencyAnalysis> analyzeFrequencyByKeyLength(
    String text, int keyLength) {
  // Clean the text - keep only letters
  String cleanText = '';
  for (int i = 0; i < text.length; i++) {
    if (RegExp(r'[A-Za-z]').hasMatch(text[i])) {
      cleanText += text[i].toLowerCase();
    }
  }

  // Split text into columns
  List<String> columns = List.generate(keyLength, (i) => '');
  for (int i = 0; i < cleanText.length; i++) {
    columns[i % keyLength] += cleanText[i];
  }

  // Analyze each column
  List<ColumnFrequencyAnalysis> results = [];
  for (int i = 0; i < columns.length; i++) {
    results.add(ColumnFrequencyAnalysis.fromText(columns[i], i));
  }

  return results;
}

/// Generates a potential key for a Vigenère cipher based on frequency analysis.
///
/// This assumes that the most common letter in each column maps to 'e', the most
/// common letter in English. This is a simplified approach and may not work for
/// all ciphertexts.
String generateKeyFromFrequencyAnalysis(String cipherText, int keyLength) {
  final columns = analyzeFrequencyByKeyLength(cipherText, keyLength);

  String key = '';
  for (var col in columns) {
    if (col.sortedFrequencies.isEmpty) {
      key += 'a'; // Default if no data
      continue;
    }

    // Assume most common letter maps to 'e'
    String mostCommon = col.mostCommonLetter;
    int mostCommonCode = mostCommon.codeUnitAt(0);
    int eCode = 'e'.codeUnitAt(0);

    // Calculate the shift that would map 'e' to the most common letter
    int shift = (mostCommonCode - eCode + 26) % 26;

    // The key letter is the one that would cause this shift
    key += String.fromCharCode('a'.codeUnitAt(0) + shift);
  }

  return key;
}

/// Standard letter frequencies in English text
final Map<String, double> englishLetterFrequencies = {
  'e': 0.1202,
  't': 0.0910,
  'a': 0.0812,
  'o': 0.0768,
  'i': 0.0731,
  'n': 0.0695,
  's': 0.0628,
  'r': 0.0602,
  'h': 0.0592,
  'd': 0.0432,
  'l': 0.0398,
  'u': 0.0288,
  'c': 0.0271,
  'm': 0.0261,
  'f': 0.0230,
  'y': 0.0211,
  'w': 0.0209,
  'g': 0.0203,
  'p': 0.0182,
  'b': 0.0149,
  'v': 0.0111,
  'k': 0.0069,
  'x': 0.0017,
  'q': 0.0011,
  'j': 0.0010,
  'z': 0.0007
};
