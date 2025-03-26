import 'package:flutter/material.dart';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'dart:isolate';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'loading_animation.dart';
import 'loading_animation_wrapper.dart';

// Result class for Vigenère cracking
class VigenereResult {
  final String key;
  final String decrypted;
  final double score;
  final int keyLength;
  final String confidence;

  VigenereResult({
    required this.key,
    required this.decrypted,
    required this.score,
    required this.keyLength,
    required this.confidence,
  });
}

// Message class for isolate communication
class CrackMessage {
  final String text;
  final SendPort sendPort;

  CrackMessage(this.text, this.sendPort);
}

class CipherHistory {
  final String timestamp;
  final String operation;
  final String cipherType;
  final String key;
  final String originalText;
  final String resultText;
  final String timeSpent;
  final double score;

  CipherHistory({
    required this.timestamp,
    required this.operation,
    required this.cipherType,
    required this.key,
    required this.originalText,
    required this.resultText,
    required this.timeSpent,
    required this.score,
  });
}

// Add this class after the CipherHistory class and before the main() function
class LoadingAnimation extends StatefulWidget {
  final double size;
  final Color color;

  const LoadingAnimation({
    Key? key,
    this.size = 40.0,
    this.color = const Color(0xFF6B4EFF),
  }) : super(key: key);

