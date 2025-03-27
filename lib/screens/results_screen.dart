import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:typedojo/models/test_result.dart';
import 'package:typedojo/models/typing_test_service.dart';
import 'package:typedojo/models/settings_model.dart';
import 'package:typedojo/services/database_helper.dart';

class ResultsScreen extends StatefulWidget {
  final bool forceRefresh;
  
  const ResultsScreen({super.key, this.forceRefresh = false});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _isLoading = true;
  TestResult? _latestResult;
  List<TestResult> _topResults = [];

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Load directly from the database
      final dbHelper = DatabaseHelper.instance;
      
      // If forceRefresh is true, wait a short delay to ensure DB write operation is complete
      if (widget.forceRefresh) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
      // Get all results ordered by timestamp (most recent first)
      final results = await dbHelper.getTestResults();
      
      // Get top results by WPM
      final topResults = await dbHelper.getTopResults(5);
      
      setState(() {
        if (results.isNotEmpty) {
          _latestResult = results.first; // Most recent result
          print('Loaded latest result: WPM=${_latestResult!.wordsPerMinute}, Accuracy=${_latestResult!.accuracy}');
        } else {
          print('No results found in the database.');
        }
        _topResults = topResults;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading results: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context);
    final testService = Provider.of<TypingTestService>(context, listen: false);
    
    // If the test service has a result but we don't, use it
    if (_latestResult == null && testService.pastResults.isNotEmpty) {
      _latestResult = testService.pastResults.first;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Results'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadResults,
            tooltip: 'Refresh results',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: settings.isDarkMode
                        ? [Colors.blueGrey.shade900, Colors.black]
                        : [Colors.blue.shade100, Colors.blue.shade300],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Result card
                      _buildResultCard(context),
                      const SizedBox(height: 24),
                      
                      // High scores
                      _buildHighScoresCard(context),
                      const SizedBox(height: 32),
                      
                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.replay),
                            label: const Text('Try Again'),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.home),
                            label: const Text('Home'),
                            onPressed: () {
                              Navigator.popUntil(context, (route) => route.isFirst);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildResultCard(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Your Results',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            
            _latestResult == null
                ? const Text('No results available')
                : Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildResultItem(
                            context,
                            'WPM',
                            '${_latestResult!.wordsPerMinute}',
                            Icons.speed,
                            Colors.blue,
                          ),
                          _buildResultItem(
                            context,
                            'Accuracy',
                            '${_latestResult!.accuracy.toStringAsFixed(1)}%',
                            Icons.check_circle_outline,
                            Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildResultItem(
                            context,
                            'Total Words',
                            '${_latestResult!.totalWords}',
                            Icons.text_fields,
                            Colors.orange,
                          ),
                          _buildResultItem(
                            context,
                            'Errors',
                            '${_latestResult!.errorCount}',
                            Icons.error_outline,
                            Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 40,
          color: color,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildHighScoresCard(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                'High Scores',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            
            _topResults.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No previous scores yet. Keep practicing!',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  )
                : SizedBox(
                    height: 150,
                    child: ListView.builder(
                      itemCount: _topResults.length > 5 ? 5 : _topResults.length,
                      itemBuilder: (context, index) {
                        final result = _topResults[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getPlaceColor(index),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text('${result.wordsPerMinute} WPM'),
                          subtitle: Text(
                            'Accuracy: ${result.accuracy.toStringAsFixed(1)}% | Errors: ${result.errorCount}',
                          ),
                          trailing: Text(
                            _formatDate(result.timestamp),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Color _getPlaceColor(int place) {
    switch (place) {
      case 0:
        return Colors.amber.shade700; // Gold
      case 1:
        return Colors.blueGrey.shade400; // Silver
      case 2:
        return Colors.brown.shade400; // Bronze
      default:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays < 2) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
} 