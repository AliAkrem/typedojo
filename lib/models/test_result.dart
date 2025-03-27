class TestResult {
  final int wordsPerMinute;
  final double accuracy;
  final int totalWords;
  final int errorCount;
  final DateTime timestamp;

  TestResult({
    required this.wordsPerMinute,
    required this.accuracy,
    required this.totalWords,
    required this.errorCount,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'wordsPerMinute': wordsPerMinute,
      'accuracy': accuracy,
      'totalWords': totalWords,
      'errorCount': errorCount,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      wordsPerMinute: json['wordsPerMinute'],
      accuracy: json['accuracy'],
      totalWords: json['totalWords'],
      errorCount: json['errorCount'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }
} 