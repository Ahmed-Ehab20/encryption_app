import 'package:flutter/material.dart';
import 'loading_animation.dart';

void main() {
  runApp(TestLoadingApp());
}

class TestLoadingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loading Animation Test',
      theme: ThemeData(
        primaryColor: Color(0xFF6B4EFF),
        colorScheme: ColorScheme.light(
          primary: Color(0xFF6B4EFF),
          secondary: Color(0xFF00D9DA),
        ),
      ),
      home: TestLoadingScreen(),
    );
  }
}

class TestLoadingScreen extends StatefulWidget {
  @override
  _TestLoadingScreenState createState() => _TestLoadingScreenState();
}

class _TestLoadingScreenState extends State<TestLoadingScreen> {
  bool _isLoading = true;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  void _simulateLoading() {
    Future.delayed(Duration(seconds: 1), () {
      _updateProgress(0.2);
      Future.delayed(Duration(seconds: 1), () {
        _updateProgress(0.4);
        Future.delayed(Duration(seconds: 1), () {
          _updateProgress(0.6);
          Future.delayed(Duration(seconds: 1), () {
            _updateProgress(0.8);
            Future.delayed(Duration(seconds: 1), () {
              _updateProgress(1.0);
              Future.delayed(Duration(seconds: 1), () {
                setState(() {
                  _isLoading = false;
                });
              });
            });
          });
        });
      });
    });
  }

  void _updateProgress(double value) {
    setState(() {
      _progress = value;
    });
  }

  void _startLoading() {
    setState(() {
      _isLoading = true;
      _progress = 0.0;
    });
    _simulateLoading();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Loading Animation Test'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) ...[
                LoadingAnimation(
                  size: 100.0,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(height: 24),
                Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor),
                ),
                SizedBox(height: 8),
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 80,
                ),
                SizedBox(height: 24),
                Text(
                  'Loading Complete!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _startLoading,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: Text(
                      'Start Loading Again',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
