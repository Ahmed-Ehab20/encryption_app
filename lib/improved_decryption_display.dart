import 'package:flutter/material.dart';

/// Use this widget to replace the existing container in the _buildResults method
/// to improve visibility of decrypted text
class DecryptedTextDisplay extends StatelessWidget {
  final Map<String, dynamic> result;
  final bool isDark;

  const DecryptedTextDisplay({
    Key? key,
    required this.result,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        // Use more opaque backgrounds for better contrast
        color: isDark
            ? Colors.black.withOpacity(0.7) // Increased opacity for dark mode
            : Colors.grey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        // Add a border to improve visibility
        border: Border.all(
          color: isDark
              ? Colors.grey.withOpacity(0.5)
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Text(
        // Handle both possible keys in the result map
        result['plaintext'] ?? result['decrypted'] ?? '',
        style: TextStyle(
          // Ensure high contrast for text visibility with increased opacity
          color: isDark ? Colors.white : Colors.black.withOpacity(0.9),
          fontWeight: FontWeight.w500, // Slightly bolder text
          fontSize: 15,
          height: 1.4, // Improve line spacing for readability
        ),
      ),
    );
  }
}

/*
To use this widget, replace the Container in _buildResults method with:

DecryptedTextDisplay(
  result: result,
  isDark: isDark,
),

Don't forget to add the import at the top of your file:
import 'improved_decryption_display.dart';
*/
