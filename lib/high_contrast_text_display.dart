import 'package:flutter/material.dart';

/// A custom widget to display text with high contrast
/// Use this widget to replace the Container in your results display
class HighContrastTextDisplay extends StatelessWidget {
  final String text;
  final bool isDarkMode;

  /// Create a high contrast text display
  ///
  /// [text] - The text to display
  /// [isDarkMode] - Whether the app is in dark mode
  const HighContrastTextDisplay({
    Key? key,
    required this.text,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // Use more opaque backgrounds for better contrast
        color: isDarkMode
            ? Colors.black.withOpacity(0.7) // Increased opacity for dark mode
            : Colors.grey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        // Add a border to improve visibility
        border: Border.all(
          color: isDarkMode
              ? Colors.grey.withOpacity(0.5)
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          // Ensure high contrast for text visibility with increased opacity
          color: isDarkMode ? Colors.white : Colors.black.withOpacity(0.9),
          fontWeight: FontWeight.w500, // Slightly bolder text
          fontSize: 15,
          height: 1.4, // Improve line spacing for readability
        ),
      ),
    );
  }
}

/*
USAGE EXAMPLE:

Replace your existing Container with:

HighContrastTextDisplay(
  text: result['plaintext'] ?? result['decrypted'] ?? '',
  isDarkMode: isDark,
)

Don't forget to add the import at the top of your file:
import 'high_contrast_text_display.dart';
*/
