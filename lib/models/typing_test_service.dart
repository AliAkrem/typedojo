import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:typedojo/models/test_result.dart';
import 'package:typedojo/models/settings_model.dart';

class TypingTestService extends ChangeNotifier {
  String _currentText = '';
  String _userInput = '';
  bool _isTestActive = false;
  int _timeRemaining = 60;
  int _wordsPerMinute = 0;
  int _errorCount = 0;
  late Timer _timer;
  DateTime? _startTime;
  List<TestResult> _pastResults = [];

  // Getters
  String get currentText => _currentText;
  String get userInput => _userInput;
  bool get isTestActive => _isTestActive;
  int get timeRemaining => _timeRemaining;
  int get wordsPerMinute => _wordsPerMinute;
  int get errorCount => _errorCount;
  List<TestResult> get pastResults => _pastResults;

  // Word lists by difficulty
  final List<String> _easyWords = [
    'the', 'be', 'to', 'of', 'and', 'a', 'in', 'that', 'have', 'I', 'it', 'for', 'not', 'on', 'with',
    'he', 'as', 'you', 'do', 'at', 'this', 'but', 'his', 'by', 'from', 'they', 'we', 'say', 'her', 'she',
    'or', 'an', 'will', 'my', 'one', 'all', 'would', 'there', 'their', 'what', 'so', 'up', 'out', 'if', 'about',
    'who', 'get', 'which', 'go', 'me', 'when', 'make', 'can', 'like', 'time', 'no', 'just', 'him', 'know', 'take',
  ];

  final List<String> _mediumWords = [
    'about', 'better', 'between', 'character', 'develop', 'different', 'everything', 'experience', 'government',
    'important', 'interest', 'knowledge', 'language', 'material', 'necessary', 'personal', 'position', 'question',
    'remember', 'represent', 'sometimes', 'something', 'special', 'together', 'understand', 'available', 'beautiful',
    'business', 'certainly', 'community', 'consider', 'continue', 'education', 'environment', 'experience', 'following',
  ];

  final List<String> _hardWords = [
    'accommodation', 'accomplishment', 'acknowledgement', 'administration', 'characteristic', 'classification',
    'communication', 'comprehensive', 'confidentiality', 'congratulations', 'correspondence', 'determination',
    'disappointment', 'embarrassment', 'extraordinary', 'implementation', 'infrastructure', 'knowledgeable',
    'manufacturing', 'miscellaneous', 'nevertheless', 'representative', 'simultaneously', 'sophisticated',
    'straightforward', 'superintendent', 'technological', 'transportation', 'understanding', 'unfortunately',
  ];

  // Initialize
  Future<void> initialize(SettingsModel settings) async {
    await loadPastResults();
    _timeRemaining = settings.durationInSeconds;
    generateText(settings.textDifficulty);
  }

  // Generate random text based on difficulty
  void generateText(TextDifficulty difficulty) {
    List<String> wordPool;
    int wordCount;
    
    switch (difficulty) {
      case TextDifficulty.easy:
        wordPool = _easyWords;
        wordCount = 50;
        break;
      case TextDifficulty.medium:
        wordPool = [..._easyWords, ..._mediumWords];
        wordCount = 60;
        break;
      case TextDifficulty.hard:
        wordPool = [..._mediumWords, ..._hardWords];
        wordCount = 70;
        break;
    }

    final random = Random();
    final StringBuilder = StringBuffer();
    
    for (var i = 0; i < wordCount; i++) {
      final word = wordPool[random.nextInt(wordPool.length)];
      StringBuilder.write(word);
      
      // Add punctuation occasionally for medium and hard difficulties
      if (difficulty != TextDifficulty.easy && random.nextInt(10) < 3) {
        final punctuation = [',', '.', '?', '!'][random.nextInt(4)];
        StringBuilder.write(punctuation);
      }
      
      StringBuilder.write(' ');
    }

    _currentText = StringBuilder.toString().trim();
    notifyListeners();
  }

  // Start the test
  void startTest(int durationInSeconds) {
    if (_isTestActive) return; // Prevent multiple starts
    
    _isTestActive = true;
    _userInput = '';
    _errorCount = 0;
    _wordsPerMinute = 0;
    _timeRemaining = durationInSeconds;
    _startTime = DateTime.now();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _timeRemaining--;
      _calculateWPM();
      
      if (_timeRemaining <= 0) {
        endTest();
      }
      
      notifyListeners();
    });
    
    notifyListeners();
  }

  // Update user input
  void updateUserInput(String input) {
    _userInput = input;
    _calculateErrors();
    _calculateWPM();
    notifyListeners();
  }

  // Calculate errors in typing
  void _calculateErrors() {
    _errorCount = 0;
    final inputWords = _userInput.split(' ');
    final targetWords = _currentText.split(' ');
    
    // Skip the last word if it's incomplete (no space after it)
    int wordsToCheck = _userInput.endsWith(' ') 
        ? inputWords.length 
        : inputWords.length - 1;
    
    // Make sure we're not checking more words than are available
    wordsToCheck = wordsToCheck.clamp(0, targetWords.length);
    
    for (int i = 0; i < wordsToCheck; i++) {
      if (i < targetWords.length && inputWords[i] != targetWords[i]) {
        _errorCount++;
      }
    }
  }

  // Calculate words per minute
  void _calculateWPM() {
    if (_startTime == null || _userInput.isEmpty) return;
    
    final elapsedTimeInMinutes = DateTime.now().difference(_startTime!).inSeconds / 60;
    if (elapsedTimeInMinutes <= 0) return;
    
    final typedWords = _userInput.trim().split(' ').length;
    _wordsPerMinute = (typedWords / elapsedTimeInMinutes).round();
  }

  // End the test
  void endTest() {
    if (!_isTestActive) return;
    
    _timer.cancel();
    _isTestActive = false;
    
    final result = TestResult(
      wordsPerMinute: _wordsPerMinute,
      accuracy: _calculateAccuracy(),
      totalWords: _userInput.split(' ').length,
      errorCount: _errorCount,
    );
    
    _pastResults.add(result);
    _savePastResults();
    
    notifyListeners();
  }

  // Calculate accuracy percentage
  double _calculateAccuracy() {
    final totalTyped = _userInput.split(' ').length;
    if (totalTyped == 0) return 0.0;
    
    return ((totalTyped - _errorCount) / totalTyped * 100).clamp(0.0, 100.0);
  }

  // Save past results
  Future<void> _savePastResults() async {
    final prefs = await SharedPreferences.getInstance();
    final resultsJson = _pastResults.map((result) => result.toJson()).toList();
    await prefs.setString('pastResults', resultsJson.toString());
  }

  // Load past results
  Future<void> loadPastResults() async {
    final prefs = await SharedPreferences.getInstance();
    final resultsString = prefs.getString('pastResults');
    
    if (resultsString != null && resultsString.isNotEmpty) {
      try {
        final resultsJson = resultsString as List;
        _pastResults = resultsJson.map((json) => TestResult.fromJson(json)).toList();
        _pastResults.sort((a, b) => b.wordsPerMinute.compareTo(a.wordsPerMinute));
      } catch (e) {
        // Handle parsing error
        _pastResults = [];
      }
    }
  }

  // Reset test
  void resetTest() {
    if (_isTestActive) {
      _timer.cancel();
    }
    
    _isTestActive = false;
    _userInput = '';
    _errorCount = 0;
    _wordsPerMinute = 0;
    
    notifyListeners();
  }
} 