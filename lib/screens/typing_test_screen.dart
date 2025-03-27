import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:typedojo/models/settings_model.dart';
import 'package:typedojo/models/typing_test_service.dart';
import 'package:typedojo/screens/results_screen.dart';

class TypingTestScreen extends StatefulWidget {
  const TypingTestScreen({super.key});

  @override
  State<TypingTestScreen> createState() => _TypingTestScreenState();
}

class _TypingTestScreenState extends State<TypingTestScreen> {
  final TextEditingController _textController = TextEditingController();
  late TypingTestService _testService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTest();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    if (_testService.isTestActive) {
      _testService.endTest();
    }
    super.dispose();
  }

  Future<void> _initializeTest() async {
    final settings = Provider.of<SettingsModel>(context, listen: false);
    _testService = Provider.of<TypingTestService>(context, listen: false);
    await _testService.initialize(settings);
    _testService.resetTest();
    
    setState(() {
      _isInitialized = true;
    });
  }

  void _startTest() {
    final settings = Provider.of<SettingsModel>(context, listen: false);
    _textController.clear();
    _testService.startTest(settings.durationInSeconds);
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Typing Test'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Consumer<TypingTestService>(
              builder: (context, testService, child) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Test info bar
                      _buildInfoBar(testService),
                      const SizedBox(height: 16),
                      
                      // Text to type
                      _buildTextDisplay(testService),
                      const SizedBox(height: 24),
                      
                      // Input field
                      TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: 'Start typing here...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: settings.isDarkMode 
                              ? Colors.grey.shade800 
                              : Colors.grey.shade100,
                        ),
                        style: TextStyle(
                          fontSize: 18,
                          color: settings.isDarkMode
                              ? Colors.white
                              : Colors.black,
                        ),
                        maxLines: 5,
                        onChanged: (value) {
                          testService.updateUserInput(value);
                          
                          if (testService.timeRemaining <= 0) {
                            _navigateToResults();
                          }
                        },
                        autofocus: true,
                      ),
                      const SizedBox(height: 24),
                      
                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.replay),
                            label: const Text('Restart Test'),
                            onPressed: () {
                              _startTest();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.stop),
                            label: const Text('End Test'),
                            onPressed: () {
                              testService.endTest();
                              _navigateToResults();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildInfoBar(TypingTestService testService) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem('Time Left', '${testService.timeRemaining}s', Icons.timer),
          _buildInfoItem('WPM', '${testService.wordsPerMinute}', Icons.speed),
          _buildInfoItem('Errors', '${testService.errorCount}', Icons.error_outline),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTextDisplay(TypingTestService testService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      height: 150,
      child: SingleChildScrollView(
        child: _buildHighlightedText(testService),
      ),
    );
  }

  Widget _buildHighlightedText(TypingTestService testService) {
    final String textToType = testService.currentText;
    final String userInput = testService.userInput;
    
    if (userInput.isEmpty) {
      return Text(
        textToType,
        style: const TextStyle(
          fontSize: 18,
          height: 1.5,
        ),
      );
    }
    
    List<TextSpan> spans = [];
    
    final List<String> targetWords = textToType.split(' ');
    final List<String> typedWords = userInput.split(' ');
    
    for (int i = 0; i < targetWords.length; i++) {
      if (i < typedWords.length) {
        // Word has been typed
        final bool isCorrect = targetWords[i] == typedWords[i];
        spans.add(
          TextSpan(
            text: '${targetWords[i]} ',
            style: TextStyle(
              color: isCorrect ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else if (i == typedWords.length) {
        // Current word to type
        spans.add(
          TextSpan(
            text: '${targetWords[i]} ',
            style: const TextStyle(
              decoration: TextDecoration.underline,
              decorationThickness: 2,
            ),
          ),
        );
      } else {
        // Future words
        spans.add(
          TextSpan(
            text: '${targetWords[i]} ',
          ),
        );
      }
    }
    
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 18,
          height: 1.5,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        children: spans,
      ),
    );
  }

  void _navigateToResults() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const ResultsScreen(),
      ),
    );
  }
} 