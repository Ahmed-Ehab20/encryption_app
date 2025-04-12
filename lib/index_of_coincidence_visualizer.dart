import 'package:flutter/material.dart';
import 'dart:math';

/// A widget that visualizes how the Index of Coincidence works and can be used
/// to determine the key length of a Vigenère cipher.
class IndexOfCoincidenceVisualizer extends StatefulWidget {
  final String cipherText;
  final VoidCallback? onBackPressed;
  final Function(int keyLength)? onKeyLengthSelected;

  const IndexOfCoincidenceVisualizer({
    Key? key,
    required this.cipherText,
    this.onBackPressed,
    this.onKeyLengthSelected,
  }) : super(key: key);

  @override
  State<IndexOfCoincidenceVisualizer> createState() =>
      _IndexOfCoincidenceVisualizerState();
}

class _IndexOfCoincidenceVisualizerState
    extends State<IndexOfCoincidenceVisualizer> {
  late String _cleanText;
  Map<int, double> _iocScores = {};
  int _selectedKeyLength = 0;
  bool _isCalculating = false;
  String _infoText = 'Tap "Calculate" to analyze the ciphertext';

  // Reference values for interpretation
  final double _randomTextIoC = 0.038; // Random text IoC
  final double _englishTextIoC = 0.067; // English text IoC

  @override
  void initState() {
    super.initState();
    _preprocessText();
  }

  void _preprocessText() {
    // Keep only letters for analysis
    _cleanText = '';
    for (int i = 0; i < widget.cipherText.length; i++) {
      if (RegExp(r'[A-Za-z]').hasMatch(widget.cipherText[i])) {
        _cleanText += widget.cipherText[i].toLowerCase();
      }
    }

    setState(() {
      if (_cleanText.length < 20) {
        _infoText =
            'Warning: Text is too short for reliable analysis (${_cleanText.length} characters)';
      } else {
        _infoText = 'Ready to analyze ${_cleanText.length} characters';
      }
    });
  }

  Future<void> _calculateIoC() async {
    if (_cleanText.length < 20) {
      setState(() {
        _infoText = 'Text is too short for reliable analysis';
      });
      return;
    }

    setState(() {
      _isCalculating = true;
      _iocScores = {};
      _infoText = 'Calculating...';
    });

    // Test key lengths from 1 to 20
    for (int length = 1; length <= 20; length++) {
      await _calculateIoCForLength(length);

      // Update UI after each calculation
      setState(() {
        _infoText = 'Testing key length $length of 20...';
      });

      // Allow UI to update
      await Future.delayed(Duration(milliseconds: 50));
    }

    // Find best key length
    double highestIoC = 0.0;
    int bestLength = 0;

    for (final entry in _iocScores.entries) {
      if (entry.value > highestIoC) {
        highestIoC = entry.value;
        bestLength = entry.key;
      }
    }

    setState(() {
      _selectedKeyLength = bestLength;
      _isCalculating = false;
      _infoText =
          'Analysis complete. Likely key length: $bestLength (IoC: ${highestIoC.toStringAsFixed(4)})';
    });

    if (widget.onKeyLengthSelected != null) {
      widget.onKeyLengthSelected!(_selectedKeyLength);
    }
  }

  Future<void> _calculateIoCForLength(int length) async {
    double avgIoC = 0.0;

    // Split text into columns based on key length
    List<String> columns = List.generate(length, (i) => '');
    for (int i = 0; i < _cleanText.length; i++) {
      columns[i % length] += _cleanText[i];
    }

    // Calculate IoC for each column
    int validColumns = 0;
    for (String col in columns) {
      if (col.length < 2) continue;

      // Count letter frequencies
      Map<String, int> freqCount = {};
      for (int i = 0; i < col.length; i++) {
        freqCount[col[i]] = (freqCount[col[i]] ?? 0) + 1;
      }

      // Calculate IoC for this column
      double ioc = 0.0;
      int sum = 0;

      for (int count in freqCount.values) {
        ioc += count * (count - 1);
        sum += count;
      }

      if (sum > 1) {
        ioc /= (sum * (sum - 1));
        avgIoC += ioc;
        validColumns++;
      }
    }

    if (validColumns > 0) {
      avgIoC /= validColumns;
      setState(() {
        _iocScores[length] = avgIoC;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Index of Coincidence Analysis'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: widget.onBackPressed,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(isDark),
            SizedBox(height: 16),
            _buildSimpleChart(isDark),
            SizedBox(height: 16),
            _buildExplanationCard(isDark),
            SizedBox(height: 16),
            _buildKeyLengthSelector(isDark),
            SizedBox(height: 16),
            _buildFrequencyVisualizer(isDark),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isCalculating ? null : _calculateIoC,
        label: Text(_isCalculating ? 'Calculating...' : 'Calculate'),
        icon: Icon(_isCalculating ? Icons.hourglass_top : Icons.calculate),
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
              'Index of Coincidence (IoC) Analysis',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'The Index of Coincidence measures the probability that two randomly selected letters from a text are the same. For Vigenère ciphers, when the correct key length is used to divide the text, each column should have an IoC closer to natural language (~0.067 for English) rather than random text (~0.038).',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.blueGrey.shade800 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: isDark ? Colors.blue.shade300 : Colors.blue.shade800,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _infoText,
                      style: TextStyle(
                        color: isDark
                            ? Colors.blue.shade300
                            : Colors.blue.shade800,
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

  Widget _buildSimpleChart(bool isDark) {
    if (_iocScores.isEmpty) {
      return Card(
        elevation: 2,
        child: Container(
          height: 200,
          width: double.infinity,
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No data yet. Click "Calculate" to analyze.',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    // Find min and max values for the chart
    double maxIoC = _iocScores.values.reduce(max) + 0.005;
    double minIoC = max(0, _iocScores.values.reduce(min) - 0.005);

    // Reference values
    double englishLinePosition = (_englishTextIoC - minIoC) / (maxIoC - minIoC);
    double randomLinePosition = (_randomTextIoC - minIoC) / (maxIoC - minIoC);

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'IoC Values by Key Length',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  minIoC.toStringAsFixed(3),
                  style: TextStyle(fontSize: 12),
                ),
                Text(
                  maxIoC.toStringAsFixed(3),
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            Container(
              height: 220,
              child: Stack(
                children: [
                  // Reference line for English text
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 220 * (1 - englishLinePosition),
                    child: Container(
                      height: 1,
                      color: Colors.green.withOpacity(0.5),
                    ),
                  ),
                  // Label for English reference
                  Positioned(
                    right: 0,
                    top: 220 * (1 - englishLinePosition) - 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      color: Colors.green.withOpacity(0.2),
                      child: Text(
                        'English (${_englishTextIoC.toStringAsFixed(3)})',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),

                  // Reference line for random text
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 220 * (1 - randomLinePosition),
                    child: Container(
                      height: 1,
                      color: Colors.red.withOpacity(0.5),
                    ),
                  ),
                  // Label for random reference
                  Positioned(
                    right: 0,
                    top: 220 * (1 - randomLinePosition) - 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      color: Colors.red.withOpacity(0.2),
                      child: Text(
                        'Random (${_randomTextIoC.toStringAsFixed(3)})',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),

                  // Bars for IoC values
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(20, (index) {
                      final keyLength = index + 1;
                      final ioc = _iocScores[keyLength] ?? 0.0;
                      final normalizedHeight =
                          (ioc - minIoC) / (maxIoC - minIoC);

                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedKeyLength = keyLength;
                              });

                              if (widget.onKeyLengthSelected != null) {
                                widget.onKeyLengthSelected!(_selectedKeyLength);
                              }
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: 220 * normalizedHeight,
                                  decoration: BoxDecoration(
                                    color: _selectedKeyLength == keyLength
                                        ? Theme.of(context).primaryColor
                                        : Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.3),
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                    border: Border.all(
                                      color: _selectedKeyLength == keyLength
                                          ? Theme.of(context).primaryColorDark
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  keyLength.toString(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: _selectedKeyLength == keyLength
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                    'IoC Values', Theme.of(context).primaryColor, isDark),
                SizedBox(width: 16),
                _buildLegendItem('English Text', Colors.green, isDark),
                SizedBox(width: 16),
                _buildLegendItem('Random Text', Colors.red, isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildExplanationCard(bool isDark) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How It Works',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'The Index of Coincidence (IoC) measures the probability that two randomly selected letters from a text are the same. Different languages have characteristic IoC values:',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            _buildIoCInfoItem('English', _englishTextIoC, Colors.green, isDark),
            _buildIoCInfoItem(
                'Random text', _randomTextIoC, Colors.red, isDark),
            SizedBox(height: 16),
            Text(
              'For Vigenère ciphers:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '1. When we split the ciphertext into columns based on the correct key length, each column contains letters encrypted with the same Caesar shift.',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '2. Each column will have frequency characteristics closer to natural language rather than random distribution.',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '3. The key length that produces IoC values closest to natural language is likely correct.',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIoCInfoItem(
      String label, double value, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            color: color,
          ),
          SizedBox(width: 8),
          Text(
            '$label: ${value.toStringAsFixed(3)}',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyLengthSelector(bool isDark) {
    if (_iocScores.isEmpty) {
      return SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Length Selection',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Suggested key length based on highest IoC: $_selectedKeyLength',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'You can also manually select a key length:',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(20, (index) {
                  final keyLength = index + 1;
                  final ioc = _iocScores[keyLength] ?? 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        '$keyLength (${ioc.toStringAsFixed(3)})',
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                      selected: _selectedKeyLength == keyLength,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedKeyLength = keyLength;
                          });

                          if (widget.onKeyLengthSelected != null) {
                            widget.onKeyLengthSelected!(_selectedKeyLength);
                          }
                        }
                      },
                    ),
                  );
                }),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                if (widget.onKeyLengthSelected != null &&
                    _selectedKeyLength > 0) {
                  widget.onKeyLengthSelected!(_selectedKeyLength);
                }
                if (widget.onBackPressed != null) {
                  widget.onBackPressed!();
                }
              },
              icon: Icon(Icons.check),
              label: Text('Use Selected Key Length'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyVisualizer(bool isDark) {
    if (_iocScores.isEmpty || _selectedKeyLength <= 0) {
      return SizedBox.shrink();
    }

    // Split text into columns
    List<String> columns = List.generate(_selectedKeyLength, (i) => '');
    for (int i = 0; i < _cleanText.length; i++) {
      columns[i % _selectedKeyLength] += _cleanText[i];
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frequency Analysis for Key Length $_selectedKeyLength',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'When text is divided into $_selectedKeyLength columns, each shows frequency patterns of a single Caesar shift:',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: List.generate(min(_selectedKeyLength, 5), (colIndex) {
                  return _buildColumnFrequency(
                      columns[colIndex], colIndex, isDark);
                }),
              ),
            ),
            if (_selectedKeyLength > 5)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Showing first 5 of $_selectedKeyLength columns',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnFrequency(String text, int columnIndex, bool isDark) {
    // Count letter frequencies
    Map<String, int> freqCount = {};
    for (int i = 0; i < text.length; i++) {
      freqCount[text[i]] = (freqCount[text[i]] ?? 0) + 1;
    }

    // Sort by frequency (descending)
    List<MapEntry<String, int>> sortedFreq = freqCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Get max frequency for normalization
    int maxFreq = sortedFreq.isNotEmpty ? sortedFreq.first.value : 0;

    return Container(
      width: 150,
      margin: EdgeInsets.only(right: 16),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? Colors.blueGrey.shade800 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'Column ${columnIndex + 1}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: sortedFreq.isEmpty
                ? Center(
                    child: Text(
                      'No data',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: min(10, sortedFreq.length),
                    itemBuilder: (context, index) {
                      final entry = sortedFreq[index];
                      final double percentage =
                          maxFreq > 0 ? entry.value / maxFreq : 0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Container(
                              width: 15,
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Stack(
                                children: [
                                  Container(
                                    height: 12,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  Container(
                                    height: 12,
                                    width: percentage * 100,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 4),
                            Container(
                              width: 20,
                              child: Text(
                                '${entry.value}',
                                style: TextStyle(
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
