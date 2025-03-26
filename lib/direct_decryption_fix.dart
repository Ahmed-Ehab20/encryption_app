import 'package:flutter/material.dart';

/// IMPORTANT FIX FOR DECRYPTED TEXT DISPLAY
///
/// The issue is that the results are stored with the key 'decrypted', not 'plaintext'.
/// Replace the existing Container in the _buildResults method with this replacement
/// that uses extremely high contrast and the correct key.

/*
Replace this Container in the _buildResults method:

Container(
  width: double.infinity,
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: isDark
        ? Colors.black.withOpacity(0.3)
        : Colors.grey.withOpacity(0.1),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
    result['plaintext'] ?? '',
    style: TextStyle(
      color: isDark ? Colors.white : Colors.black87,
      fontSize: 15,
    ),
  ),
),

WITH THIS FIXED VERSION:
*/

Container(
  width: double.infinity,
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    // Use FAR more opaque backgrounds with stronger contrast
    color: isDark
        ? Colors.black.withOpacity(0.9)   // Nearly opaque black for dark mode
        : Colors.white,                   // Pure white for light mode
    borderRadius: BorderRadius.circular(8),
    // Add a strong visible border
    border: Border.all(
      color: isDark
          ? Colors.white.withOpacity(0.6)  // Visible white border in dark mode
          : Colors.black.withOpacity(0.3), // Visible black border in light mode
      width: 1.5,                         // Thicker border for visibility
    ),
  ),
  child: Text(
    // *** IMPORTANT: Use 'decrypted' key, not 'plaintext' ***
    result['decrypted'] ?? '',
    style: TextStyle(
      // Maximum contrast colors
      color: isDark 
          ? Colors.white              // Pure white text on dark backgrounds
          : Colors.black,             // Pure black text on light backgrounds
      fontWeight: FontWeight.w600,    // Even bolder text
      fontSize: 16,                   // Larger font size
      letterSpacing: 0.5,             // Add letter spacing for readability
      height: 1.4,                    // Improve line spacing for readability
    ),
  ),
),


/*
ALSO IMPORTANT: Update the Clipboard code:

From:
Clipboard.setData(ClipboardData(text: result['plaintext'] ?? ''));

To:
Clipboard.setData(ClipboardData(text: result['decrypted'] ?? ''));

And update the _addToHistory method:

From:
resultText: result['plaintext'] ?? '',

To:
resultText: result['decrypted'] ?? '',
*/ 