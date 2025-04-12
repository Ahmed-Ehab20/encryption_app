import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'enhanced_vigenere_cracker.dart';
import 'file_utils.dart';
import 'dart:math';

class EnhancedVigenerePage extends StatefulWidget {
  final List<String> savedKeys;
  final Function(List<String>) onSavedKeysUpdate;

  const EnhancedVigenerePage({
    Key? key,
    this.savedKeys = const [],
    required this.onSavedKeysUpdate,
  }) : super(key: key);

  @override
  _EnhancedVigenerePageState createState() => _EnhancedVigenerePageState();
}

class _EnhancedVigenerePageState extends State<EnhancedVigenerePage> {
  final TextEditingController _inputController = TextEditingController();
  bool _isAnalyzing = false;
  double _progress = 0.0;
  String _statusMessage = '';
  List<Map<String, dynamic>> _results = [];
  List<String> _dictionary = [];
  List<String> _savedKeys = [];

  // Track which method is currently selected
  String _selectedMethod = 'Dictionary Attack'; // Default selected method

  @override
  void initState() {
    super.initState();
    _savedKeys = List.from(widget.savedKeys);
    _loadDictionary();
  }

  Future<void> _loadDictionary() async {
    try {
      // Attempt to load the dictionary file
      final String content = await FileUtils.loadTextFile('lib/dictionary.txt');
      _dictionary = content
          .split('\n')
          .map((s) => s.trim().toLowerCase())
          .where((s) => s.isNotEmpty && s.length >= 2)
          .toList();

      print('Loaded ${_dictionary.length} words from dictionary file');

      if (_dictionary.isEmpty) {
        // Fallback to a smaller built-in dictionary
        _dictionary = [
          // Common short words
          'the', 'and', 'for', 'are', 'but', 'not', 'you', 'all', 'any', 'can',
          'had', 'her', 'was', 'one', 'our', 'out', 'day', 'get', 'has', 'him',
          // Common crypto terms
          'key', 'code', 'data', 'text', 'hash', 'salt', 'bits', 'byte', 'file',
          'cipher', 'secret', 'secure', 'decode', 'encode', 'crypto',
          'vigenere',
          // Names and common short words
          'john', 'jane', 'mary', 'mike', 'dave', 'anna', 'james', 'sarah',
          'david',
          'hello', 'world', 'password', 'admin', 'test', 'welcome',
        ];
      }
    } catch (e) {
      print('Error loading dictionary file: $e');
      // Fallback to minimal dictionary
      _dictionary = [
        'key',
        'password',
        'test',
        'secret',
        'vigenere',
        'cipher',
        'a',
        'b'
      ];
    }
  }

