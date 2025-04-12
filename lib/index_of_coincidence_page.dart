import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ioc_utils.dart';
import 'index_of_coincidence_visualizer.dart';

/// A standalone page that demonstrates the Index of Coincidence method for
/// cryptanalysis of Vigenère and other polyalphabetic ciphers.
class IndexOfCoincidencePage extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const IndexOfCoincidencePage({Key? key, this.onBackPressed})
      : super(key: key);

  @override
  State<IndexOfCoincidencePage> createState() => _IndexOfCoincidencePageState();
}

class _IndexOfCoincidencePageState extends State<IndexOfCoincidencePage> {
  final TextEditingController _cipherTextController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _plainTextController = TextEditingController();

  bool _isAnalyzing = false;
  bool _showVisualizer = false;
  int _estimatedKeyLength = 0;
  String _generatedKey = '';
  double _averageIoC = 0.0;

  String _cipherTextType = 'Vigenère';
  String _status = '';

  @override
  void initState() {
    super.initState();

    // Initialize with a sample ciphertext for demonstration
    _cipherTextController.text = '''
      PPQCA XQVEKG YBNKMAZU YBNGBAL JON I TSZM JYIM. VRAG VOHT VRAU C TKSG. 
      DDWUO XITLAZU VAVV RAZ C VKB QP IWPOU.
    ''';
  }

  @override
  void dispose() {
    _cipherTextController.dispose();
    _keyController.dispose();
    _plainTextController.dispose();
    super.dispose();
  }

