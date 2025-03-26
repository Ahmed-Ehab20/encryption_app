import 'package:flutter/material.dart';

/// A debugging widget to show all keys and values in the result map
class DebugResultInfo extends StatelessWidget {
  final Map<String, dynamic> result;
  final bool isDark;

  const DebugResultInfo({
    Key? key,
    required this.result,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DEBUG - RESULT MAP CONTENTS:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade900,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            ...result.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key}: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${entry.value}',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            Divider(),
            Text(
              'INSTRUCTIONS:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade900,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '1. Add this widget after the "Decrypted Text:" section in _buildResults method',
              style: TextStyle(color: Colors.black87),
            ),
            Text(
              '2. Look for the key that contains the decrypted text',
              style: TextStyle(color: Colors.black87),
            ),
            Text(
              '3. Update the Container to use that key instead',
              style: TextStyle(color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

/* 
HOW TO USE:

1. Import this file in main.dart:
   import 'package:your_app/debug_result_info.dart';

2. Add this widget right after the "Decrypted Text:" section in the _buildResults method:

   Text(
     'Decrypted Text:',
     ...
   ),
   SizedBox(height: 8),
   DebugResultInfo(result: result, isDark: isDark),  // ADD THIS LINE
   SizedBox(height: 8),
   Container(
     ...
   ),
*/
