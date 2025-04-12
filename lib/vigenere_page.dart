import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'improved_vigenere.dart';
import 'improved_vigenere_attack.dart';
import 'enhanced_vigenere_page.dart';

/// A complete page for Vigenère cipher operations including:
/// - Encryption
/// - Decryption
/// - Dictionary Attack
class VigenerePage extends StatefulWidget {
  const VigenerePage({Key? key}) : super(key: key);

  @override
  State<VigenerePage> createState() => _VigenerePageState();
}

class _VigenerePageState extends State<VigenerePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vigenère Cipher'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.lock), text: 'Encrypt'),
            Tab(icon: Icon(Icons.lock_open), text: 'Decrypt'),
            Tab(icon: Icon(Icons.security), text: 'Attack'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          EncryptTab(),
          DecryptTab(),
          AttackTab(),
        ],
      ),
    );
  }
}

/// Tab for encrypting text with Vigenère cipher
class EncryptTab extends StatefulWidget {
  @override
  _EncryptTabState createState() => _EncryptTabState();
}

class _EncryptTabState extends State<EncryptTab> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  String _result = '';
  String _errorMessage = '';

  void _encrypt() {
    final text = _textController.text.trim();
    final key = _keyController.text.trim();

    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter text to encrypt';
        _result = '';
      });
      return;
    }

    if (key.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an encryption key';
        _result = '';
      });
      return;
    }

    try {
      final encrypted = VigenereUtil.encrypt(text, key);
      setState(() {
        _result = encrypted;
        _errorMessage = '';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _result = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              labelText: 'Text to Encrypt',
              border: OutlineInputBorder(),
              hintText: 'Enter your plaintext here',
            ),
            maxLines: 4,
          ),
          SizedBox(height: 16),
          TextField(
            controller: _keyController,
            decoration: InputDecoration(
              labelText: 'Encryption Key',
              border: OutlineInputBorder(),
              hintText: 'Enter key (letters only)',
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            icon: Icon(Icons.lock),
            label: Text('Encrypt'),
            onPressed: _encrypt,
          ),
          SizedBox(height: 24),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
              ),
            ),
          if (_result.isNotEmpty) ...[
            Text(
              'Encrypted Result:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withOpacity(0.8)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.3)
                      : Colors.black.withOpacity(0.2),
                ),
              ),
              child: Text(
                _result,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.copy),
              label: Text('Copy to Clipboard'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _result));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// Tab for decrypting text with Vigenère cipher
class DecryptTab extends StatefulWidget {
  @override
  _DecryptTabState createState() => _DecryptTabState();
}

class _DecryptTabState extends State<DecryptTab> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  String _result = '';
  String _errorMessage = '';

  void _decrypt() {
    final text = _textController.text.trim();
    final key = _keyController.text.trim();

    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter text to decrypt';
        _result = '';
      });
      return;
    }

    if (key.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a decryption key';
        _result = '';
      });
      return;
    }

    try {
      final decrypted = VigenereUtil.decrypt(text, key);
      setState(() {
        _result = decrypted;
        _errorMessage = '';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _result = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              labelText: 'Text to Decrypt',
              border: OutlineInputBorder(),
              hintText: 'Enter encrypted text here',
            ),
            maxLines: 4,
          ),
          SizedBox(height: 16),
          TextField(
            controller: _keyController,
            decoration: InputDecoration(
              labelText: 'Decryption Key',
              border: OutlineInputBorder(),
              hintText: 'Enter key (letters only)',
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            icon: Icon(Icons.lock_open),
            label: Text('Decrypt'),
            onPressed: _decrypt,
          ),
          SizedBox(height: 24),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
              ),
            ),
          if (_result.isNotEmpty) ...[
            Text(
              'Decrypted Result:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.9) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.6)
                      : Colors.black.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Text(
                _result,
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
            ElevatedButton.icon(
              icon: Icon(Icons.copy),
              label: Text('Copy to Clipboard'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _result));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// Tab for attacking Vigenère cipher
class AttackTab extends StatefulWidget {
  @override
  _AttackTabState createState() => _AttackTabState();
}

class _AttackTabState extends State<AttackTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Enhanced cracker for short texts
          Card(
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
                      Icon(
                        Icons.psychology,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Enhanced Vigenère Cracking',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      Spacer(),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'New',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Optimized for short texts (1-2 sentences) with selectable analysis methods',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Only allows one cracking method at a time for better performance\n'
                    '• Includes methods like Key Length Analysis, Dictionary Attack, and more\n'
                    '• Especially effective for shorter ciphertexts',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white60
                          : Colors.black45,
                    ),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.bolt),
                      label: Text('Open Enhanced Cracker'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EnhancedVigenerePage(
                              savedKeys: [], // Pass saved keys if available
                              onSavedKeysUpdate: (newKeys) {
                                // Handle saved keys update if needed
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),

          // Traditional attack methods
          Card(
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
                    'Traditional Attack Methods',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Full-featured Vigenère cryptanalysis with various attack methods',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
                    ),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.security),
                      label: Text('Open Traditional Cracker'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImprovedVigenereAttackPage(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A page for a specific attack method
class MethodSpecificAttackPage extends StatelessWidget {
  final VigenereAttackMethod method;

  const MethodSpecificAttackPage({Key? key, required this.method})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${method.displayName}'),
      ),
      body: VigenereAttackWidget(
        dictionaryAssetPath: 'lib/dictionary.txt',
      ),
    );
  }
}
