import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TestDuration { short, medium, long, custom }
enum TextDifficulty { easy, medium, hard }

class SettingsModel extends ChangeNotifier {
  bool _isDarkMode = false;
  TestDuration _testDuration = TestDuration.medium;
  TextDifficulty _textDifficulty = TextDifficulty.medium;
  int _customDurationSeconds = 60;

  bool get isDarkMode => _isDarkMode;
  TestDuration get testDuration => _testDuration;
  TextDifficulty get textDifficulty => _textDifficulty;
  int get customDurationSeconds => _customDurationSeconds;

  int get durationInSeconds {
    switch (_testDuration) {
      case TestDuration.short:
        return 30;
      case TestDuration.medium:
        return 60;
      case TestDuration.long:
        return 120;
      case TestDuration.custom:
        return _customDurationSeconds;
    }
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _saveSettings();
    notifyListeners();
  }

  void setTestDuration(TestDuration duration) {
    _testDuration = duration;
    _saveSettings();
    notifyListeners();
  }

  void setTextDifficulty(TextDifficulty difficulty) {
    _textDifficulty = difficulty;
    _saveSettings();
    notifyListeners();
  }

  void setCustomDuration(int seconds) {
    _customDurationSeconds = seconds;
    _saveSettings();
    notifyListeners();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _testDuration = TestDuration.values[prefs.getInt('testDuration') ?? 1];
    _textDifficulty = TextDifficulty.values[prefs.getInt('textDifficulty') ?? 1];
    _customDurationSeconds = prefs.getInt('customDurationSeconds') ?? 60;
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setInt('testDuration', _testDuration.index);
    await prefs.setInt('textDifficulty', _textDifficulty.index);
    await prefs.setInt('customDurationSeconds', _customDurationSeconds);
  }
} 