import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:typedojo/models/test_result.dart';
import 'package:typedojo/models/typing_test_service.dart';
import 'package:typedojo/models/settings_model.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context);
    final testService = Provider.of<TypingTestService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Results'),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Result card
              _buildResultCard(context, testService),
              const SizedBox(height: 24),
              
              // High scores
              _buildHighScoresCard(context, testService),
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
    );
  }

  Widget _buildResultCard(BuildContext context, TypingTestService testService) {
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
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildResultItem(
                  context,
                  'WPM',
                  '${testService.wordsPerMinute}',
                  Icons.speed,
                  Colors.blue,
                ),
                _buildResultItem(
                  context,
                  'Accuracy',
                  '${_calculateAccuracy(testService).toStringAsFixed(1)}%',
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
                  '${_calculateTotalWords(testService)}',
                  Icons.text_fields,
                  Colors.orange,
                ),
                _buildResultItem(
                  context,
                  'Errors',
                  '${testService.errorCount}',
                  Icons.error_outline,
                  Colors.red,
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

  Widget _buildHighScoresCard(BuildContext context, TypingTestService testService) {
    final List<TestResult> highScores = [...testService.pastResults]
      ..sort((a, b) => b.wordsPerMinute.compareTo(a.wordsPerMinute));
    
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
            
            highScores.isEmpty
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
                      itemCount: highScores.length > 5 ? 5 : highScores.length,
                      itemBuilder: (context, index) {
                        final result = highScores[index];
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

  double _calculateAccuracy(TypingTestService testService) {
    final totalTyped = _calculateTotalWords(testService);
    if (totalTyped == 0) return 0.0;
    
    return ((totalTyped - testService.errorCount) / totalTyped * 100).clamp(0.0, 100.0);
  }
  
  int _calculateTotalWords(TypingTestService testService) {
    return testService.userInput.split(' ').length;
  }
} 