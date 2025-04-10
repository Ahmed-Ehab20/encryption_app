import 'dart:io';
import 'package:flutter/services.dart';

/// Utility class for loading files from different sources
class FileUtils {
  /// Loads text content from a file path or asset
  ///
  /// This method tries multiple approaches to load the file:
  /// 1. First as a direct file path
  /// 2. Then as an asset
  /// 3. Finally with 'assets/' prefix
  ///
  /// Returns the text content of the file
  static Future<String> loadTextFile(String path) async {
    try {
      // First try to load as a direct file path
      try {
        final File file = File(path);
        if (await file.exists()) {
          return await file.readAsString();
        }
      } catch (e) {
        print('Could not load as direct file: $e');
      }

      // Then try to load from assets bundle
      try {
        return await rootBundle.loadString(path);
      } catch (e) {
        print('Could not load from assets: $e');
      }

      // Finally try with 'assets/' prefix
      try {
        return await rootBundle.loadString('assets/$path');
      } catch (e) {
        print('Could not load with assets/ prefix: $e');
        // If all attempts fail, throw the error
        throw Exception('Failed to load file: $path');
      }
    } catch (e) {
      print('Error loading file: $e');
      rethrow;
    }
  }
}
