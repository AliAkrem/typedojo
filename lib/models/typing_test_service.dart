import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:typedojo/models/test_result.dart';
import 'package:typedojo/models/settings_model.dart';
import 'package:typedojo/services/database_helper.dart';

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
  
  // Database helper
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  // For segmented text display
  List<String> _textSegments = [];
  int _currentSegmentIndex = 0;
  int _segmentSize = 6; // Words per segment
  int _totalTypedWords = 0; // Track total words typed across segments
  int _totalErrorCount = 0; // Track total errors across segments
  
  // Segmented text getters
  String get currentSegment => _currentSegmentIndex < _textSegments.length 
      ? _textSegments[_currentSegmentIndex] 
      : '';
  int get currentSegmentIndex => _currentSegmentIndex;
  int get totalSegments => _textSegments.length;
  bool get hasNextSegment => _currentSegmentIndex < _textSegments.length - 1;
  bool get hasPreviousSegment => _currentSegmentIndex > 0;

  // Getters
  String get currentText => _currentText;
  String get userInput => _userInput;
  bool get isTestActive => _isTestActive;
  int get timeRemaining => _timeRemaining;
  int get wordsPerMinute => _wordsPerMinute;
  int get errorCount => _totalErrorCount + _calculateCurrentSegmentErrors(); // Include current segment errors
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

  TextDifficulty _currentDifficulty = TextDifficulty.medium;
  
  // Initialize
  Future<void> initialize(SettingsModel settings) async {
    await loadPastResults();
    _timeRemaining = settings.durationInSeconds;
    generateText(settings.textDifficulty);
  }

  // Generate random text based on difficulty
  void generateText(TextDifficulty difficulty) {
    _currentDifficulty = difficulty;
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
    _createSegments();
    notifyListeners();
  }
  
  // Create text segments
  void _createSegments() {
    _textSegments = [];
    _currentSegmentIndex = 0;
    
    final List<String> words = _currentText.split(' ');
    
    for (int i = 0; i < words.length; i += _segmentSize) {
      final int end = (i + _segmentSize < words.length) ? i + _segmentSize : words.length;
      final String segment = words.sublist(i, end).join(' ');
      _textSegments.add(segment);
    }
  }
  
  // Move to next segment
  bool moveToNextSegment() {
    if (_currentSegmentIndex < _textSegments.length - 1) {
      // Update total typed words from current segment
      _totalTypedWords += _userInput.trim().split(' ').length;
      
      // Add current segment's errors to total before moving to next segment
      _totalErrorCount += _calculateCurrentSegmentErrors();
      
      _currentSegmentIndex++;
      notifyListeners();
      return true;
    }
    return false;
  }
  
  // Move to previous segment
  bool moveToPreviousSegment() {
    if (_currentSegmentIndex > 0) {
      _currentSegmentIndex--;
      notifyListeners();
      return true;
    }
    return false;
  }
  
  // Reset current segment
  void resetToFirstSegment() {
    _currentSegmentIndex = 0;
    notifyListeners();
  }
  
  // Get current segment progress (0.0 to 1.0)
  double getSegmentProgress() {
    if (_textSegments.isEmpty) return 0.0;
    return _currentSegmentIndex / (_textSegments.length - 1);
  }

  // Calculate errors in typing for current segment only
  int _calculateCurrentSegmentErrors() {
    int segmentErrors = 0;
    
    // Use character-by-character comparison for the current segment
    final List<String> inputChars = _userInput.split('');
    final List<String> targetChars = currentSegment.split('');
    
    // Only check characters that have been typed so far
    final int charsToCheck = inputChars.length.clamp(0, targetChars.length);
    
    for (int i = 0; i < charsToCheck; i++) {
      // Don't count as error if characters match exactly
      bool isCorrect = inputChars[i] == targetChars[i];
      
      if (!isCorrect) {
        segmentErrors++;
      }
    }
    
    return segmentErrors;
  }

  // Calculate errors in typing (updates the running total)
  void _calculateErrors() {
    // Calculate errors for the current segment
    int currentSegmentErrors = _calculateCurrentSegmentErrors();
    
    // Error count is now the sum of all previous segments plus current segment
    _errorCount = currentSegmentErrors;
  }

  // Start the test
  void startTest(int durationInSeconds) {
    if (_isTestActive) return; // Prevent multiple starts
    
    _isTestActive = true;
    _userInput = '';
    _errorCount = 0;
    _totalErrorCount = 0; // Reset total errors when starting a new test
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

  // Calculate words per minute
  void _calculateWPM() {
    if (_startTime == null || (_userInput.isEmpty && _totalTypedWords == 0)) return;
    
    final elapsedTimeInMinutes = DateTime.now().difference(_startTime!).inSeconds / 60;
    if (elapsedTimeInMinutes <= 0) return;
    
    // Include words from completed segments plus current segment
    final currentSegmentWords = _userInput.trim().split(' ').length;
    final totalWords = _totalTypedWords + currentSegmentWords;
    
    _wordsPerMinute = (totalWords / elapsedTimeInMinutes).round();
  }

  // End the test
  Future<void> endTest() async {
    if (!_isTestActive) return;
    
    _timer.cancel();
    _isTestActive = false;
    
    // Add current segment's errors to total
    _totalErrorCount += _calculateCurrentSegmentErrors();
    
    // Get difficulty string
    String difficultyStr;
    switch (_currentDifficulty) {
      case TextDifficulty.easy:
        difficultyStr = 'easy';
        break;
      case TextDifficulty.medium:
        difficultyStr = 'medium';
        break;
      case TextDifficulty.hard:
        difficultyStr = 'hard';
        break;
    }
    
    // Create the result object
    final result = TestResult(
      wordsPerMinute: _wordsPerMinute,
      accuracy: _calculateAccuracy(),
      totalWords: _totalTypedWords + _userInput.trim().split(' ').length,
      errorCount: _totalErrorCount, // Use total error count
      difficulty: difficultyStr,
    );
    
    // Save to the in-memory list first for immediate access
    _pastResults.insert(0, result); // Add at the beginning for most recent
    
    // Save to database
    try {
      final resultId = await _saveResultToDatabase(result);
      print('Test result saved to database with ID: $resultId');
      
      if (resultId > 0) {
        // Update the result with the database ID
        _pastResults[0] = TestResult(
          id: resultId,
          wordsPerMinute: result.wordsPerMinute,
          accuracy: result.accuracy,
          totalWords: result.totalWords,
          errorCount: result.errorCount,
          timestamp: result.timestamp,
          difficulty: result.difficulty,
        );
      }
      
      // No need to reload from database, already have the data
    } catch (e) {
      print('Error saving test result to database: $e');
      
      // In case of error, try to reload from database to keep consistent
      await loadPastResults();
    }
    
    notifyListeners();
  }

  // Calculate accuracy percentage
  double _calculateAccuracy() {
    final totalTyped = _totalTypedWords + _userInput.trim().split(' ').length;
    if (totalTyped == 0) return 0.0;
    
    // Calculate based on character accuracy instead of words
    final totalChars = _currentText.length;
    final totalErrors = _totalErrorCount; // Current error count
    
    // Use error ratio to calculate accuracy
    return (100 - (totalErrors / totalChars * 100)).clamp(0.0, 100.0);
  }

  // Save result to database
  Future<int> _saveResultToDatabase(TestResult result) async {
    try {
      final id = await _dbHelper.insertTestResult(result);
      print('Test result saved to database successfully with ID: $id');
      return id;
    } catch (e) {
      print('Error saving test result to database: $e');
      return -1;
    }
  }

  // Load past results from database
  Future<void> loadPastResults() async {
    try {
      _pastResults = await _dbHelper.getTestResults();
      _pastResults.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Sort by most recent first
      notifyListeners();
    } catch (e) {
      // Handle any database errors
      print('Error loading past results: $e');
      _pastResults = [];
    }
  }

  // Delete a result from history
  Future<void> deleteResult(int? id) async {
    if (id != null) {
      await _dbHelper.deleteTestResult(id);
      await loadPastResults(); // Reload results after deletion
    }
  }

  // Get stats for dashboard
  Future<Map<String, dynamic>> getStats() async {
    return await _dbHelper.getStats();
  }

  // Reset test
  void resetTest() {
    if (_isTestActive) {
      _timer.cancel();
    }
    
    _isTestActive = false;
    _userInput = '';
    _errorCount = 0;
    _totalErrorCount = 0; // Reset total errors
    _wordsPerMinute = 0;
    _totalTypedWords = 0;
    resetToFirstSegment();
    
    notifyListeners();
  }
} 