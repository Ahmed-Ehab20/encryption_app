import 'package:flutter/material.dart';
import 'index_of_coincidence_page.dart';

/// Example implementation showing how to integrate attack method toggling
/// between dictionary attack and IoC/frequency analysis.
///
/// This can be integrated with your existing Vigenère cipher attack tools.

class CipherAttackOptionsWidget extends StatefulWidget {
  final String ciphertext;
  final Function(String) onKeyFound;

  const CipherAttackOptionsWidget({
    Key? key,
    required this.ciphertext,
    required this.onKeyFound,
  }) : super(key: key);

  @override
  _CipherAttackOptionsWidgetState createState() =>
      _CipherAttackOptionsWidgetState();
}

class _CipherAttackOptionsWidgetState extends State<CipherAttackOptionsWidget> {
  bool _useDictionaryAttack = true;
  bool _isAnalyzing = false;
  String _status = '';

  // Open the Index of Coincidence analysis page
  void _openIoCAnalysis() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IndexOfCoincidencePageWithText(
          initialCiphertext: widget.ciphertext,
          onBackPressed: () => Navigator.of(context).pop(),
          onKeyFound: (key) {
            Navigator.of(context).pop();
            widget.onKeyFound(key);
          },
        ),
      ),
    );
  }

  // Start dictionary attack
  Future<void> _startDictionaryAttack() async {
    setState(() {
      _isAnalyzing = true;
      _status = 'Running dictionary attack...';
    });

    try {
      // Simulate dictionary attack
      await Future.delayed(Duration(seconds: 2));

      // In a real implementation, you would call your actual dictionary attack method
      // String key = await YourDictionaryAttackMethod(widget.ciphertext);

      String key = "EXAMPLE"; // Replace with actual result

      setState(() {
        _isAnalyzing = false;
        _status = 'Dictionary attack complete. Key found: $key';
      });

      widget.onKeyFound(key);
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _status = 'Dictionary attack failed: ${e.toString()}';
      });
    }
  }

  // Start selected analysis method based on toggle
  void _startAnalysis() {
    if (_useDictionaryAttack) {
      _startDictionaryAttack();
    } else {
      _openIoCAnalysis();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attack Methods',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            // Toggle switch between attack methods
            SwitchListTile(
              title: Text('Use Dictionary Attack'),
              subtitle: Text(_useDictionaryAttack
                  ? 'Search through known words for potential keys'
                  : 'Use Index of Coincidence and frequency analysis instead'),
              value: _useDictionaryAttack,
              onChanged: (value) {
                setState(() {
                  _useDictionaryAttack = value;
                });
              },
            ),

            SizedBox(height: 8),

            // Information about selected method
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black12
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _useDictionaryAttack
                        ? 'Dictionary Attack'
                        : 'IoC & Frequency Analysis',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _useDictionaryAttack
                        ? 'Attempts to decrypt the cipher by trying common words as potential keys. Fast for simple ciphers with dictionary words as keys.'
                        : 'Analyzes letter frequencies and index of coincidence to determine key length and probable key characters. More effective for complex ciphers with non-dictionary keys.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Status message
            if (_status.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  _status,
                  style: TextStyle(
                    color:
                        _status.contains('failed') ? Colors.red : Colors.green,
                  ),
                ),
              ),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(_useDictionaryAttack
                    ? Icons.book_outlined
                    : Icons.analytics_outlined),
                label: Text(_useDictionaryAttack
                    ? 'Start Dictionary Attack'
                    : 'Start IoC Analysis'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _isAnalyzing ? null : _startAnalysis,
              ),
            ),

            if (_isAnalyzing)
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Example of how to integrate this widget into your cipher analysis page
class CipherAnalysisExample extends StatefulWidget {
  @override
  _CipherAnalysisExampleState createState() => _CipherAnalysisExampleState();
}

class _CipherAnalysisExampleState extends State<CipherAnalysisExample> {
  String _ciphertext = 'RVGLLVGLLHYTUHZGLLHPLOHKRTMFVGOSHZBKYHUAVHYVCWEZ';
  String _foundKey = '';
  String _plaintext = '';

  void _handleKeyFound(String key) {
    setState(() {
      _foundKey = key;
      _plaintext = _simulateDecryption(_ciphertext, key);
    });
  }

  // Simplified decryption function for demonstration
  String _simulateDecryption(String ciphertext, String key) {
    // In a real implementation, call your actual Vigenère decryption function
    // For demo purposes, just return a placeholder
    return "This would be the decrypted text using the key: $key";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vigenère Cipher Analysis'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ciphertext to Analyze',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Text(_ciphertext),
            ),

            SizedBox(height: 24),

            // The attack options widget
            CipherAttackOptionsWidget(
              ciphertext: _ciphertext,
              onKeyFound: _handleKeyFound,
            ),

            SizedBox(height: 24),

            // Results section
            if (_foundKey.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analysis Results',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Found Key: $_foundKey',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Plaintext:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(_plaintext),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Modified version of the IndexOfCoincidencePageWithText to handle key finding callback
class IndexOfCoincidencePageWithText extends IndexOfCoincidencePage {
  final String initialCiphertext;
  final Function(String)? onKeyFound;

  const IndexOfCoincidencePageWithText({
    Key? key,
    required this.initialCiphertext,
    required VoidCallback onBackPressed,
    this.onKeyFound,
  }) : super(key: key, onBackPressed: onBackPressed);

  @override
  State<IndexOfCoincidencePage> createState() {
    // NOTE: You need to implement this method based on your actual
    // IndexOfCoincidencePage implementation structure
    //
    // In a real implementation, you would return an instance of your
    // State class that handles the initialCiphertext and onKeyFound callback
    throw UnimplementedError(
        'You need to implement this method based on your IndexOfCoincidencePage structure');
  }
}
