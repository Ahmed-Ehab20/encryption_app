import 'package:flutter/material.dart';
import 'dart:math';

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
  Map<String, dynamic>? _result;
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

  Map<String, dynamic>? _detectCaesar(String ciphertext) {
    Map<String, dynamic>? bestResult;
    double bestScore = 0.0;

    for (int shift = 0; shift < 26; shift++) {
      String decrypted = _caesarDecrypt(ciphertext, shift);
      double score = _calculateValidity(decrypted);
      
      if (score > bestScore) {
        bestScore = score;
        bestResult = {
          'type': 'Caesar',
          'key': shift,
          'decrypted': decrypted,
          'score': score
        };
      }
    }
    return (bestResult?['score'] ?? 0) > 0.3 ? bestResult : null;
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

  Map<String, dynamic>? _detectRailFence(String ciphertext) {
    Map<String, dynamic>? bestResult;
    double bestScore = 0.0;
    int maxRails = min(ciphertext.length, 20);

    for (int rails = 2; rails <= maxRails; rails++) {
      try {
        String decrypted = _railFenceDecrypt(ciphertext, rails);
        double score = _calculateValidity(decrypted);
        
        if (score > bestScore) {
          bestScore = score;
          bestResult = {
            'type': 'Rail Fence',
            'key': rails,
            'decrypted': decrypted,
            'score': score
          };
        }
      } catch (e) {
        continue;
      }
    }
    return (bestResult?['score'] ?? 0) > 0.3 ? bestResult : null;
  }

  void _analyze() {
    String ciphertext = _controller.text;
    if (ciphertext.isEmpty) return;

    List<Map<String, dynamic>> results = [];
    
    Map<String, dynamic>? caesar = _detectCaesar(ciphertext);
    if (caesar != null) results.add(caesar);
    
    Map<String, dynamic>? railFence = _detectRailFence(ciphertext);
    if (railFence != null) results.add(railFence);

    if (results.isNotEmpty) {
      results.sort((a, b) => b['score'].compareTo(a['score']));
      setState(() => _result = results.first);
    } else {
      setState(() => _result = {'type': 'Unknown', 'key': 'N/A', 'decrypted': ''});
    }
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
            if (_result != null) _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('querda',
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
          _buildSectionTitle('DECRYPTION RESULTS'),
          SizedBox(height: 15),
          _buildResultItem('Cipher Type:', _result!['type']),
          _buildResultItem('Encryption Key:', _result!['key'].toString()),
          SizedBox(height: 10),
          _buildSectionTitle('CLEARTEXT OUTPUT'),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(_result!['decrypted'],
                style: TextStyle(
                    color: Colors.blueAccent[200],
                    fontSize: 14)),
          ),
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