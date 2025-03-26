// This file contains the fixed code for improving text visibility in the decrypted text display

/*
Replace the Container in _buildResults() method with this code:

Container(
  width: double.infinity,
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    // Use more opaque backgrounds for better contrast
    color: isDark
        ? Colors.black.withOpacity(0.7)  // Increased opacity for dark mode
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
    result['plaintext'] ?? '',
    style: TextStyle(
      // Ensure high contrast for text visibility with increased opacity
      color: isDark 
          ? Colors.white 
          : Colors.black.withOpacity(0.9),
      fontWeight: FontWeight.w500,  // Slightly bolder text
      fontSize: 15,
      height: 1.4, // Improve line spacing for readability
    ),
  ),
),
*/

// Also update all instances of 'result['decrypted']' to 'result['plaintext']' if they still exist
