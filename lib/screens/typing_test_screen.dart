import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final FocusNode _focusNode = FocusNode();
  late TypingTestService _testService;
  bool _isInitialized = false;
  bool _isCountdown = true;
  int _countdownValue = 3;
  late Timer _countdownTimer;

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
    _focusNode.dispose();
    if (_testService.isTestActive) {
      _testService.endTest();
    }
    if (_isCountdown) {
      _countdownTimer.cancel();
    }
    super.dispose();
  }

  Future<void> _initializeTest() async {
    final settings = Provider.of<SettingsModel>(context, listen: false);
    _testService = Provider.of<TypingTestService>(context, listen: false);
    await _testService.initialize(settings);
    _testService.resetTest();
    
    // Start countdown
    _startCountdown();

    setState(() {
      _isInitialized = true;
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdownValue--;
        if (_countdownValue <= 0) {
          _isCountdown = false;
          _countdownTimer.cancel();
          _textController.clear();
        }
      });
    });
  }

  void _startTest() {
    final settings = Provider.of<SettingsModel>(context, listen: false);
    _textController.clear();
    // Only reset and start the timer here
    _testService.resetTest();
    _testService.startTest(settings.durationInSeconds);
    _testService.addListener(_checkTimeUp);
  }

  void _checkTimeUp() {
    if (_testService.timeRemaining <= 0 && !_testService.isTestActive) {
      // Remove listener to prevent multiple navigations
      _testService.removeListener(_checkTimeUp);
      // Navigate with a slight delay to allow state to update
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _navigateToResults();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Typing Test'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: !_isInitialized || _isCountdown
            ? null
            : [
                Consumer<TypingTestService>(
                  builder: (context, testService, _) {
                    return Row(
                      children: [
                        _buildInfoItem('${testService.timeRemaining}s', Icons.timer),
                        const SizedBox(width: 12),
                        _buildInfoItem('${testService.wordsPerMinute}', Icons.speed),
                        const SizedBox(width: 12),
                        _buildInfoItem('${testService.errorCount}', Icons.error_outline),
                        const SizedBox(width: 8),
                      ],
                    );
                  },
                ),
              ],
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : _isCountdown 
              ? _buildCountdown()
              : Consumer<TypingTestService>(
                  builder: (context, testService, child) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Text to type - now the main focus
                          Expanded(
                            child: Stack(
                              children: [
                                _buildTextDisplay(testService),
                                // Hidden text field to trigger keyboard with raw keyboard listener for backspace
                                Positioned.fill(
                                  child: Focus(
                                    focusNode: _focusNode,
                                    onKeyEvent: (node, event) {
                                      // Handle backspace key event
                                      if (event is KeyDownEvent && 
                                          event.logicalKey == LogicalKeyboardKey.backspace && 
                                          testService.userInput.isNotEmpty) {
                                        testService.updateUserInput(
                                          testService.userInput.substring(0, testService.userInput.length - 1)
                                        );
                                        return KeyEventResult.handled;
                                      }
                                      return KeyEventResult.ignored;
                                    },
                                    child: Opacity(
                                      opacity: 0,
                                      child: TextField(
                                        controller: _textController,
                                        autofocus: true,
                                        keyboardType: TextInputType.text,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                        ),
                                        onChanged: (value) {
                                          // Only handle inputs if field is not empty
                                          if (value.isEmpty) return;
                                          
                                          // Start test if needed
                                          if (!testService.isTestActive) {
                                            _startTest();
                                          }
                                          
                                          final String currentSegmentText = testService.currentSegment;
                                          final String currentUserInput = testService.userInput;
                                          
                                          // Check if user has typed a space
                                          if (value == " ") {
                                            // Check if the next character to type should be a space
                                            if (currentUserInput.length < currentSegmentText.length &&
                                                currentSegmentText[currentUserInput.length] == ' ') {
                                              // Accept the space and advance to next word
                                              testService.updateUserInput(currentUserInput + value);
                                            }
                                            _textController.clear();
                                            return;
                                          }
                                          
                                          // Check if the user is supposed to type a space but typed something else
                                          if (currentUserInput.isNotEmpty && 
                                              currentUserInput.length < currentSegmentText.length &&
                                              currentSegmentText[currentUserInput.length] == ' ') {
                                            // User should type space next, but typed something else
                                            // Don't count as error, but also don't accept the input
                                            _textController.clear();
                                            return;
                                          }
                                          
                                          if (value.length > 1 && currentUserInput.isNotEmpty) {
                                            // Handle multiple characters (paste or prediction)
                                            String newChars = value.substring(1);
                                            testService.updateUserInput(currentUserInput + newChars);
                                          } else if (value.length == 1) {
                                            // Handle single character (normal typing)
                                            testService.updateUserInput(currentUserInput + value);
                                          }
                                          
                                          // Check if current segment is complete
                                          if (testService.userInput.length >= testService.currentSegment.length) {
                                            // Move to next segment if available, otherwise clear
                                            if (testService.hasNextSegment) {
                                              Future.microtask(() {
                                                testService.moveToNextSegment();
                                                testService.updateUserInput('');
                                              });
                                            }
                                          }
                                          
                                          // Clear for next input
                                          _textController.clear();
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Keyboard activation reminder
                          GestureDetector(
                            onTap: () {
                              _focusNode.requestFocus();
                            },
                            child: Card(
                              color: Theme.of(context).colorScheme.surface,
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  'Tap here if keyboard is not visible. Start typing to begin the test.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
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

  Widget _buildInfoItem(String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTextDisplay(TypingTestService testService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Segment progress indicator
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Segment ${testService.currentSegmentIndex + 1}/${testService.totalSegments}',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: testService.hasPreviousSegment
                        ? () {
                            testService.moveToPreviousSegment();
                            testService.updateUserInput('');
                            _textController.clear();
                          }
                        : null,
                    iconSize: 18,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: testService.hasNextSegment
                        ? () {
                            testService.moveToNextSegment();
                            testService.updateUserInput('');
                            _textController.clear();
                          }
                        : null,
                    iconSize: 18,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
        // Segment text display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
              width: 1,
            ),
          ),
          child: SingleChildScrollView(
            child: _buildHighlightedText(testService),
          ),
        ),
        // Segment progress bar
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: LinearProgressIndicator(
            value: testService.getSegmentProgress(),
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightedText(TypingTestService testService) {
    final String textToType = testService.currentSegment;
    final String userInput = testService.userInput;
    
    List<TextSpan> spans = [];
    
    // If user hasn't started typing yet, show all text with low opacity
    if (userInput.isEmpty) {
      // Make spaces more visible in the text with subtle background highlighting
      List<TextSpan> initialSpans = [];
      for (int i = 0; i < textToType.length; i++) {
        bool isSpace = textToType[i] == ' ';
        initialSpans.add(
          TextSpan(
            text: textToType[i],
            style: TextStyle(
              fontSize: 18,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              backgroundColor: isSpace ? Colors.grey.withOpacity(0.1) : null,
            ),
          ),
        );
      }
      
      return RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 18,
            height: 1.5,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          children: initialSpans,
        ),
      );
    }
    
    // Split text into characters to handle character-by-character comparison
    List<String> textChars = textToType.split('');
    List<String> inputChars = userInput.split('');
    
    // For characters already typed
    for (int i = 0; i < min(inputChars.length, textChars.length); i++) {
      bool isCorrect = inputChars[i] == textChars[i];
      bool isSpace = textChars[i] == ' ';
      spans.add(
        TextSpan(
          text: textChars[i], // Just use the actual space character
          style: TextStyle(
            color: isCorrect ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            // Enhance background for spaces to make them more visible without the symbol
            backgroundColor: isSpace
                ? (isCorrect ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2))
                : (isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1)),
          ),
        ),
      );
    }
    
    // Current character to type (underlined)
    if (inputChars.length < textChars.length) {
      // Check if next character is a space - highlight it specially
      bool nextIsSpace = textChars[inputChars.length] == ' ';
      spans.add(
        TextSpan(
          text: textChars[inputChars.length], // Use the actual space character
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
            decorationThickness: 2,
            fontSize: 18,
            // Make space more visible with stronger background highlighting
            backgroundColor: nextIsSpace ? Colors.amber.withOpacity(0.4) : null,
            letterSpacing: nextIsSpace ? 2.0 : null, // Wider spacing for spaces
          ),
        ),
      );
    }
    
    // Remaining text (with reduced opacity)
    if (inputChars.length + 1 < textChars.length) {
      for (int i = inputChars.length + 1; i < textChars.length; i++) {
        bool isSpace = textChars[i] == ' ';
        spans.add(
          TextSpan(
            text: textChars[i], // Use the actual space character
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 18,
              backgroundColor: isSpace ? Colors.grey.withOpacity(0.15) : null,
            ),
          ),
        );
      }
    }
    
    // Auto-advance to next segment if current segment is completed
    if (inputChars.length >= textChars.length && testService.hasNextSegment) {
      // Use Future.microtask to avoid rebuilding during build
      Future.microtask(() {
        testService.moveToNextSegment();
        testService.updateUserInput('');
      });
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

  Widget _buildCountdown() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Get Ready!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '$_countdownValue',
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToResults() {
    // Make sure the test is properly ended only once
    if (_testService.isTestActive) {
      _testService.endTest();
    }
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(forceRefresh: true),
      ),
    );
  }
} 