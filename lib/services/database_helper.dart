import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:typedojo/models/test_result.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static DatabaseHelper get instance => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'typedojo.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      print('Upgrading database from version $oldVersion to $newVersion');
    }
    
    if (oldVersion < 3) {
      // Add difficulty column to existing database
      print('Adding difficulty column to test_results table');
      await db.execute('ALTER TABLE test_results ADD COLUMN difficulty TEXT DEFAULT "medium"');
    }
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE test_results(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        wordsPerMinute INTEGER NOT NULL,
        accuracy REAL NOT NULL,
        totalWords INTEGER NOT NULL,
        errorCount INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        difficulty TEXT DEFAULT "medium"
      )
    ''');
    
    print('Database created successfully');
  }

  // Insert a new test result
  Future<int> insertTestResult(TestResult result) async {
    try {
      Database db = await database;
      
      final resultMap = result.toMap();
 
      
      final id = await db.insert(
        'test_results',
        resultMap,
      );
      
      

      
      return id;
    } catch (e) {
      print('Error inserting test result: $e');
      print('Stack trace: ${StackTrace.current}');
      return -1;
    }
  }

  // Retrieve all test results
  Future<List<TestResult>> getTestResults() async {
    try {
      Database db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'test_results',
        orderBy: 'timestamp DESC',
      );
      
      print('Retrieved ${maps.length} test results from database');
      
      return List.generate(maps.length, (i) {
        return TestResult.fromMap(maps[i]);
      });
    } catch (e) {
      print('Error retrieving test results: $e');
      return [];
    }
  }

  // Get top N results by WPM
  Future<List<TestResult>> getTopResults(int limit) async {
    try {
      Database db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'test_results',
        orderBy: 'wordsPerMinute DESC',
        limit: limit,
      );
      
      print('Retrieved ${maps.length} top results from database');
      
      return List.generate(maps.length, (i) {
        return TestResult.fromMap(maps[i]);
      });
    } catch (e) {
      print('Error retrieving top results: $e');
      return [];
    }
  }

  // Delete a test result
  Future<int> deleteTestResult(int id) async {
    try {
      Database db = await database;
      final result = await db.delete(
        'test_results',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      print('Deleted test result with ID: $id, affected rows: $result');
      return result;
    } catch (e) {
      print('Error deleting test result: $e');
      return 0;
    }
  }

  // Clear all test results
  Future<int> clearResults() async {
    try {
      Database db = await database;
      final result = await db.delete('test_results');
      
      print('Cleared all test results, affected rows: $result');
      return result;
    } catch (e) {
      print('Error clearing test results: $e');
      return 0;
    }
  }

  // Get stats
  Future<Map<String, dynamic>> getStats() async {
    try {
      Database db = await database;
      
      // Get best WPM
      final bestWpmResult = await db.rawQuery(
        'SELECT MAX(wordsPerMinute) as bestWpm FROM test_results'
      );
      int bestWpm = bestWpmResult.first['bestWpm'] as int? ?? 0;
      
      // Get best accuracy
      final bestAccuracyResult = await db.rawQuery(
        'SELECT MAX(accuracy) as bestAccuracy FROM test_results'
      );
      double bestAccuracy = bestAccuracyResult.first['bestAccuracy'] as double? ?? 0.0;
      
      // Get average WPM
      final avgWpmResult = await db.rawQuery(
        'SELECT AVG(wordsPerMinute) as avgWpm FROM test_results'
      );
      double avgWpm = avgWpmResult.first['avgWpm'] as double? ?? 0.0;
      
      // Get total tests count
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM test_results'
      );
      int count = countResult.first['count'] as int? ?? 0;
      
      print('Retrieved stats: Best WPM: $bestWpm, Best Accuracy: $bestAccuracy, Avg WPM: $avgWpm, Total Tests: $count');
      
      return {
        'bestWpm': bestWpm,
        'bestAccuracy': bestAccuracy,
        'avgWpm': avgWpm,
        'totalTests': count,
      };
    } catch (e) {
      print('Error retrieving stats: $e');
      return {
        'bestWpm': 0,
        'bestAccuracy': 0.0,
        'avgWpm': 0.0,
        'totalTests': 0,
      };
    }
  }
} 