  Future<void> _analyzeText() async {
    final text = _inputController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter text to analyze')),
      );
      return;
    }

    if (text.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Text is too short for meaningful analysis')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _progress = 0.0;
      _statusMessage = 'Starting analysis...';
      _results = [];
    });

    try {
      // Create a list of enabled methods (just the selected one)
      List<String> enabledMethods = [_selectedMethod];

      // Run the analysis
      final results = await EnhancedVigenereCracker.crackShortText(
        ciphertext: text,
        enabledMethods: enabledMethods,
        dictionary: _dictionary,
        savedKeys: _savedKeys,
        progressCallback: (message) {
          if (mounted) {
            setState(() {
              _statusMessage = message;
            });
          }
        },
        progressValueCallback: (value) {
          if (mounted) {
            setState(() {
              _progress = value;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _results = results;

          if (results.isEmpty) {
            _statusMessage = 'No results found. Try another method or text.';
          } else {
            _statusMessage = 'Found ${results.length} potential results.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _statusMessage = 'Error during analysis: $e';
        });
      }
      print('Error analyzing text: $e');
    }
  }

  void _saveKey(String key) {
    if (!_savedKeys.contains(key)) {
      setState(() {
        _savedKeys.add(key);
      });
      widget.onSavedKeysUpdate(_savedKeys);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Key "$key" saved')),
      );
    }
  }

  void _removeKey(String key) {
    if (_savedKeys.contains(key)) {
      setState(() {
        _savedKeys.remove(key);
      });
      widget.onSavedKeysUpdate(_savedKeys);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Key "$key" removed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('Enhanced Vigenère Cracker'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 20),
                _buildInputSection(),
                SizedBox(height: 20),
                _buildMethodSelector(),
                SizedBox(height: 20),
                _buildAnalyzeButton(),
                SizedBox(height: 20),
                if (_isAnalyzing) _buildProgressIndicator(),
                if (_results.isNotEmpty) _buildResults(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enhanced Vigenère Cryptanalysis',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Optimized for short text (1-2 sentences). Select one method below to analyze your ciphertext.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lock,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(width: 8),
                Text(
                  'Ciphertext',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Spacer(),
                if (_inputController.text.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear, size: 18),
                    onPressed: () {
                      setState(() {
                        _inputController.clear();
                        _results = [];
                      });
                    },
                    tooltip: 'Clear text',
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _inputController,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 15,
                ),
                maxLines: 5,
                minLines: 3,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter encrypted text to analyze...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black38,
                  ),
                  contentPadding: EdgeInsets.all(12),
                ),
                onChanged: (text) {
                  // Clear results when input changes
                  if (_results.isNotEmpty) {
                    setState(() {
                      _results = [];
                    });
                  }
                },
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_inputController.text.isNotEmpty)
                  Text(
                    'Characters: ${_inputController.text.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                  ),
                if (_savedKeys.isNotEmpty)
                  Text(
                    'Saved keys: ${_savedKeys.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodSelector() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Analysis Method',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ...EnhancedVigenereCracker.availableMethods.map((method) {
              return _buildMethodOption(method);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodOption(VigenereCrackingMethod method) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedMethod == method.name;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
        color: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Colors.transparent,
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMethod = method.name;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                method.icon,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : (isDark ? Colors.white70 : Colors.black54),
                size: 22,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.name,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      method.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Radio<String>(
                value: method.name,
                groupValue: _selectedMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedMethod = value!;
                  });
                },
                activeColor: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isAnalyzing ? null : _analyzeText,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isAnalyzing)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            if (_isAnalyzing) SizedBox(width: 12),
            Text(
              _isAnalyzing ? 'Analyzing...' : 'Crack Vigenère Cipher',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value: _progress > 0 ? _progress : null,
              strokeWidth: 4,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 16),
            Text(
              _statusMessage,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            if (_progress > 0) ...[
              SizedBox(height: 8),
              Text(
                '${(_progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Results',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_results.length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Spacer(),
                Text(
                  'Method: $_selectedMethod',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final result = _results[index];
                final bool isBestMatch = index == 0;
                final bool isSavedKey =
                    _savedKeys.contains(result['key'].toString());
                final readabilityScore = result['score'] ?? 0.0;

                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isBestMatch
                          ? Theme.of(context).primaryColor
                          : Colors.grey.withOpacity(0.2),
                      width: isBestMatch ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        if (isBestMatch)
                          Icon(
                            Icons.star,
                            color: Theme.of(context).primaryColor,
                            size: 18,
                          ),
                        if (isBestMatch) SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Key: ${result['key']}',
                            style: TextStyle(
                              fontWeight: isBestMatch
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isBestMatch
                                  ? Theme.of(context).primaryColor
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ),
                        if (isSavedKey)
                          Icon(Icons.bookmark, color: Colors.amber, size: 18),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Score: ${readabilityScore.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            SizedBox(width: 8),
                            _buildScoreIndicator(readabilityScore),
                          ],
                        ),
                        if (result['method'] != null)
                          Text(
                            'Method: ${result['method']}',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: isDark ? Colors.white60 : Colors.black45,
                            ),
                          ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Decrypted Text:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.black.withOpacity(0.9)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.6)
                                      : Colors.black.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                result['decrypted'] ?? '',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  letterSpacing: 0.5,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  icon: Icon(Icons.copy, size: 18),
                                  label: Text('Copy'),
                                  style: ElevatedButton.styleFrom(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(
                                        text: result['decrypted'] ?? ''));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Decrypted text copied to clipboard'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(width: 8),
                                ElevatedButton.icon(
                                  icon: Icon(
                                    isSavedKey
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    size: 18,
                                  ),
                                  label:
                                      Text(isSavedKey ? 'Saved' : 'Save Key'),
                                  style: ElevatedButton.styleFrom(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    backgroundColor: isSavedKey
                                        ? Colors.amber
                                        : Theme.of(context).primaryColor,
                                  ),
                                  onPressed: () {
                                    final key = result['key'].toString();
                                    if (isSavedKey) {
                                      _removeKey(key);
                                    } else {
                                      _saveKey(key);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreIndicator(double score) {
    Color color;
    int filledDots;

    if (score >= 80) {
      color = Colors.green;
      filledDots = 5;
    } else if (score >= 60) {
      color = Colors.green[400]!;
      filledDots = 4;
    } else if (score >= 40) {
      color = Colors.orange[400]!;
      filledDots = 3;
    } else if (score >= 20) {
      color = Colors.orange[700]!;
      filledDots = 2;
    } else {
      color = Colors.red[400]!;
      filledDots = 1;
    }

    return Row(
      children: List.generate(5, (index) {
        return Container(
          width: 6,
          height: 6,
          margin: EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < filledDots ? color : Colors.grey.withOpacity(0.3),
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }
}
