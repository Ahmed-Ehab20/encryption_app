import 'package:flutter/material.dart';

/// A debugging widget that displays all keys and values in a result map
class DebugTextDisplay extends StatelessWidget {
  final Map<String, dynamic> result;
  final bool isDark;

  const DebugTextDisplay({
    Key? key,
    required this.result,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create a string representation of all keys and their values
    String debugText = 'Available keys:\n';
    result.forEach((key, value) {
      debugText +=
          '- $key: ${value.toString().substring(0, min(50, value.toString().length))}${value.toString().length > 50 ? '...' : ''}\n';
    });

    String possibleText = '';

    // Try different common keys
    if (result.containsKey('plaintext')) {
      possibleText = result['plaintext'] ?? '';
    } else if (result.containsKey('decrypted')) {
      possibleText = result['decrypted'] ?? '';
    } else if (result.containsKey('text')) {
      possibleText = result['text'] ?? '';
    } else if (result.containsKey('result')) {
      possibleText = result['result'] ?? '';
    } else if (result.containsKey('content')) {
      possibleText = result['content'] ?? '';
    } else if (result.containsKey('message')) {
      possibleText = result['message'] ?? '';
    }

    debugText += '\nCurrent text display attempt: "$possibleText"';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DEBUG INFO',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.8) : Colors.white,
            border: Border.all(color: Colors.red, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            debugText,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        SizedBox(height: 20),
        Text(
          'RESULT DISPLAY',
          style: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.7) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.blue,
              width: 2,
            ),
          ),
          child: Text(
            possibleText.isEmpty ? "[NO TEXT FOUND IN RESULT]" : possibleText,
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  int min(int a, int b) => a < b ? a : b;
}

/*
USAGE:

Replace the text display container with:

DebugTextDisplay(
  result: result,
  isDark: isDark,
),

Don't forget to add the import at the top of your file:
import 'debug_text_display.dart';
*/
