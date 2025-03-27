import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:typedojo/models/test_result.dart';
import 'package:typedojo/models/typing_test_service.dart';
import 'package:typedojo/models/settings_model.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context);
    final testService = Provider.of<TypingTestService>(context);
    
    // Sort results by WPM
    final List<TestResult> sortedResults = [...testService.pastResults]
      ..sort((a, b) => b.wordsPerMinute.compareTo(a.wordsPerMinute));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
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
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16.0),
              color: settings.isDarkMode
                  ? Colors.black.withOpacity(0.5)
                  : Colors.blue.shade700,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  Text(
                    'Rank',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'WPM',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Accuracy',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Date',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Leaderboard entries
            Expanded(
              child: sortedResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.emoji_events_outlined,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No scores yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: settings.isDarkMode ? Colors.white : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Complete a typing test to see your scores here',
                            style: TextStyle(
                              color: settings.isDarkMode ? Colors.white70 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: sortedResults.length,
                      itemBuilder: (context, index) {
                        final result = sortedResults[index];
                        return _buildLeaderboardItem(
                          context, 
                          index + 1, 
                          result,
                          settings.isDarkMode,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardItem(
    BuildContext context, 
    int rank, 
    TestResult result,
    bool isDarkMode,
  ) {
    final isTopThree = rank <= 3;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey.shade900.withOpacity(0.8)
            : Colors.white.withOpacity(0.8),
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
          child: Text(
            '$rank',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              '${result.wordsPerMinute}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            Text(
              '${result.accuracy.toStringAsFixed(1)}%',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            Text(
              _formatDate(result.timestamp),
              style: TextStyle(
                color: isDarkMode ? Colors.white60 : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: LinearProgressIndicator(
            value: result.wordsPerMinute / 100, // Scale to make the bar look nice
            backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
            color: _getMedalColor(rank),
          ),
        ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 