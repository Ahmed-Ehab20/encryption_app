import 'package:flutter/material.dart';
import 'dart:math';
import 'package:collection/collection.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: CipherDetector(),
    );
  }
}

class CipherDetector extends StatefulWidget {
  @override
  _CipherDetectorState createState() => _CipherDetectorState();
}

class _CipherDetectorState extends State<CipherDetector> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  final FocusNode _focusNode = FocusNode();

  final Set<String> _dictionary = {
    'the', 'be', 'to', 'of', 'and', 'a', 'in', 'that', 'have', 'i',
    'it', 'for', 'not', 'on', 'with', 'he', 'as', 'you', 'do', 'at',
    'this', 'but', 'his', 'by', 'from', 'they', 'we', 'say', 'her', 'she',
    'or', 'an', 'will', 'my', 'one', 'all', 'would', 'there', 'their', 'what',
    'so', 'up', 'out', 'if', 'about', 'who', 'get', 'which', 'go', 'me',
    'when', 'make', 'can', 'like', 'time', 'no', 'just', 'him', 'know', 'take',
    'people', 'into', 'year', 'your', 'good', 'some', 'could', 'them', 'see',
    'other', 'than', 'then', 'now', 'look', 'only', 'come', 'its', 'over',
    'think', 'also', 'back', 'after', 'use', 'two', 'how', 'our', 'work',
    'first', 'well', 'way', 'even', 'new', 'want', 'because', 'any', 'these',
    'give', 'day', 'most', 'us', 'is', 'are', 'was', 'were', 'hello', 'world'
  };

  final Map<String, double> _englishFrequencies = {
    'a': 0.08167, 'b': 0.01492, 'c': 0.02782, 'd': 0.04258,
    'e': 0.12702, 'f': 0.02228, 'g': 0.02015, 'h': 0.06094,
    'i': 0.06966, 'j': 0.00153, 'k': 0.00772, 'l': 0.04025,
    'm': 0.02406, 'n': 0.06749, 'o': 0.07507, 'p': 0.01929,
    'q': 0.00095, 'r': 0.05987, 's': 0.06327, 't': 0.09056,
    'u': 0.02758, 'v': 0.00978, 'w': 0.02360, 'x': 0.00150,
    'y': 0.01974, 'z': 0.00074,
  };

  double _calculateValidity(String text) {
    List<String> words = text.toLowerCase().split(RegExp(r'\W+'));
    if (words.isEmpty) return 0.0;
    
    int validCount = 0;
    for (String word in words) {
      if (_dictionary.contains(word)) {
        validCount++;
      }
    }
    return validCount / words.length;
  }

  String _caesarDecrypt(String ciphertext, int shift) {
    return ciphertext.split('').map((char) {
      if (RegExp(r'[A-Za-z]').hasMatch(char)) {
        int base = char.codeUnitAt(0) <= 90 ? 65 : 97;
        return String.fromCharCode(
            (char.codeUnitAt(0) - base - shift + 26) % 26 + base);
      }
      return char;
    }).join('');
  }

  List<Map<String, dynamic>> _detectCaesar(String ciphertext) {
    List<Map<String, dynamic>> candidates = [];
    for (int shift = 0; shift < 26; shift++) {
      String decrypted = _caesarDecrypt(ciphertext, shift);
      double score = _calculateValidity(decrypted);
      if (score > 0.2) {
        candidates.add({
          'type': 'Caesar',
          'key': shift,
          'decrypted': decrypted,
          'score': score
        });
      }
    }
    candidates.sort((a, b) => b['score'].compareTo(a['score']));
    return candidates.take(3).toList();
  }

  String _railFenceDecrypt(String ciphertext, int rails) {
    List<List<String>> matrix = List.generate(rails, (_) => []);
    int n = ciphertext.length;
    List<int> rowLengths = List.filled(rails, 0);
    int idx = 0;
    int direction = 1;

    for (int i = 0; i < n; i++) {
      rowLengths[idx]++;
      idx += direction;
      if (idx >= rails) {
        idx = rails - 2;
        direction = -1;
      } else if (idx < 0) {
        idx = 1;
        direction = 1;
      }
    }

    int curr = 0;
    for (int i = 0; i < rails; i++) {
      for (int j = 0; j < rowLengths[i]; j++) {
        if (curr < n) {
          matrix[i].add(ciphertext[curr++]);
        }
      }
    }

    List<String> result = [];
    idx = 0;
    direction = 1;
    List<int> rowIndices = List.generate(rails, (i) => 0);

    for (int i = 0; i < n; i++) {
      result.add(matrix[idx][rowIndices[idx]++]);
      idx += direction;
      if (idx >= rails) {
        idx = rails - 2;
        direction = -1;
      } else if (idx < 0) {
        idx = 1;
        direction = 1;
      }
    }

    return result.join('');
  }

  List<Map<String, dynamic>> _detectRailFence(String ciphertext) {
    List<Map<String, dynamic>> candidates = [];
    int maxRails = min(ciphertext.length, 20);

    for (int rails = 2; rails <= maxRails; rails++) {
      try {
        String decrypted = _railFenceDecrypt(ciphertext, rails);
        double score = _calculateValidity(decrypted);
        if (score > 0.2) {
          candidates.add({
            'type': 'Rail Fence',
            'key': rails,
            'decrypted': decrypted,
            'score': score
          });
        }
      } catch (e) {
        continue;
      }
    }
    candidates.sort((a, b) => b['score'].compareTo(a['score']));
    return candidates.take(3).toList();
  }

  double _computeFrequencyScore(String text) {
    text = text.toLowerCase();
    Map<String, int> counts = {};
    int total = 0;

    for (int i = 0; i < text.length; i++) {
      String char = text[i];
      if (_englishFrequencies.containsKey(char)) {
        counts[char] = (counts[char] ?? 0) + 1;
        total++;
      }
    }

    if (total == 0) return 0.0;
    
    double score = 0.0;
    counts.forEach((char, count) {
      double expected = _englishFrequencies[char]!;
      double actual = count / total;
      score += 1.0 - (expected - actual).abs();
    });

    return score / counts.length;
  }

  String _vigenereDecrypt(String ciphertext, String key) {
    key = key.toLowerCase();
    StringBuffer decrypted = StringBuffer();
    int keyIndex = 0;

    for (int i = 0; i < ciphertext.length; i++) {
      String char = ciphertext[i];
      if (RegExp(r'[A-Za-z]').hasMatch(char)) {
        int base = char.codeUnitAt(0) <= 90 ? 65 : 97;
        int keyChar = key.codeUnitAt(keyIndex % key.length) - 97;
        int shifted = (char.codeUnitAt(0) - base - keyChar + 26) % 26 + base;
        decrypted.writeCharCode(shifted);
        keyIndex++;
      } else {
        decrypted.write(char);
      }
    }
    return decrypted.toString();
  }

  List<int> _factors(int n) {
    List<int> factors = [];
    for (int i = 2; i <= sqrt(n); i++) {
      if (n % i == 0) {
        factors.add(i);
        if (i != n ~/ i) factors.add(n ~/ i);
      }
    }
    return factors..sort();
  }

  String _guessVigenereKey(String ciphertext, int keyLength) {
    String lettersOnly = ciphertext.replaceAll(RegExp(r'[^A-Za-z]'), '').toLowerCase();
    List<List<String>> subgroups = List.generate(keyLength, (index) => []);

    for (int i = 0; i < lettersOnly.length; i++) {
      subgroups[i % keyLength].add(lettersOnly[i]);
    }

    StringBuffer key = StringBuffer();
    for (int k = 0; k < keyLength; k++) {
      List<String> subgroup = subgroups[k];
      if (subgroup.isEmpty) {
        key.write('a');
        continue;
      }

      Map<int, double> shiftScores = {};
      for (int shift = 0; shift < 26; shift++) {
        String decrypted = _caesarDecrypt(subgroup.join(), shift);
        double freqScore = _computeFrequencyScore(decrypted);
        double dictScore = _calculateValidity(decrypted);
        shiftScores[shift] = (freqScore * 0.7) + (dictScore * 0.3);
      }

      int bestShift = shiftScores.entries
        .sorted((a, b) => b.value.compareTo(a.value))
        .first.key;

      key.write(String.fromCharCode('a'.codeUnitAt(0) + bestShift));
    }
    
    return key.toString();
  }

  List<Map<String, dynamic>> _detectVigenere(String ciphertext) {
    List<Map<String, dynamic>> candidates = [];
    String lettersOnly = ciphertext.replaceAll(RegExp(r'[^A-Za-z]'), '').toLowerCase();
    if (lettersOnly.length < 8) return candidates;

    List<String> commonKeys = ['the', 'and', 'that', 'have', 'with', 'this', 'your', 'they', 'which'];
    for (String key in commonKeys) {
      String decrypted = _vigenereDecrypt(ciphertext, key);
      double score = (_computeFrequencyScore(decrypted) * 0.6) + (_calculateValidity(decrypted) * 0.4);
      if (score > 0.25) {
        candidates.add({
          'type': 'Vigenère',
          'key': key,
          'decrypted': decrypted,
          'score': score
        });
      }
    }

    Map<int, int> keyLengthScores = {};
    Map<String, List<int>> sequences = {};

    for (int i = 0; i < lettersOnly.length - 2; i++) {
      String seq = lettersOnly.substring(i, i + 3);
      sequences.putIfAbsent(seq, () => []).add(i);
    }

    sequences.forEach((seq, positions) {
      if (positions.length > 1) {
        for (int i = 1; i < positions.length; i++) {
          int distance = positions[i] - positions[i-1];
          for (int factor in _factors(distance)) {
            if (factor > 1 && factor <= 15) {
              keyLengthScores[factor] = (keyLengthScores[factor] ?? 0) + 1;
            }
          }
        }
      }
    });

    List<int> probableKeyLengths = keyLengthScores.entries
      .sorted((a, b) => b.value.compareTo(a.value))
      .map((e) => e.key)
      .take(3)
      .toList();

    if (probableKeyLengths.isEmpty) {
      probableKeyLengths = [3, 4, 5, 6];
    }

    for (int keyLength in probableKeyLengths) {
      String key = _guessVigenereKey(lettersOnly, keyLength);
      String decrypted = _vigenereDecrypt(ciphertext, key);
      double score = (_computeFrequencyScore(decrypted) * 0.6) + (_calculateValidity(decrypted) * 0.4);
      
      if (score > 0.25) {
        candidates.add({
          'type': 'Vigenère',
          'key': key,
          'decrypted': decrypted,
          'score': score
        });
      }
    }

    candidates.sort((a, b) => b['score'].compareTo(a['score']));
    return candidates.take(3).toList();
  }

  void _analyze() {
    String ciphertext = _controller.text;
    if (ciphertext.isEmpty) return;

    List<Map<String, dynamic>> results = [];
    
    results.addAll(_detectCaesar(ciphertext));
    results.addAll(_detectRailFence(ciphertext));
    results.addAll(_detectVigenere(ciphertext));

    // Filter results if Caesar/Rail Fence are detected
    final hasClassicCipher = results.any((r) => 
        r['type'] == 'Caesar' || r['type'] == 'Rail Fence');
        
    if (hasClassicCipher) {
      results = results.where((r) => 
          r['type'] == 'Caesar' || r['type'] == 'Rail Fence').toList();
    }

    results.sort((a, b) => b['score'].compareTo(a['score']));
    setState(() => _results = results.take(5).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 30),
            _buildInputSection(),
            SizedBox(height: 20),
            _buildAnalyzeButton(),
            SizedBox(height: 30),
            if (_results.isNotEmpty) _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cypher',
            style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        SizedBox(height: 10),
        Text('CRYPTO ANALYSIS: QUANTUM DECRYPTION',
            style: TextStyle(
                color: Colors.blueAccent[200],
                fontSize: 16,
                fontWeight: FontWeight.w300)),
      ],
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: TextStyle(color: Colors.white70),
        maxLines: 3,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Enter encrypted text...',
          hintStyle: TextStyle(color: Colors.white54),
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _analyze,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.blueAccent,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.blueAccent),
          ),
        ),
        child: Text('INITIATE DECRYPTION SEQUENCE',
            style: TextStyle(letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildResultSection() {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('TOP DECRYPTION RESULTS'),
          SizedBox(height: 15),
          ..._results.map((result) => _buildResultCard(result)).toList(),
        ],
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultItem('Cipher Type:', result['type']),
          _buildResultItem('Encryption Key:', result['key'].toString()),
          SizedBox(height: 10),
          _buildSectionTitle('CLEARTEXT OUTPUT'),
          SizedBox(height: 10),
          Text(result['decrypted'],
              style: TextStyle(
                  color: Colors.blueAccent[200],
                  fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(text,
        style: TextStyle(
            color: Colors.blueAccent[200],
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2));
  }

  Widget _buildResultItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            margin: EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle),
          ),
          Text(label,
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12)),
          SizedBox(width: 10),
          Text(value,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}