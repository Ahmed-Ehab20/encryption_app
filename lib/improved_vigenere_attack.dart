import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'improved_vigenere.dart';
import 'file_utils.dart';
import 'vigenere_attack_methods.dart';

/// An improved Vigenère cipher attack page that supports multiple cracking methods
class ImprovedVigenereAttackPage extends StatefulWidget {
  const ImprovedVigenereAttackPage({Key? key}) : super(key: key);

  @override
  State<ImprovedVigenereAttackPage> createState() =>
      _ImprovedVigenereAttackPageState();
}

class _ImprovedVigenereAttackPageState
    extends State<ImprovedVigenereAttackPage> {
  final TextEditingController _cipherTextController = TextEditingController();
  final TextEditingController _cribController = TextEditingController();
  final TextEditingController _keyLengthController = TextEditingController();

  List<String> _dictionaryWords = [];
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  double _progress = 0.0;
  String _statusMessage = '';
  VigenereAttackMethod _selectedMethod = VigenereAttackMethod.dictionaryAttack;
  int _keyLengthHint = 0;

  @override
  void initState() {
    super.initState();
    _loadDictionary();
  }

  // Load dictionary from file
  Future<void> _loadDictionary() async {
    try {
      final String content = await FileUtils.loadTextFile('lib/dictionary.txt');

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
    }
  }

  // Readability checker for scoring decryptions
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

  // Update progress during attacks
  void _updateProgress(double progress, String status) {
    if (!mounted) return;
    setState(() {
      _progress = progress.clamp(0.0, 1.0);
      _statusMessage = status;
    });
  }

  // Run the selected attack method
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
      int keyLength = 0;
      if (_keyLengthController.text.isNotEmpty) {
        keyLength = int.tryParse(_keyLengthController.text) ?? 0;
      }

      List<Map<String, dynamic>> results;

      switch (_selectedMethod) {
        case VigenereAttackMethod.dictionaryAttack:
          results = await VigenereUtil.dictionaryAttack(
              cipherText: cipherText,
              dictionary: _dictionaryWords,
              readabilityChecker: _checkReadability,
              threshold: 0.4,
              progressCallback: (progress, key) {
                _updateProgress(progress,
                    'Testing key: $key (${(progress * 100).toInt()}%)');
              });
          break;

        case VigenereAttackMethod.frequencyTables:
          results = await VigenereAttacker.frequencyTableAttack(
              cipherText, keyLength, _updateProgress);
          break;

        case VigenereAttackMethod.fitness:
          results = await VigenereAttacker.fitnessAttack(
              cipherText, _updateProgress, _checkReadability);
          break;

        case VigenereAttackMethod.crib:
          String crib = _cribController.text.trim();
          if (crib.isEmpty) {
            setState(() {
              _isLoading = false;
              _statusMessage = 'Please enter a crib (known plaintext)';
            });
            return;
          }

          results = await VigenereAttacker.cribAttack(
              cipherText, crib, _updateProgress, _checkReadability);
          break;

        case VigenereAttackMethod.indexOfCoincidence:
          results = await VigenereAttacker.iocAttack(
              cipherText, _updateProgress, _checkReadability);
          break;

        default:
          // For methods not fully implemented yet
          setState(() {
            _isLoading = false;
            _statusMessage =
                '${_selectedMethod.displayName} is not fully implemented yet';
          });
          return;
      }

      setState(() {
        _results = results;
        _isLoading = false;
        _statusMessage = results.isEmpty
            ? 'No matches found'
            : 'Found ${results.length} potential matches';
      });
    } catch (e) {
      print('Error during attack: $e');
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error during attack: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Advanced Vigenère Attack'),
      ),
      body: Column(
        children: [
          // Attack method selector
          VigenereMethodSelector(
            initialMethod: _selectedMethod,
            onMethodSelected: (method) {
              setState(() {
                _selectedMethod = method;
                _results = []; // Clear previous results
              });
            },
          ),

          // Method-specific inputs
          if (_selectedMethod == VigenereAttackMethod.crib)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _cribController,
                decoration: InputDecoration(
                  labelText: 'Known Plaintext (Crib)',
                  border: OutlineInputBorder(),
                  hintText:
                      'Enter a word or phrase you expect in the plaintext',
                ),
              ),
            ),

          if (_selectedMethod != VigenereAttackMethod.dictionaryAttack &&
              _selectedMethod != VigenereAttackMethod.indexOfCoincidence)
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _keyLengthController,
                      decoration: InputDecoration(
                        labelText: 'Key Length (Optional)',
                        border: OutlineInputBorder(),
                        hintText: 'If known, enter key length',
                      ),
                      keyboardType: TextInputType.number,
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

                        int length =
                            await VigenereAttacker.estimateKeyLength(text);

                        setState(() {
                          _isLoading = false;
                          if (length > 0) {
                            _keyLengthController.text = length.toString();
                            _statusMessage = 'Estimated key length: $length';
                          } else {
                            _statusMessage = 'Could not estimate key length';
                          }
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

          // Ciphertext input
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

          // Progress indicator
          if (_isLoading)
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: LinearProgressIndicator(
                      value: _progress > 0 ? _progress : null),
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

          // Results display
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
      ),
    );
  }
}
