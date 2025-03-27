class TestResult {
  final int? id;
  final int wordsPerMinute;
  final double accuracy;
  final int totalWords;
  final int errorCount;
  final DateTime timestamp;
  final String difficulty;

  TestResult({
    this.id,
    required this.wordsPerMinute,
    required this.accuracy,
    required this.totalWords,
    required this.errorCount,
    DateTime? timestamp,
    this.difficulty = 'medium',
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'wordsPerMinute': wordsPerMinute,
      'accuracy': accuracy,
      'totalWords': totalWords,
      'errorCount': errorCount,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'difficulty': difficulty,
    };
  }

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      wordsPerMinute: json['wordsPerMinute'],
      accuracy: json['accuracy'],
      totalWords: json['totalWords'],
      errorCount: json['errorCount'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      difficulty: json['difficulty'] ?? 'medium',
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'wordsPerMinute': wordsPerMinute,
      'accuracy': accuracy,
      'totalWords': totalWords,
      'errorCount': errorCount,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'difficulty': difficulty,
    };
    
    if (id != null) {
      map['id'] = id!;
    }
    
    return map;
  }

  factory TestResult.fromMap(Map<String, dynamic> map) {
    return TestResult(
      id: map['id'] != null ? map['id'] as int : null,
      wordsPerMinute: map['wordsPerMinute'] as int,
      accuracy: map['accuracy'] is int 
          ? (map['accuracy'] as int).toDouble() 
          : map['accuracy'] as double,
      totalWords: map['totalWords'] as int,
      errorCount: map['errorCount'] as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      difficulty: map['difficulty'] as String? ?? 'medium',
    );
  }
} 