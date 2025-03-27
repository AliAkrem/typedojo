import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:typedojo/models/settings_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Consumer<SettingsModel>(
        builder: (context, settings, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Appearance Section
              _buildSectionHeader(context, 'Appearance'),
              
              // Dark Mode
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Toggle between light and dark theme'),
                value: settings.isDarkMode,
                onChanged: (value) {
                  settings.toggleDarkMode();
                },
                secondary: Icon(
                  settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                ),
              ),
              
              const Divider(),
              
              // Test Duration Section
              _buildSectionHeader(context, 'Test Duration'),
              
              // Radio buttons for test duration
              RadioListTile<TestDuration>(
                title: const Text('Short - 30 seconds'),
                value: TestDuration.short,
                groupValue: settings.testDuration,
                onChanged: (value) {
                  if (value != null) {
                    settings.setTestDuration(value);
                  }
                },
              ),
              RadioListTile<TestDuration>(
                title: const Text('Medium - 60 seconds'),
                value: TestDuration.medium,
                groupValue: settings.testDuration,
                onChanged: (value) {
                  if (value != null) {
                    settings.setTestDuration(value);
                  }
                },
              ),
              RadioListTile<TestDuration>(
                title: const Text('Long - 120 seconds'),
                value: TestDuration.long,
                groupValue: settings.testDuration,
                onChanged: (value) {
                  if (value != null) {
                    settings.setTestDuration(value);
                  }
                },
              ),
              RadioListTile<TestDuration>(
                title: const Text('Custom'),
                subtitle: Text('${settings.customDurationSeconds} seconds'),
                value: TestDuration.custom,
                groupValue: settings.testDuration,
                onChanged: (value) {
                  if (value != null) {
                    settings.setTestDuration(value);
                    _showCustomDurationDialog(context, settings);
                  }
                },
              ),
              
              if (settings.testDuration == TestDuration.custom)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      _showCustomDurationDialog(context, settings);
                    },
                    child: const Text('Set Custom Duration'),
                  ),
                ),
              
              const Divider(),
              
              // Difficulty Level Section
              _buildSectionHeader(context, 'Text Difficulty'),
              
              // Radio buttons for difficulty level
              RadioListTile<TextDifficulty>(
                title: const Text('Easy'),
                subtitle: const Text('Common words, no punctuation'),
                value: TextDifficulty.easy,
                groupValue: settings.textDifficulty,
                onChanged: (value) {
                  if (value != null) {
                    settings.setTextDifficulty(value);
                  }
                },
              ),
              RadioListTile<TextDifficulty>(
                title: const Text('Medium'),
                subtitle: const Text('Longer words, some punctuation'),
                value: TextDifficulty.medium,
                groupValue: settings.textDifficulty,
                onChanged: (value) {
                  if (value != null) {
                    settings.setTextDifficulty(value);
                  }
                },
              ),
              RadioListTile<TextDifficulty>(
                title: const Text('Hard'),
                subtitle: const Text('Technical vocabulary, more punctuation'),
                value: TextDifficulty.hard,
                groupValue: settings.textDifficulty,
                onChanged: (value) {
                  if (value != null) {
                    settings.setTextDifficulty(value);
                  }
                },
              ),
              
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  void _showCustomDurationDialog(BuildContext context, SettingsModel settings) {
    int customDuration = settings.customDurationSeconds;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Custom Duration'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose a duration in seconds (15-300):'),
              const SizedBox(height: 20),
              Slider(
                value: customDuration.toDouble(),
                min: 15,
                max: 300,
                divisions: 57, // (300-15)/5
                label: '$customDuration seconds',
                onChanged: (value) {
                  customDuration = value.round();
                  // This just updates the slider display
                  (context as Element).markNeedsBuild();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                settings.setCustomDuration(customDuration);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
} 