  Future<void> _analyzeText() async {
    if (_cipherTextController.text.isEmpty) {
      setState(() {
        _status = 'Please enter some ciphertext to analyze';
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _status = 'Analyzing text...';
    });

    try {
      // Calculate IoC for the entire text
      double ioc = calculateIndexOfCoincidence(_cipherTextController.text);

      // Calculate key length
      int keyLength = await estimateKeyLength(_cipherTextController.text);

      // Generate a potential key
      String key = '';
      if (keyLength > 0) {
        key = generateKeyFromFrequencyAnalysis(
            _cipherTextController.text, keyLength);
      }

      // Update state with results
      setState(() {
        _estimatedKeyLength = keyLength;
        _generatedKey = key;
        _averageIoC = ioc;

        if (ioc < 0.045) {
          _status =
              'Text appears to be random or heavily encrypted. IoC: ${ioc.toStringAsFixed(4)}';
        } else if (ioc > 0.065) {
          _status =
              'Text shows natural language patterns. IoC: ${ioc.toStringAsFixed(4)}';
        } else {
          _status =
              'Text may be encrypted with a simple cipher. IoC: ${ioc.toStringAsFixed(4)}';
        }

        if (keyLength > 0) {
          _keyController.text = key;
          _status += ' Estimated key length: $keyLength';
        } else {
          _status += ' Could not determine key length.';
        }
      });
    } catch (e) {
      setState(() {
        _status = 'Error during analysis: $e';
      });
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  void _toggleVisualizer() {
    setState(() {
      _showVisualizer = !_showVisualizer;
    });
  }

  void _onKeyLengthSelected(int keyLength) {
    setState(() {
      _estimatedKeyLength = keyLength;
      _showVisualizer = false;

      // Generate a new key based on the selected key length
      if (keyLength > 0) {
        _generatedKey = generateKeyFromFrequencyAnalysis(
            _cipherTextController.text, keyLength);
        _keyController.text = _generatedKey;
        _status = 'Key length updated to: $keyLength';
      }
    });
  }

  String _decryptVigenere(String cipherText, String key) {
    if (key.isEmpty) return cipherText;

    String cleanKey = '';
    for (int i = 0; i < key.length; i++) {
      if (RegExp(r'[A-Za-z]').hasMatch(key[i])) {
        cleanKey += key[i].toLowerCase();
      }
    }

    if (cleanKey.isEmpty) return cipherText;

    String plainText = '';
    int keyIndex = 0;

    for (int i = 0; i < cipherText.length; i++) {
      if (RegExp(r'[A-Za-z]').hasMatch(cipherText[i])) {
        // Get the shift amount from the key
        int shift = cleanKey[keyIndex % cleanKey.length].codeUnitAt(0) -
            'a'.codeUnitAt(0);

        // Apply the reverse shift
        int charCode = cipherText[i].codeUnitAt(0);
        if (charCode >= 'a'.codeUnitAt(0) && charCode <= 'z'.codeUnitAt(0)) {
          charCode = ((charCode - 'a'.codeUnitAt(0) - shift + 26) % 26) +
              'a'.codeUnitAt(0);
        } else if (charCode >= 'A'.codeUnitAt(0) &&
            charCode <= 'Z'.codeUnitAt(0)) {
          charCode = ((charCode - 'A'.codeUnitAt(0) - shift + 26) % 26) +
              'A'.codeUnitAt(0);
        }

        plainText += String.fromCharCode(charCode);
        keyIndex++;
      } else {
        // Keep non-alphabetic characters as is
        plainText += cipherText[i];
      }
    }

    return plainText;
  }

  void _tryDecrypt() {
    if (_cipherTextController.text.isEmpty || _keyController.text.isEmpty) {
      setState(() {
        _status = 'Please enter both ciphertext and key';
      });
      return;
    }

    try {
      final String plainText =
          _decryptVigenere(_cipherTextController.text, _keyController.text);

      setState(() {
        _plainTextController.text = plainText;

        // Calculate IoC of the plaintext to check if it looks like natural language
        double ioc = calculateIndexOfCoincidence(plainText);

        if (ioc > 0.065) {
          _status =
              'Decryption successful! Plaintext has a natural language pattern (IoC: ${ioc.toStringAsFixed(4)})';
        } else if (ioc > 0.055) {
          _status =
              'Decryption may be partially successful (IoC: ${ioc.toStringAsFixed(4)})';
        } else {
          _status =
              'Decryption may not be correct. Low readability score (IoC: ${ioc.toStringAsFixed(4)})';
        }
      });
    } catch (e) {
      setState(() {
        _status = 'Error during decryption: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (_showVisualizer) {
      return IndexOfCoincidenceVisualizer(
        cipherText: _cipherTextController.text,
        onBackPressed: _toggleVisualizer,
        onKeyLengthSelected: _onKeyLengthSelected,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Index of Coincidence Analysis'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: widget.onBackPressed,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            tooltip: 'Learn about IoC',
            onPressed: () {
              _showInfoDialog(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(isDark),
            SizedBox(height: 16),
            _buildInputSection(isDark),
            SizedBox(height: 16),
            _buildAnalysisSection(isDark),
            SizedBox(height: 16),
            _buildResultsSection(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Index of Coincidence (IoC) Analyzer',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'The Index of Coincidence (IoC) is a powerful tool for analyzing encrypted text, '
              'particularly useful for breaking Vigenère ciphers. It can help determine the '
              'key length and then derive the key itself.',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.amber,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'A sample encrypted text is provided. Try analyzing it to see how the IoC method works!',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(bool isDark) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Input',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _cipherTextType,
              decoration: InputDecoration(
                labelText: 'Cipher Type',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              items: ['Vigenère', 'Beaufort', 'Autokey'].map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text(method),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _cipherTextType = value;
                  });
                }
              },
            ),
            SizedBox(height: 16),
            TextField(
              controller: _cipherTextController,
              decoration: InputDecoration(
                labelText: 'Encrypted Text',
                border: OutlineInputBorder(),
                helperText: 'Enter the ciphertext you want to analyze',
                suffixIcon: IconButton(
                  icon: Icon(Icons.paste),
                  tooltip: 'Paste from clipboard',
                  onPressed: () async {
                    final clipboardData =
                        await Clipboard.getData(Clipboard.kTextPlain);
                    if (clipboardData?.text != null) {
                      setState(() {
                        _cipherTextController.text = clipboardData!.text!;
                      });
                    }
                  },
                ),
              ),
              maxLines: 5,
              onChanged: (text) {
                // Clear results when input changes
                setState(() {
                  _estimatedKeyLength = 0;
                  _generatedKey = '';
                  _plainTextController.text = '';
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisSection(bool isDark) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analysis',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon:
                        Icon(_isAnalyzing ? Icons.hourglass_top : Icons.search),
                    label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze Text'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _isAnalyzing ? null : _analyzeText,
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: Icon(Icons.bar_chart),
                  label: Text('Visualize'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _cipherTextController.text.isNotEmpty
                      ? _toggleVisualizer
                      : null,
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.blueGrey.shade800 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status.isEmpty
                    ? 'Status: Ready to analyze'
                    : 'Status: $_status',
                style: TextStyle(
                  color: isDark ? Colors.blue.shade300 : Colors.blue.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection(bool isDark) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Decryption',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _keyController,
              decoration: InputDecoration(
                labelText: 'Key',
                border: OutlineInputBorder(),
                helperText: 'Enter or use the generated key',
                prefixIcon: Icon(Icons.vpn_key),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.lock_open),
                label: Text('Decrypt'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: (_keyController.text.isNotEmpty &&
                        _cipherTextController.text.isNotEmpty)
                    ? _tryDecrypt
                    : null,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _plainTextController,
              decoration: InputDecoration(
                labelText: 'Decrypted Text',
                border: OutlineInputBorder(),
                helperText: 'Result will appear here',
                suffixIcon: IconButton(
                  icon: Icon(Icons.copy),
                  tooltip: 'Copy to clipboard',
                  onPressed: _plainTextController.text.isNotEmpty
                      ? () {
                          Clipboard.setData(
                            ClipboardData(text: _plainTextController.text),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Copied to clipboard'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      : null,
                ),
              ),
              maxLines: 5,
              readOnly: true,
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About the Index of Coincidence'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'What is the Index of Coincidence?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'The Index of Coincidence (IoC) measures the probability that two randomly '
                'selected letters from a text are the same. It\'s calculated by counting '
                'repeated letters and dividing by the total possible pairs.',
              ),
              SizedBox(height: 16),
              Text(
                'IoC Values by Language:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• English: ~0.067'),
              Text('• German: ~0.076'),
              Text('• French: ~0.078'),
              Text('• Italian: ~0.074'),
              Text('• Random text: ~0.038'),
              SizedBox(height: 16),
              Text(
                'Breaking a Vigenère Cipher:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '1. Calculate IoC for different key lengths\n'
                '2. The correct key length will have IoC close to natural language\n'
                '3. Once key length is known, analyze frequency in each column\n'
                '4. Determine each key letter by frequency analysis',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Learn More'),
            onPressed: () {
              Navigator.of(context).pop();
              _toggleVisualizer();
            },
          ),
        ],
      ),
    );
  }
}
