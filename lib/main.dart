import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cipher App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CipherScreen(),
    );
  }
}

class CipherScreen extends StatefulWidget {
  @override
  _CipherScreenState createState() => _CipherScreenState();
}

class _CipherScreenState extends State<CipherScreen> {
  final TextEditingController _textController = TextEditingController();
  String _resultText = '';
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cipher App'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'Encrypted Text',
              ),
            ),
            ElevatedButton(
              onPressed: _handleBreak,
              child: Text('Break Cipher'),
            ),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 20),
            Text('Result: $_resultText'),
          ],
        ),
      ),
    );
  }

  void _handleBreak() {
    String text = _textController.text;
    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter encrypted text';
      });
      return;
    }

    String detectedCipher = '';
    String key = '';
    String decryptedText = '';

    for (int k = 1; k <= 25; k++) {
      String attempt = caesar(text, k * -1);
      if (isEnglish(attempt)) {
        detectedCipher = 'Caesar';
        key = k.toString();
        decryptedText = attempt;
        break;
      }
    }

    for (int k = 2; k <= 25 && detectedCipher.isEmpty; k++) {
      String attempt = railFence(text, k, false);
      if (isEnglish(attempt)) {
        detectedCipher = 'Rail Fence';
        key = k.toString();
        decryptedText = attempt;
        break;
      }
    }

    List<String> commonKeys = ['KEY', 'SECRET', 'HELLO', 'WORLD', 'FLUTTER'];
    for (String k in commonKeys) {
      String attempt = vigenere(text, k, false);
      if (isEnglish(attempt)) {
        detectedCipher = 'Vigenère';
        key = k;
        decryptedText = attempt;
        break;
      }
    }

    setState(() {
      _resultText = detectedCipher.isNotEmpty
          ? 'Detected Cipher: $detectedCipher\nKey: $key\nDecrypted Text: $decryptedText'
          : 'Could not detect cipher';
      _errorMessage = detectedCipher.isEmpty ? 'Could not detect cipher' : '';
    });
  }

  String caesar(String text, int key) {
    StringBuffer result = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      int char = text.codeUnitAt(i);
      if (char >= 65 && char <= 90) {
        int base = 65;
        int offset = (char - base + key) % 26;
        if (offset < 0) offset += 26;
        result.writeCharCode(base + offset);
      } else if (char >= 97 && char <= 122) {
        int base = 97;
        int offset = (char - base + key) % 26;
        if (offset < 0) offset += 26;
        result.writeCharCode(base + offset);
      } else {
        result.write(text[i]);
      }
    }
    return result.toString();
  }

  String railFence(String text, int rails, bool encrypt) {
    if (rails < 2) return text;
    List<List<String>> fence = List.generate(rails, (_) => []);
    int rail = 0;
    bool down = true;

    for (int i = 0; i < text.length; i++) {
      fence[rail].add(text[i]);
      if (rail == rails - 1) {
        down = false;
      } else if (rail == 0) {
        down = true;
      }
      rail += down ? 1 : -1;
    }

    return fence.expand((row) => row).join();
  }

  String vigenere(String text, String key, bool encrypt) {
    StringBuffer result = StringBuffer();
    int keyIndex = 0;
    key = key.toUpperCase();
    
    for (int i = 0; i < text.length; i++) {
      int char = text.codeUnitAt(i);
      if (char >= 65 && char <= 90) {
        int keyShift = key.codeUnitAt(keyIndex % key.length) - 65;
        int newChar = encrypt ? (char + keyShift - 65) % 26 + 65 : (char - keyShift - 65 + 26) % 26 + 65;
        result.writeCharCode(newChar);
        keyIndex++;
      } else if (char >= 97 && char <= 122) {
        int keyShift = key.codeUnitAt(keyIndex % key.length) - 65;
        int newChar = encrypt ? (char + keyShift - 97) % 26 + 97 : (char - keyShift - 97 + 26) % 26 + 97;
        result.writeCharCode(newChar);
        keyIndex++;
      } else {
        result.write(text[i]);
      }
    }
    return result.toString();
  }

  bool isEnglish(String text) {
    List<String> commonWords = ['the', 'and', 'you', 'that', 'was', 'for', 'with', 'hello', 'world', 'example'];
    return commonWords.any((word) => text.toLowerCase().contains(word));
  }
}