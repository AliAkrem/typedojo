import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:typedojo/models/test_result.dart';
import 'package:typedojo/models/typing_test_service.dart';
import 'package:typedojo/models/settings_model.dart';
import 'package:intl/intl.dart';
import 'package:typedojo/services/database_helper.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _sortCriteria = 'WPM';
  bool _isLoading = false;
  List<TestResult> _allResults = [];
  Map<String, dynamic> _stats = {
    'bestWpm': 0,
    'bestAccuracy': 0.0,
    'avgWpm': 0.0,
    'totalTests': 0,
  };
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data each time the screen is focused
    _loadData();
  }
  
  Future<void> _loadData() async {
    if (_isLoading) return; // Prevent multiple concurrent loads
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load all results directly from the database
      final dbHelper = DatabaseHelper.instance;
      _allResults = await dbHelper.getTestResults();
      _stats = await dbHelper.getStats();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context);
    final testService = Provider.of<TypingTestService>(context);
    
    // Sort results based on criteria
    List<TestResult> sortedResults = [..._allResults];
    
    switch (_sortCriteria) {
      case 'WPM':
        sortedResults.sort((a, b) => b.wordsPerMinute.compareTo(a.wordsPerMinute));
        break;
      case 'Accuracy':
        sortedResults.sort((a, b) => b.accuracy.compareTo(a.accuracy));
        break;
      case 'Date':
        sortedResults.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard & History'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.emoji_events), text: 'Top Scores'),
            Tab(icon: Icon(Icons.history), text: 'All History'),
            Tab(icon: Icon(Icons.stacked_line_chart), text: 'Stats'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by',
            onSelected: (String value) {
              setState(() {
                _sortCriteria = value;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'WPM',
                child: Text('Sort by WPM'),
              ),
              const PopupMenuItem<String>(
                value: 'Accuracy',
                child: Text('Sort by Accuracy'),
              ),
              const PopupMenuItem<String>(
                value: 'Date',
                child: Text('Sort by Date (Latest)'),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: settings.isDarkMode
                ? [Colors.blueGrey.shade900, Colors.black]
                : [Colors.blue.shade100, Colors.blue.shade300],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            // Top Scores Tab
            _buildTopScoresTab(context, sortedResults, settings.isDarkMode, testService),
            
            // All History Tab
            _buildHistoryTab(context, sortedResults, settings.isDarkMode, testService),
            
            // Stats Tab
            _buildStatsTab(context, settings.isDarkMode),
          ],
        ),
      ),
     
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, TypingTestService testService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to delete all typing test history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });
              
              // Clear all results
              await DatabaseHelper.instance.clearResults();
              
              // Reload data after clearing
              _allResults = [];
              await _loadData();
              
              // Also reload in the test service for consistency
              await testService.loadPastResults();
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTopScoresTab(BuildContext context, List<TestResult> results, bool isDarkMode, TypingTestService testService) {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (results.isEmpty) {
      return _buildEmptyState(isDarkMode);
    }
    
    // Take only top 10 for this view
    final topResults = results.take(10).toList();
    
    return Column(
      children: [
        // Stats Summary Card
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Card(
            color: isDarkMode ? Colors.grey.shade900 : Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Best WPM', 
                      '${_stats['bestWpm']}', 
                      Icons.speed, 
                      Colors.blue),
                  _buildStatItem('Best Accuracy', 
                      '${(_stats['bestAccuracy'] as double).toStringAsFixed(1)}%', 
                      Icons.check_circle, 
                      Colors.green),
                  _buildStatItem('Tests Taken', 
                      '${_stats['totalTests']}', 
                      Icons.assessment, 
                      Colors.orange),
                ],
              ),
            ),
          ),
        ),
        
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          color: isDarkMode ? Colors.black.withOpacity(0.5) : Colors.blue.shade700,
          child: Row(
            children: [
              const SizedBox(width: 50), // Space for rank
              Expanded(
                flex: 2,
                child: Text(
                  'WPM',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Accuracy',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Date',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Leaderboard entries
        Expanded(
          child: ListView.builder(
            itemCount: topResults.length,
            itemBuilder: (context, index) {
              final result = topResults[index];
              return _buildLeaderboardItem(context, index + 1, result, isDarkMode, testService);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildHistoryTab(BuildContext context, List<TestResult> results, bool isDarkMode, TypingTestService testService) {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (results.isEmpty) {
      return _buildEmptyState(isDarkMode);
    }
    
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        
        return Dismissible(
          key: Key(result.id?.toString() ?? '$index-${result.timestamp.millisecondsSinceEpoch}'),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Entry'),
                content: const Text('Are you sure you want to delete this test result?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) async {
            if (result.id != null) {
              await DatabaseHelper.instance.deleteTestResult(result.id!);
              
              // Update local data
              setState(() {
                _allResults.remove(result);
              });
              
              // Reload stats and service data
              await _loadData();
              await testService.loadPastResults();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Test result deleted"),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            color: isDarkMode ? Colors.grey.shade900.withOpacity(0.8) : Colors.white.withOpacity(0.9),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: _getTestResultColor(result, isDarkMode),
                child: Icon(
                  Icons.keyboard,
                  color: Colors.white,
                ),
              ),
              title: Text(
                '${result.wordsPerMinute} WPM',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Text(
                _formatDateTime(result.timestamp),
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${result.accuracy.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: _getAccuracyColor(result.accuracy),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildDifficultyBadge(result.difficulty),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDetailItem('Total Words', '${result.totalWords}', isDarkMode),
                          _buildDetailItem('Errors', '${result.errorCount}', isDarkMode),
                          _buildDetailItem('Rank', _getRankText(results, result), isDarkMode),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: result.wordsPerMinute / 120, // Scale to make the bar look nice
                        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                        color: _getTestResultColor(result, isDarkMode),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildStatsTab(BuildContext context, bool isDarkMode) {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: isDarkMode ? Colors.grey.shade900 : Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      'Performance Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildLargeStatItem(
                          'Best WPM',
                          '${_stats['bestWpm']}',
                          Icons.speed,
                          Colors.blue,
                          isDarkMode,
                        ),
                        _buildLargeStatItem(
                          'Average WPM',
                          '${(_stats['avgWpm'] as double).toStringAsFixed(1)}',
                          Icons.trending_up,
                          Colors.amber,
                          isDarkMode,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildLargeStatItem(
                          'Best Accuracy',
                          '${(_stats['bestAccuracy'] as double).toStringAsFixed(1)}%',
                          Icons.check_circle,
                          Colors.green,
                          isDarkMode,
                        ),
                        _buildLargeStatItem(
                          'Tests Completed',
                          '${_stats['totalTests']}',
                          Icons.assessment,
                          Colors.purple,
                          isDarkMode,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: isDarkMode ? Colors.grey.shade900 : Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tips to Improve',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTipItem('Practice regularly - even just 10 minutes a day', Icons.calendar_today, isDarkMode),
                    _buildTipItem('Focus on accuracy before speed', Icons.check_circle_outline, isDarkMode),
                    _buildTipItem('Use proper finger placement and posture', Icons.accessibility_new, isDarkMode),
                    _buildTipItem('Take breaks to avoid fatigue', Icons.healing, isDarkMode),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () {
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Statistics refreshed"),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Stats'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTipItem(String tip, IconData icon, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLargeStatItem(String label, String value, IconData icon, Color color, bool isDarkMode) {
    return Column(
      children: [
        Icon(icon, color: color, size: 40),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          const Text(
            'Loading data...',
            style: TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailItem(String label, String value, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(
    BuildContext context, 
    int rank, 
    TestResult result,
    bool isDarkMode,
    TypingTestService testService,
  ) {
    final isTopThree = rank <= 3;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey.shade900.withOpacity(0.8)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: isTopThree
            ? [
                BoxShadow(
                  color: _getMedalColor(rank).withOpacity(0.5),
                  blurRadius: 5,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getMedalColor(rank),
          child: isTopThree 
            ? Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 20,
              )
            : Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
        ),
        title: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                '${result.wordsPerMinute}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${result.accuracy.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: _getAccuracyColor(result.accuracy),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Text(
                    _formatDate(result.timestamp),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white60 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildDifficultyBadge(result.difficulty),
                ],
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: LinearProgressIndicator(
            value: result.wordsPerMinute / 120, // Scale to make the bar look nice
            backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
            color: _getMedalColor(rank),
          ),
        ),
        onLongPress: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Entry'),
              content: const Text('Would you like to delete this test result?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await testService.deleteResult(result.id);
                    await _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Test result deleted"),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 80,
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No scores yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete a typing test to see your scores here',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black38,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.keyboard),
            label: const Text('Take a Typing Test'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Color _getMedalColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade700; // Gold
      case 2:
        return Colors.blueGrey.shade400; // Silver
      case 3:
        return Colors.brown.shade400; // Bronze
      default:
        return Colors.blue;
    }
  }
  
  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 95) return Colors.green;
    if (accuracy >= 85) return Colors.lime.shade700;
    if (accuracy >= 75) return Colors.orange;
    return Colors.red;
  }
  
  Color _getTestResultColor(TestResult result, bool isDarkMode) {
    if (result.wordsPerMinute >= 80) return Colors.purple;
    if (result.wordsPerMinute >= 60) return Colors.blue;
    if (result.wordsPerMinute >= 40) return Colors.green;
    if (result.wordsPerMinute >= 20) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  String _formatDateTime(DateTime date) {
    return DateFormat('MMM d, y - h:mm a').format(date);
  }
  
  int _getBestWPM(List<TestResult> results) {
    if (results.isEmpty) return 0;
    return results.map((r) => r.wordsPerMinute).reduce((a, b) => a > b ? a : b);
  }
  
  double _getBestAccuracy(List<TestResult> results) {
    if (results.isEmpty) return 0.0;
    return results.map((r) => r.accuracy).reduce((a, b) => a > b ? a : b);
  }
  
  String _getRankText(List<TestResult> allResults, TestResult current) {
    final wpmSorted = [...allResults]..sort((a, b) => b.wordsPerMinute.compareTo(a.wordsPerMinute));
    final rank = wpmSorted.indexOf(current) + 1;
    return '#$rank/${allResults.length}';
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color badgeColor;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        badgeColor = Colors.green;
        break;
      case 'medium':
        badgeColor = Colors.orange;
        break;
      case 'hard':
        badgeColor = Colors.red;
        break;
      default:
        badgeColor = Colors.blue;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: badgeColor,
        ),
      ),
    );
  }
} 