  @override
  _LoadingAnimationState createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _radiusAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    _radiusAnimation = Tween<double>(
      begin: widget.size * 0.2,
      end: widget.size * 0.3,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _CirclePainter(
              rotation: _rotationAnimation.value,
              radius: _radiusAnimation.value,
              color: widget.color,
              dotCount: 8,
            ),
          ),
        );
      },
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double rotation;
  final double radius;
  final Color color;
  final int dotCount;

  _CirclePainter({
    required this.rotation,
    required this.radius,
    required this.color,
    this.dotCount = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final circleRadius = size.width / 2 - radius;

    for (int i = 0; i < dotCount; i++) {
      final angle = rotation + (2 * pi * i / dotCount);
      final offset = Offset(
        center.dx + cos(angle) * circleRadius,
        center.dy + sin(angle) * circleRadius,
      );

      final opacity = 0.3 + (0.7 * i / dotCount);
      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(offset, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_CirclePainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.radius != radius ||
        oldDelegate.color != color;
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cyphy - Cryptography Tool',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF6B4EFF),
        colorScheme: ColorScheme.light(
          primary: Color(0xFF6B4EFF),
          secondary: Color(0xFF00D9DA),
          surface: Colors.white,
          background: Colors.grey[100]!,
          onPrimary: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF2D2D2D),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(
            color: Color(0xFF2D2D2D),
          ),
        ),
        scaffoldBackgroundColor: Colors.grey[50],
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(
            color: Color(0xFF2D2D2D),
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF2D2D2D),
            fontSize: 14,
          ),
          titleLarge: TextStyle(
            color: Color(0xFF2D2D2D),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            color: Color(0xFF2D2D2D),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Color(0xFF6B4EFF),
          textTheme: ButtonTextTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF6B4EFF),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Color(0xFF6B4EFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            side: BorderSide(color: Color(0xFF6B4EFF)),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFF6B4EFF)),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.grey[300],
          thickness: 1,
          space: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Color(0xFF6B4EFF),
          contentTextStyle: TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Color(0xFF6B4EFF),
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF6B4EFF),
          secondary: Color(0xFF00D9DA),
          surface: Color(0xFF2D2D2D),
          background: Color(0xFF1C1C1C),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
        ),
        scaffoldBackgroundColor: Color(0xFF1C1C1C),
        textTheme: TextTheme(
          bodyLarge: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          titleLarge: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Color(0xFF6B4EFF),
          textTheme: ButtonTextTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF6B4EFF),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Color(0xFF6B4EFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            side: BorderSide(color: Color(0xFF6B4EFF)),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFF6B4EFF)),
          ),
          fillColor: Color(0xFF2D2D2D),
          filled: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.grey[800],
          thickness: 1,
          space: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Color(0xFF6B4EFF),
          contentTextStyle: TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      themeMode: ThemeMode.system,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final List<String> savedKeys;

  const HomeScreen({super.key, this.savedKeys = const []});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CipherHistory> _history = [];
  List<String> _savedKeys = [];
  bool _isDictionaryAttack = true;
  final TextEditingController _keyInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _history = [];
    _savedKeys = List.from(widget.savedKeys);
    _loadBlacklist();
    _loadHistory();
    _loadDictionary();
    _keyInputController.clear();
  }

  // Load blacklist of invalid keys
  void _loadBlacklist() {
    // This is just a placeholder since the HomeScreen doesn't actually need a blacklist
    // but the method is called in initState
  }

  // Load encryption history
  void _loadHistory() {
    // In a real app, this would load history from local storage
    _history = [];
  }

  // Load dictionary for attacks
  void _loadDictionary() {
    // In a real app, this would load dictionary from assets or network
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                SizedBox(height: 40),
                _buildModeSelection(context),
                SizedBox(height: 40),
                _buildOptions(),
                SizedBox(height: 40),
                _buildHistorySection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cyphy',
          style: TextStyle(
            color: isDark ? Colors.white : Color(0xFF2D2D2D),
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'CRYPTOGRAPHY TOOLKIT',
          style: TextStyle(
            color: Color(0xFF6B4EFF),
            fontSize: 16,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelection(BuildContext context) {
    return Column(
      children: [
        _buildModeCard(
          context,
          'Encryption',
          'Encrypt your messages',
          Icons.lock,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CipherScreen(
                mode: 'encrypt',
                history: _history,
                onHistoryUpdate: (newHistory) {
                  setState(() {
                    _history = newHistory;
                  });
                },
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
        _buildModeCard(
          context,
          'Decryption',
          'Decrypt your messages',
          Icons.lock_open,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CipherScreen(
                mode: 'decrypt',
                history: _history,
                onHistoryUpdate: (newHistory) {
                  setState(() {
                    _history = newHistory;
                  });
                },
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
        _buildModeCard(
          context,
          'Cipher Cracking',
          'Attempt to crack encrypted messages',
          Icons.psychology,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CipherDetector(
                history: _history,
                onHistoryUpdate: (newHistory) {
                  setState(() {
                    _history = newHistory;
                  });
                },
                savedKeys: _savedKeys,
                onSavedKeysUpdate: (newKeys) {
                  setState(() {
                    _savedKeys = newKeys;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF2D2D2D) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Color(0xFF6B4EFF).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black12 : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF6B4EFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Color(0xFF6B4EFF), size: 30),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Color(0xFF2D2D2D),
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isDark ? Colors.white54 : Colors.black38,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('Dictionary Attack'),
                ),
                Switch(
                  value: _isDictionaryAttack,
                  onChanged: (value) {
                    setState(() {
                      _isDictionaryAttack = value;
                    });
                  },
                ),
              ],
            ),
            if (_isDictionaryAttack) ...[
              SizedBox(height: 16),
              Text(
                'Saved Keys:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              if (_savedKeys.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _savedKeys
                      .map((key) => Chip(
                            label: Text(key),
                            deleteIcon: Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _savedKeys.remove(key);
                              });
                            },
                          ))
                      .toList(),
                )
              else
                Text(
                  'No saved keys yet. When you find a working key, you can save it here.',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _keyInputController,
                      decoration: InputDecoration(
                        labelText: 'Add Key',
                        hintText: 'Enter a key to save',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _keyInputController.text.isEmpty
                        ? null
                        : () {
                            setState(() {
                              final key = _keyInputController.text.trim();
                              if (key.isNotEmpty && !_savedKeys.contains(key)) {
                                _savedKeys.add(key);
                                _keyInputController.clear();
                              }
                            });
                          },
                    child: Text('Add'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OPERATION HISTORY',
          style: TextStyle(
            color: Color(0xFF6B4EFF),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 15),
        _history.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'No history yet. Start using the app to see your operations here.',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final item = _history[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 15),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF2D2D2D) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Color(0xFF6B4EFF).withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black12
                              : Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.timestamp,
                              style: TextStyle(
                                color: Color(0xFF6B4EFF),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Time: ${item.timeSpent}',
                              style: TextStyle(
                                color: Color(0xFF6B4EFF),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        _buildHistoryItem('Operation:', item.operation),
                        _buildHistoryItem('Cipher Type:', item.cipherType),
                        _buildHistoryItem('Key:', item.key),
                        SizedBox(height: 8),
                        Text(
                          'ORIGINAL TEXT',
                          style: TextStyle(
                            color: Color(0xFF6B4EFF),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFF6B4EFF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.originalText,
                            style: TextStyle(
                              color: Color(0xFF6B4EFF),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'RESULT',
                          style: TextStyle(
                            color: Color(0xFF6B4EFF),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFF6B4EFF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.resultText,
                            style: TextStyle(
                              color: Color(0xFF6B4EFF),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildHistoryItem(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Color(0xFF6B4EFF),
              shape: BoxShape.circle,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 12,
            ),
          ),
          SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _keyInputController.dispose();
    super.dispose();
  }
}

class CipherScreen extends StatefulWidget {
  final String mode;
  final List<CipherHistory> history;
  final Function(List<CipherHistory>) onHistoryUpdate;

  const CipherScreen({
    super.key,
    required this.mode,
    required this.history,
    required this.onHistoryUpdate,
  });

  @override
  _CipherScreenState createState() => _CipherScreenState();
}

class _CipherScreenState extends State<CipherScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  String _selectedCipher = 'Caesar';
  String _result = '';
  List<Map<String, dynamic>> _results = []; // Changed from final to non-final
  List<CipherHistory> _history = [];
  bool _isDictionaryAttack = true;
  List<Map<String, dynamic>> _keyAttempts = [];
  List<Map<String, dynamic>> _dictionaryAttackResults = [];
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _keyInputController = TextEditingController();
  String _errorMessage = ''; // Add this variable

  @override
  void initState() {
    super.initState();
    _history = widget.history;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == 'encrypt' ? 'Encryption' : 'Decryption'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCipherSelector(),
              SizedBox(height: 20),
              _buildInputSection(),
              SizedBox(height: 20),
              _buildKeySection(),
              SizedBox(height: 20),
              _buildActionButton(),
              SizedBox(height: 20),
              if (_result.isNotEmpty) _buildResultSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCipherSelector() {
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
            Text(
              'Cipher Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCipher,
                  isExpanded: true,
                  dropdownColor: isDark ? Color(0xFF2D2D2D) : Colors.white,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: Theme.of(context).primaryColor,
                  ),
                  items:
                      ['Caesar', 'Vigenère', 'Rail Fence'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: TextStyle(
                          color: isDark ? Colors.white : Color(0xFF2D2D2D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCipher = newValue;
                        _results = [];
                      });
                    }
                  },
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              _getCipherDescription(_selectedCipher),
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.white60 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCipherDescription(String cipher) {
    switch (cipher) {
      case 'Caesar':
        return 'A substitution cipher where each letter is shifted by a fixed number of places.';
      case 'Vigenère':
        return 'A method of encrypting text by using a series of interwoven Caesar ciphers based on the letters of a keyword.';
      case 'Rail Fence':
        return 'A transposition cipher that arranges the plaintext in a zig-zag pattern across multiple "rails".';
      default:
        return '';
    }
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
                if (_textController.text.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear, size: 18),
                    onPressed: () {
                      setState(() {
                        _textController.clear();
                        _result = '';
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
                controller: _textController,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 15,
                ),
                maxLines: 5,
                minLines: 5,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: widget.mode == 'encrypt'
                      ? 'Enter text to encrypt...'
                      : 'Enter text to decrypt...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black38,
                  ),
                  contentPadding: EdgeInsets.all(12),
                ),
                onChanged: (text) {
                  // Clear results when input changes
                  if (_result.isNotEmpty) {
                    setState(() {
                      _result = '';
                    });
                  }
                },
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_textController.text.isNotEmpty)
                  Text(
                    'Characters: ${_textController.text.length}',
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

  Widget _buildKeySection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFF6B4EFF).withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _keyController,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: _selectedCipher == 'Caesar'
                  ? 'Enter shift (0-25)'
                  : _selectedCipher == 'Vigenère'
                      ? 'Enter keyword'
                      : 'Enter number of rails',
              hintStyle: TextStyle(
                color: isDark ? Colors.white54 : Colors.black38,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _processText,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
        child: Text(
          widget.mode == 'encrypt' ? 'ENCRYPT' : 'DECRYPT',
          style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFF6B4EFF).withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'RESULT',
            style: TextStyle(
              color: Color(0xFF6B4EFF),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 15),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _result));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Text copied to clipboard'),
                  duration: Duration(seconds: 1),
                  backgroundColor: Color(0xFF6B4EFF),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF6B4EFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _result,
                      style: TextStyle(color: Color(0xFF6B4EFF), fontSize: 16),
                    ),
                  ),
                  Icon(Icons.copy, size: 20, color: Color(0xFF6B4EFF)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _processText() {
    String text = _textController.text;
    String key = _keyController.text;

    if (text.isEmpty || key.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter both text and key')));
      return;
    }

    // Start timing
    final stopwatch = Stopwatch()..start();

    setState(() {
      switch (_selectedCipher) {
        case 'Caesar':
          _result = widget.mode == 'encrypt'
              ? _caesarEncrypt(text, int.tryParse(key) ?? 0)
              : _caesarDecrypt(text, int.tryParse(key) ?? 0);
          break;
        case 'Vigenère':
          _result = widget.mode == 'encrypt'
              ? _vigenereEncrypt(text, key)
              : _vigenereDecrypt(text, key);
          break;
        case 'Rail Fence':
          _result = widget.mode == 'encrypt'
              ? _railFenceEncrypt(text, int.tryParse(key) ?? 2)
              : _railFenceDecrypt(text, int.tryParse(key) ?? 2);
          break;
      }
    });

    // Stop timing and add to history
    stopwatch.stop();
    _history.insert(
      0,
      CipherHistory(
        timestamp: DateTime.now().toString().split('.')[0],
        operation: widget.mode == 'encrypt' ? 'Encrypt' : 'Decrypt',
        cipherType: _selectedCipher,
        key: key,
        originalText: text,
        resultText: _result,
        timeSpent: '${stopwatch.elapsed.inMilliseconds}ms',
        score: 0.0,
      ),
    );

    // Update parent's history
    widget.onHistoryUpdate(_history);
  }

  String _caesarEncrypt(String text, int shift) {
    return text.split('').map((char) {
      if (RegExp(r'[A-Za-z]').hasMatch(char)) {
        int base = char.codeUnitAt(0) <= 90 ? 65 : 97;
        return String.fromCharCode(
          (char.codeUnitAt(0) - base + shift) % 26 + base,
        );
      }
      return char;
    }).join('');
  }

  String _caesarDecrypt(String text, int shift) {
    return text.split('').map((char) {
      if (RegExp(r'[A-Za-z]').hasMatch(char)) {
        int base = char.codeUnitAt(0) <= 90 ? 65 : 97;
        return String.fromCharCode(
          (char.codeUnitAt(0) - base - shift + 26) % 26 + base,
        );
      }
      return char;
    }).join('');
  }

  String _vigenereEncrypt(String text, String key) {
    key = key.toLowerCase(); // Ensure key is lowercase for consistency
    String processedText = '';
    int keyIndex = 0;

    for (int i = 0; i < text.length; i++) {
      if (RegExp(r'[A-Za-z]').hasMatch(text[i])) {
        // Check if character is a letter
        int shift = key[keyIndex % key.length].codeUnitAt(0) -
            'a'.codeUnitAt(0); // key shift
        // No need to negate shift for encryption

        int charCode = text[i].codeUnitAt(0);
        if (charCode >= 'a'.codeUnitAt(0) && charCode <= 'z'.codeUnitAt(0)) {
          charCode = ((charCode - 'a'.codeUnitAt(0) + shift + 26) % 26) +
              'a'.codeUnitAt(0);
        } else {
          charCode = ((charCode - 'A'.codeUnitAt(0) + shift + 26) % 26) +
              'A'.codeUnitAt(0);
        }

        processedText += String.fromCharCode(charCode);
        keyIndex++;
      } else {
        processedText += text[i]; // Include non-letters unchanged
      }
    }
    return processedText;
  }

  String _vigenereDecrypt(String text, String key) {
    key = key.toLowerCase(); // Ensure key is lowercase for consistency
    String processedText = '';
    int keyIndex = 0;

    for (int i = 0; i < text.length; i++) {
      if (RegExp(r'[A-Za-z]').hasMatch(text[i])) {
        // Check if character is a letter
        int shift = key[keyIndex % key.length].codeUnitAt(0) -
            'a'.codeUnitAt(0); // key shift
        shift = -shift; // For decryption

        int charCode = text[i].codeUnitAt(0);
        if (charCode >= 'a'.codeUnitAt(0) && charCode <= 'z'.codeUnitAt(0)) {
          charCode = ((charCode - 'a'.codeUnitAt(0) + shift + 26) % 26) +
              'a'.codeUnitAt(0);
        } else {
          charCode = ((charCode - 'A'.codeUnitAt(0) + shift + 26) % 26) +
              'A'.codeUnitAt(0);
        }

        processedText += String.fromCharCode(charCode);
        keyIndex++;
      } else {
        processedText += text[i]; // Include non-letters unchanged
      }
    }
    return processedText;
  }

  String _railFenceEncrypt(String text, int rails) {
    if (rails < 2) return text;

    List<List<String>> matrix = List.generate(
      rails,
      (_) => List.filled(text.length, ''),
    );
    int row = 0;
    int col = 0;
    bool goingDown = true;

    for (int i = 0; i < text.length; i++) {
      matrix[row][col] = text[i];
      col++;

      if (goingDown) {
        row++;
        if (row == rails - 1) goingDown = false;
      } else {
        row--;
        if (row == 0) goingDown = true;
      }
    }

    StringBuffer encrypted = StringBuffer();
    for (int i = 0; i < rails; i++) {
      for (int j = 0; j < text.length; j++) {
        if (matrix[i][j].isNotEmpty) {
          encrypted.write(matrix[i][j]);
        }
      }
    }
    return encrypted.toString();
  }

  String _railFenceDecrypt(String text, int rails) {
    if (rails < 2 || text.isEmpty) return text;

    final fence =
        List.generate(rails, (_) => List<String>.filled(text.length, ''));

    // Calculate zigzag pattern
    int row = 0;
    int direction = 1;
    List<int> railPositions = [];

    for (int i = 0; i < text.length; i++) {
      railPositions.add(row);
      row += direction;
      if (row == 0 || row == rails - 1) {
        direction = -direction;
      }
    }

    // Fill fence with text
    Map<int, List<int>> railIndices = {};
    for (int i = 0; i < rails; i++) {
      railIndices[i] = [];
    }

    for (int i = 0; i < text.length; i++) {
      railIndices[railPositions[i]]!.add(i);
    }

    int textIndex = 0;
    List<String> result = List.filled(text.length, '');

    for (int r = 0; r < rails; r++) {
      for (int pos in railIndices[r]!) {
        result[pos] = text[textIndex++];
      }
    }

    return result.join('');
  }
}

class CipherDetector extends StatefulWidget {
  final List<CipherHistory> history;
  final Function(List<CipherHistory>) onHistoryUpdate;
  final List<String> savedKeys;
  final Function(List<String>) onSavedKeysUpdate; // Add callback for saved keys

  const CipherDetector({
    Key? key,
    required this.history,
    required this.onHistoryUpdate,
    this.savedKeys = const [],
    required this.onSavedKeysUpdate, // Required callback
  }) : super(key: key);

  @override
  _CipherDetectorState createState() => _CipherDetectorState();
}

class _CipherDetectorState extends State<CipherDetector> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _keyInputController = TextEditingController();
  String _selectedCipher = 'Vigenère';
  bool _isLoading = false;
  String _errorMessage = '';
  double _progressValue = 0.0;
  List<String> _detectedCiphers = [];
  List<Map<String, dynamic>> _results = []; // Changed from final to non-final
  List<String> _blacklist = [];
  bool _isDictionaryAttack = true;
  List<Map<String, dynamic>> _history = [];
  List<String> _savedKeys = [];

  @override
  void initState() {
    super.initState();
    _savedKeys = List.from(widget.savedKeys);
    _loadBlacklist();
    _loadHistory();
    _loadDictionary();
    _controller.text = '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('Cipher Cracking'),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                SizedBox(height: 20),
                _buildCipherSelector(),
                SizedBox(height: 20),
                _buildInputSection(),
                SizedBox(height: 20),
                _buildAnalyzeButton(),
                SizedBox(height: 20),
                if (_isLoading) _buildProgressIndicator(),
                if (_results.isNotEmpty) _buildResults(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build the header section with toggle button
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
              'Cryptanalysis Tool',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Enter encrypted text below and choose a cipher type to attempt decryption.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(width: 8),
                Text(
                  'Dictionary Attack:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Spacer(),
                Switch(
                  value: _isDictionaryAttack,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _isDictionaryAttack = value;
                    });
                  },
                ),
              ],
            ),
            if (_isDictionaryAttack)
              Padding(
                padding: const EdgeInsets.only(left: 26.0),
                child: Text(
                  'Using common words as potential keys for faster decryption',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white60 : Colors.black45,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Build the cipher selector dropdown
  Widget _buildCipherSelector() {
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
            Text(
              'Cipher Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCipher,
                  isExpanded: true,
                  dropdownColor: isDark ? Color(0xFF2D2D2D) : Colors.white,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: Theme.of(context).primaryColor,
                  ),
                  items:
                      ['Caesar', 'Vigenère', 'Rail Fence'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: TextStyle(
                          color: isDark ? Colors.white : Color(0xFF2D2D2D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCipher = newValue;
                        _results = [];
                      });
                    }
                  },
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              _getCipherDescription(_selectedCipher),
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.white60 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCipherDescription(String cipher) {
    switch (cipher) {
      case 'Caesar':
        return 'A substitution cipher where each letter is shifted by a fixed number of places.';
      case 'Vigenère':
        return 'A method of encrypting text by using a series of interwoven Caesar ciphers based on the letters of a keyword.';
      case 'Rail Fence':
        return 'A transposition cipher that arranges the plaintext in a zig-zag pattern across multiple "rails".';
      default:
        return '';
    }
  }

  // Build the input section
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
                if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear, size: 18),
                    onPressed: () {
                      setState(() {
                        _controller.clear();
                        _results = [];
                        _errorMessage = '';
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
                controller: _controller,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 15,
                ),
                maxLines: 5,
                minLines: 5,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter ciphertext to analyze...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black38,
                  ),
                  contentPadding: EdgeInsets.all(12),
                ),
                onChanged: (text) {
                  // Ensure state updates when text changes to enable/disable button
                  setState(() {
                    if (_results.isNotEmpty) {
                      _results = [];
                    }
                  });
                },
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_controller.text.isNotEmpty)
                  Text(
                    'Characters: ${_controller.text.length}',
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

  // Build the analyze button
  Widget _buildAnalyzeButton() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _controller.text.isEmpty ? null : _analyzeText,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoading)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    if (_isLoading) SizedBox(width: 12),
                    Text(
                      _isLoading ? 'Analyzing...' : 'Analyze Text',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading) ...[
              SizedBox(height: 16),
              LinearProgressIndicator(
                value: _progressValue > 0 ? _progressValue : null,
                backgroundColor: Colors.grey[200],
              ),
              SizedBox(height: 12),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                ),
              ),
            ],
            if (!_isLoading && _errorMessage.isNotEmpty) ...[
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _results.isNotEmpty
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _results.isNotEmpty
                        ? Colors.green[700]
                        : Colors.red[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Build loading indicator with progress
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
            LoadingAnimationWrapper(
              size: 60.0,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(height: 16),
            Text(
              _errorMessage.isEmpty
                  ? 'Analyzing text with $_selectedCipher cipher...'
                  : _errorMessage,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progressValue,
              color: Theme.of(context).primaryColor,
            ),
            if (_progressValue > 0) ...[
              SizedBox(height: 8),
              Text(
                '${(_progressValue * 100).toInt()}%',
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

  // Build results section
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
            Text(
              'Results',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 16),
            if (_results.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'No results found. Try another cipher type or input text.',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_results.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final result = _results[index];
                  final bool isBestMatch = index == 0;
                  final bool isSavedKey =
                      _savedKeys.contains(result['key'].toString());

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
                      subtitle: Text(
                        'Score: ${result['score'].toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
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
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
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
                                      setState(() {
                                        final key = result['key'].toString();
                                        if (isSavedKey) {
                                          _savedKeys.remove(key);
                                        } else {
                                          _savedKeys.add(key);
                                        }
                                        widget.onSavedKeysUpdate(_savedKeys);
                                      });
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

  // Helper method to get score color
  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green[700]!;
    if (score >= 60) return Colors.green[400]!;
    if (score >= 40) return Colors.orange[400]!;
    if (score >= 20) return Colors.orange[700]!;
    return Colors.red[400]!;
  }

  void _analyzeText() async {
    final text = _controller.text.trim();

    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter text to analyze';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _progressValue = 0.0;
      _results = [];
    });

    List<Map<String, dynamic>> analysisResults = [];

    switch (_selectedCipher) {
      case 'Caesar':
        // Try all possible Caesar shifts (0-25)
        for (int shift = 0; shift < 26; shift++) {
          String decrypted = text.split('').map((char) {
            if (RegExp(r'[A-Za-z]').hasMatch(char)) {
              int base = char.codeUnitAt(0) <= 90 ? 65 : 97;
              return String.fromCharCode(
                (char.codeUnitAt(0) - base - shift + 26) % 26 + base,
              );
            }
            return char;
          }).join('');

          double score = _calculateReadabilityScore(decrypted);

          if (score > 0.15) {
            // Only include reasonable results
            analysisResults.add({
              'key': shift.toString(),
              'decrypted': decrypted,
              'score': score * 100,
              'method': 'Caesar Shift'
            });
          }
        }
        break;

      case 'Vigenère':
        // First try dictionary attack if enabled
        if (_isDictionaryAttack) {
          final dictionaryResults = await _runDictionaryAttack(text);
          analysisResults.addAll(dictionaryResults);
        }

        // If no results or dictionary attack is disabled, try some common keys
        if (analysisResults.isEmpty) {
          List<String> commonKeys = [
            'a',
            'ab',
            'key',
            'test',
            'code',
            'hello',
            'secret'
          ];
          for (final key in commonKeys) {
            // Apply Vigenère decryption with this key
            String decrypted = _applyVigenereDecryption(text, key);
            double score = _calculateReadabilityScore(decrypted);

            if (score > 0.25) {
              // Threshold for considering a result
              analysisResults.add({
                'key': key,
                'decrypted': decrypted,
                'score': score * 100,
                'method': 'Common Keys'
              });
            }
          }
        }
        break;

      case 'Rail Fence':
        // Try different rail counts from 2 to 10
        for (int rails = 2; rails <= min(10, text.length / 2); rails++) {
          // Apply Rail Fence decryption with this rail count
          String decrypted = _applyRailFenceDecryption(text, rails);
          double score = _calculateReadabilityScore(decrypted);

          if (score > 0.2) {
            // Threshold for considering a result
            analysisResults.add({
              'key': rails.toString(),
              'decrypted': decrypted,
              'score': score * 100,
              'method': 'Rail Fence'
            });
          }
        }
        break;
    }

    // Sort results by score
    analysisResults.sort((a, b) => b['score'].compareTo(a['score']));

    // Take top 5 results
    final topResults = analysisResults.take(5).toList();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _results = topResults;
    });

    // Add to history if we found a good result
    if (_results.isNotEmpty && _results.first['score'] > 50) {
      _addToHistory(_results.first);
    }
  }

  // Helper method for Vigenère decryption
  String _applyVigenereDecryption(String text, String key) {
    key = key.toLowerCase(); // Ensure key is lowercase for consistency
    String processedText = '';
    int keyIndex = 0;

    for (int i = 0; i < text.length; i++) {
      if (RegExp(r'[A-Za-z]').hasMatch(text[i])) {
        // Check if character is a letter
        int shift = key[keyIndex % key.length].codeUnitAt(0) -
            'a'.codeUnitAt(0); // key shift
        shift = -shift; // For decryption

        int charCode = text[i].codeUnitAt(0);
        if (charCode >= 'a'.codeUnitAt(0) && charCode <= 'z'.codeUnitAt(0)) {
          charCode = ((charCode - 'a'.codeUnitAt(0) + shift + 26) % 26) +
              'a'.codeUnitAt(0);
        } else {
          charCode = ((charCode - 'A'.codeUnitAt(0) + shift + 26) % 26) +
              'A'.codeUnitAt(0);
        }

        processedText += String.fromCharCode(charCode);
        keyIndex++;
      } else {
        processedText += text[i]; // Include non-letters unchanged
      }
    }
    return processedText;
  }

  // Helper method for Rail Fence decryption
  String _applyRailFenceDecryption(String text, int rails) {
    if (rails < 2 || text.isEmpty) return text;

    // Calculate the pattern first (which rows get which positions)
    List<List<int>> pattern = List.generate(rails, (row) => []);
    int row = 0;
    int direction = 1;
    List<int> railPositions = [];

    for (int i = 0; i < text.length; i++) {
      railPositions.add(row);
      row += direction;

      // Change direction when we hit the top or bottom rail
      if (row == 0 || row == rails - 1) {
        direction = -direction;
      }
    }

    // Fill fence with text
    Map<int, List<int>> railIndices = {};
    for (int i = 0; i < rails; i++) {
      railIndices[i] = [];
    }

    for (int i = 0; i < text.length; i++) {
      railIndices[railPositions[i]]!.add(i);
    }

    int textIndex = 0;
    List<String> result = List.filled(text.length, '');

    for (int r = 0; r < rails; r++) {
      for (int pos in railIndices[r]!) {
        result[pos] = text[textIndex++];
      }
    }

    return result.join('');
  }

  // Calculate a readability score for the text
  double _calculateReadabilityScore(String text) {
    if (text.isEmpty) return 0.0;

    // Common English words for frequent bigrams and trigrams
    final commonEnglishWords = {
      'the',
      'and',
      'that',
      'have',
      'for',
      'not',
      'with',
      'you',
      'this',
      'but',
      'his',
      'from',
      'they',
      'say',
      'she',
      'will',
      'one',
      'all',
      'would',
      'there',
      'their',
      'what',
      'out',
      'about',
      'who',
      'get',
      'which',
      'when',
      'make',
      'can',
      'like',
      'time',
      'just',
      'him',
      'know',
      'take',
      'people',
      'into',
      'year',
      'your',
      'good',
      'some',
      'could',
      'them',
      'see',
      'other',
      'than',
      'then',
      'now',
      'look',
      'only',
      'come',
      'its',
      'over',
      'think',
      'also',
      'back',
      'after',
      'use',
      'two',
      'how',
      'our',
      'work',
      'first',
      'well',
      'way',
      'even',
      'new',
      'want',
      'because',
      'any',
      'these',
      'give',
      'day',
      'most',
      'been',
      'very',
      'was',
      'has',
      'had',
      'are',
      'were',
      'being',
    };

    // Common English bigrams
    final commonBigrams = [
      'th',
      'he',
      'in',
      'er',
      'an',
      're',
      'on',
      'at',
      'en',
      'nd',
      'ti',
      'es',
      'or',
      'te',
      'of',
      'ed',
      'is',
      'it',
      'al',
      'ar',
      'st',
      'to',
      'nt',
      'ng',
      'se',
      'ha',
      'as',
      'ou',
      'io',
      'le',
      'co',
      'me',
      'de',
      'hi',
      'ri',
      'ro',
      'ic',
      'ne',
      'ea',
      'ra',
      've',
      'ld',
      'ur',
      'be',
      'ay',
      'ow',
      'ma',
      'be',
      'si',
      'in',
    ];

    // Common English trigrams
    final commonTrigrams = [
      'the',
      'and',
      'ing',
      'ion',
      'tio',
      'ent',
      'ati',
      'for',
      'her',
      'ter',
      'hat',
      'tha',
      'ere',
      'ate',
      'his',
      'con',
      'res',
      'ver',
      'all',
      'ons',
      'nce',
      'men',
      'ith',
      'ted',
      'ers',
      'pro',
      'thi',
      'wit',
      'are',
      'ess',
      'not',
      'ive',
      'was',
      'ect',
      'rea',
      'com',
      'eve',
      'per',
      'int',
      'est',
      'sta',
      'cti',
      'ica',
      'ist',
      'ear',
      'ain',
      'one',
      'our',
    ];

    // Letter frequency in English (source: Wikipedia)
    final englishLetterFrequency = {
      'e': 12.02,
      't': 9.10,
      'a': 8.12,
      'o': 7.68,
      'i': 7.31,
      'n': 6.95,
      's': 6.28,
      'r': 6.02,
      'h': 5.92,
      'd': 4.32,
      'l': 3.98,
      'u': 2.88,
      'c': 2.71,
      'm': 2.61,
      'f': 2.30,
      'y': 2.11,
      'w': 2.09,
      'g': 2.03,
      'p': 1.82,
      'b': 1.49,
      'v': 1.11,
      'k': 0.69,
      'x': 0.17,
      'q': 0.11,
      'j': 0.10,
      'z': 0.07
    };

    // Convert text to lowercase for analysis
    final String cleanText = text.toLowerCase();

    // Split the text into words and count how many are in our common words list
    final List<String> words = cleanText
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) return 0.0;

    // Count common words
    int commonWordCount = 0;
    for (final word in words) {
      if (commonEnglishWords.contains(word)) {
        commonWordCount++;
      }
    }

    // Calculate word score
    double wordScore = words.isEmpty ? 0.0 : commonWordCount / words.length;

    // Calculate bigram and trigram scores
    int bigramMatches = 0;
    int totalBigrams = 0;

    int trigramMatches = 0;
    int totalTrigrams = 0;

    // Check for bigrams
    for (int i = 0; i < cleanText.length - 1; i++) {
      final String bigram = cleanText.substring(i, i + 2);
      if (RegExp(r'^[a-z]{2}$').hasMatch(bigram)) {
        totalBigrams++;
        if (commonBigrams.contains(bigram)) {
          bigramMatches++;
        }
      }
    }

    // Check for trigrams
    for (int i = 0; i < cleanText.length - 2; i++) {
      final String trigram = cleanText.substring(i, i + 3);
      if (RegExp(r'^[a-z]{3}$').hasMatch(trigram)) {
        totalTrigrams++;
        if (commonTrigrams.contains(trigram)) {
          trigramMatches++;
        }
      }
    }

    double bigramScore = totalBigrams > 0 ? bigramMatches / totalBigrams : 0.0;
    double trigramScore =
        totalTrigrams > 0 ? trigramMatches / totalTrigrams : 0.0;

    // Calculate letter frequency score
    Map<String, int> letterCounts = {};
    int totalLetters = 0;

    for (int i = 0; i < cleanText.length; i++) {
      String char = cleanText[i];
      if (RegExp(r'[a-z]').hasMatch(char)) {
        letterCounts[char] = (letterCounts[char] ?? 0) + 1;
        totalLetters++;
      }
    }

    double letterFrequencyScore = 0.0;
    if (totalLetters > 0) {
      double freqDiffSum = 0.0;
      for (var entry in letterCounts.entries) {
        double actualFreq = (entry.value / totalLetters) * 100;
        double expectedFreq = englishLetterFrequency[entry.key] ?? 0.0;
        freqDiffSum +=
            (1.0 - (actualFreq - expectedFreq).abs() / 12.0).clamp(0.0, 1.0);
      }
      letterFrequencyScore = letterCounts.isEmpty ? 0.0 : freqDiffSum / 26.0;
    }

    // Check for repeated characters (indication of non-meaningful text)
    int repeats = 0;
    for (int i = 0; i < cleanText.length - 3; i++) {
      if (cleanText[i] == cleanText[i + 1] &&
          cleanText[i] == cleanText[i + 2] &&
          cleanText[i] == cleanText[i + 3]) {
        repeats++;
      }
    }
    double repeatPenalty =
        repeats > 0 ? 1.0 - (repeats / cleanText.length).clamp(0.0, 0.5) : 1.0;

    // Calculate space ratio (meaningful text typically has about 1 space per 5-6 characters)
    int spaceCount = text.split(' ').length - 1;
    double spaceRatio = spaceCount / text.length;
    double spaceScore = 1.0 - (spaceRatio - 0.17).abs() / 0.17;
    spaceScore = spaceScore.clamp(0.0, 1.0);

    // Combine all scores with appropriate weights
    final double combinedScore =
        (wordScore * 0.40 + // Common words are a strong indicator
            bigramScore * 0.15 + // Bigram frequency
            trigramScore * 0.15 + // Trigram frequency
            letterFrequencyScore * 0.15 + // Letter frequency
            spaceScore * 0.05 + // Space distribution
            repeatPenalty * 0.10 // Penalty for repeating characters
        );

    return combinedScore.clamp(0.0, 1.0);
  }

  // Add result to history
  void _addToHistory(Map<String, dynamic> result) {
    widget.history.insert(
      0,
      CipherHistory(
        timestamp: DateTime.now().toString().split('.')[0],
        operation: 'Crack',
        cipherType: _selectedCipher,
        key: result['key'],
        originalText: _controller.text.trim(),
        resultText: result['decrypted'] ?? '',
        timeSpent: 'N/A',
        score: result['score'],
      ),
    );

    // Update parent's history
    widget.onHistoryUpdate(widget.history);
  }

  // Load blacklist from storage
  Future<void> _loadBlacklist() async {
    // In a real app, you would load this from SharedPreferences or a database
    _blacklist = ['badkey1', 'badkey2']; // Example blacklist
  }

  // Load history from storage
  Future<void> _loadHistory() async {
    // In a real app, you would load this from SharedPreferences or a database
    _history = widget.history
        .map((item) => {
              'key': item.key,
              'decrypted': item.resultText,
              'score': item.score,
            })
        .toList();
  }

  // Load dictionary words from asset
  Future<List<String>> _loadDictionary() async {
    // Try to load from assets first
    try {
      final String data = await rootBundle.loadString('assets/dictionary.txt');
      List<String> dictionary = data
          .split('\n')
          .map((word) => word.trim())
          .where((word) => word.isNotEmpty)
          .toList();

      if (dictionary.isNotEmpty) {
        print('Loaded ${dictionary.length} words from dictionary.txt');
        return dictionary;
      }
    } catch (e) {
      print('Error loading dictionary from assets: $e');
    }

    // Fallback to hard-coded list if asset loading failed
    print('Using built-in dictionary');
    return [
      // Common short words
      'the', 'and', 'for', 'are', 'but', 'not', 'you', 'all', 'any', 'can',
      'had', 'her', 'was', 'one',
      'our', 'out', 'day', 'get', 'has', 'him', 'his', 'how', 'man', 'new',
      'now', 'old', 'see', 'two',
      'way', 'who', 'boy', 'did', 'its', 'let', 'put', 'say', 'she', 'too',
      'use', 'that', 'with', 'have',
      'this', 'will', 'your', 'from', 'they', 'been', 'call', 'each', 'find',
      'grow', 'here', 'keep',
      // Common encryption terms
      'key', 'code', 'data', 'text', 'hash', 'salt', 'bits', 'byte', 'file',
      'type', 'mode', 'sign', 'seed',
      'word', 'block', 'chain', 'cipher', 'crypt', 'secret', 'secure', 'decode',
      'encode', 'public',
      'private', 'encrypt', 'decrypt', 'message', 'password', 'plaintext',
      'cleartext', 'ciphertext',
      // Common crypto algorithms
      'aes', 'des', 'rsa', 'md5', 'sha', 'pgp', 'ssl', 'tls', 'dsa', 'otp',
      'hmac', 'ecdsa',
      // People names
      'john', 'jane', 'mary', 'mike', 'dave', 'anna', 'james', 'sarah', 'david',
      'laura', 'kevin', 'lisa',
      // Tech terms
      'app', 'web', 'api', 'gui', 'url', 'xml', 'json', 'html', 'http', 'java',
      'perl', 'ruby', 'rust',
      'dart', 'go', 'php', 'sql', 'node', 'code', 'font', 'link', 'site',
      'page', 'user', 'data', 'test',
      'beta', 'blog', 'byte', 'chat', 'demo', 'disk', 'file', 'hack', 'icon',
      'info', 'ping', 'port',
      'post', 'root', 'spam', 'sync', 'unix', 'wiki', 'open', 'deep', 'auto',
      'core', 'host', 'loop',
      'main', 'path', 'time', 'auth', 'blog', 'case', 'copy', 'echo', 'eval',
      'exec', 'fail', 'fork',
      'free', 'full', 'func', 'goto', 'heap', 'help', 'hide', 'high', 'home',
      'hook', 'init', 'join',
      'kill', 'lang', 'leak', 'line', 'list', 'load', 'lock', 'logs', 'long',
      'loop', 'mail', 'make',
      'mark', 'meta', 'mode', 'name', 'null', 'open', 'over', 'page', 'pass',
      'path', 'perl', 'pipe',
      'poll', 'pool', 'port', 'read', 'real', 'redo', 'rest', 'ruby', 'rule',
      'save', 'scan', 'seed',
      'seek', 'self', 'send', 'site', 'size', 'skip', 'soft', 'sort', 'spam',
      'task', 'team', 'temp',
      'term', 'test', 'text', 'time', 'tool', 'true', 'type', 'undo', 'unix',
      'user', 'view', 'wait',
      'wake', 'warn', 'wrap', 'zero',
      // Vigenere specific words
      'hello', 'world', 'vigenere', 'cipher', 'tabula', 'recta', 'enigma',
      'blaise', 'porta', 'frequency',
      'analysis', 'kasiski', 'examination', 'running', 'autokey', 'beaufort',
      'variant', 'polyalphabetic',
      'substitution',
      // Other common passwords
      'admin', 'guest', 'qwerty', 'letmein', 'welcome', 'monkey', 'dragon',
      'shadow', 'master', 'football',
      'baseball', 'superman', 'batman', 'trustno1', 'sunshine', 'iloveyou',
      'princess', 'starwars',
    ];
  }

  // Method to run dictionary attack
  Future<List<Map<String, dynamic>>> _runDictionaryAttack(String text) async {
    List<Map<String, dynamic>> results = [];
    try {
      if (_isDictionaryAttack) {
        // Run dictionary attack code
        setState(() {
          _isLoading = true;
          _progressValue = 0.0;
          _errorMessage = 'Preparing dictionary attack...';
        });

        // First try with saved keys if available
        if (_savedKeys.isNotEmpty) {
          setState(() {
            _errorMessage = 'Checking saved keys...';
          });

          for (final key in _savedKeys) {
            // Skip blacklisted keys
            if (_blacklist.contains(key)) continue;

            // Decrypt with this key
            String decrypted = _applyVigenereDecryption(text, key);

            // Calculate readability score
            double score = _calculateReadabilityScore(decrypted);

            // Add to results regardless of score since it's a saved key
            results.add({
              'key': key,
              'decrypted': decrypted,
              'score': score * 100,
              'method': 'Saved Key'
            });

            // Update UI for user feedback
            if (mounted) {
              setState(() {
                _errorMessage = 'Checked saved key: $key';
              });
              await Future.delayed(Duration(milliseconds: 100));
            }
          }
        }

        // Load dictionary words
        List<String> dictionary = await _loadDictionary();

        // Add best potential candidates to the words list
        dictionary = [
          ...dictionary,
          'hello',
          'world',
          'password',
          'secret',
          'vigenere',
          'cipher',
          'key',
          'code',
          'crypto',
          'python',
          'java',
          'dart',
          'android',
          'apple',
          'google',
          'flutter',
          'mobile',
          'security',
          'encrypt',
          'decrypt',
        ];

        int totalWords = dictionary.length;
        int processedWords = 0;
        int successfulWords = 0;

        // Try each dictionary word as a potential key
        for (final word in dictionary) {
          // Skip already processed saved keys and blacklisted words
          if (_savedKeys.contains(word) || _blacklist.contains(word)) {
            processedWords++;
            continue;
          }

          // Update the UI periodically to show progress
          if (processedWords % 5 == 0 && mounted) {
            setState(() {
              _progressValue = processedWords / totalWords;
              _errorMessage =
                  'Testing key: $word (${(processedWords * 100 ~/ totalWords)}%)';
            });
            // Brief delay to allow UI updates
            await Future.delayed(Duration(milliseconds: 1));
          }

          // Actually decrypt with this key
          String decrypted = _applyVigenereDecryption(text, word);

          // Calculate readability score
          double score = _calculateReadabilityScore(decrypted);

          // Only add results with reasonable readability
          if (score > 0.2) {
            successfulWords++;
            results.add({
              'key': word,
              'decrypted': decrypted,
              'score': score * 100,
              'method': 'Dictionary Attack'
            });

            // Show promising candidates in real-time
            if (score > 0.3 && mounted) {
              setState(() {
                _errorMessage =
                    'Found potential key: $word (Score: ${(score * 100).toStringAsFixed(1)}%)';
              });
            }
          }

          processedWords++;
        }

        // Clear status message and finish progress
        if (mounted) {
          setState(() {
            _progressValue = 1.0;
            _errorMessage = successfulWords > 0
                ? 'Found $successfulWords potential keys'
                : 'No suitable keys found in dictionary';
          });
        }

        // Sort results by score
        results.sort((a, b) => b['score'].compareTo(a['score']));

        // Take top 5 results
        if (results.length > 5) {
          results = results.sublist(0, 5);
        }
      }
    } catch (e) {
      print('Error in dictionary attack: $e');
      if (mounted) {
        setState(() {
          _progressValue = 0.0;
          _errorMessage = 'Error during dictionary attack: $e';
        });
      }
    }
    return results;
  }

  // Add this method to _CipherDetectorState class
  void _updateSavedKeys() {
    widget.onSavedKeysUpdate(_savedKeys);
  }

  // Add the helper method for score icons at the end of the _CipherDetectorState class
  // Helper method to get score icon
  IconData _getScoreIcon(double score) {
    if (score >= 80) return Icons.verified;
    if (score >= 60) return Icons.thumb_up;
    if (score >= 40) return Icons.thumbs_up_down;
    if (score >= 20) return Icons.help_outline;
    return Icons.thumb_down;
  }
}
