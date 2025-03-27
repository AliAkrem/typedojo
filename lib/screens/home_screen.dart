import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:typedojo/models/settings_model.dart';
import 'package:typedojo/screens/typing_test_screen.dart';
import 'package:typedojo/screens/settings_screen.dart';
import 'package:typedojo/screens/leaderboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: settings.isDarkMode
                ? [Colors.blueGrey.shade900, Colors.black]
                : [Colors.blue.shade300, Colors.blue.shade700],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo or App Name
                Icon(
                  Icons.keyboard,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                
                // Title
                Text(
                  'TypeDojo',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                
                // Subtitle
                Text(
                  'Test Your Typing Speed!',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 60),
                
                // Start Button
                _buildButton(
                  context,
                  'Start Typing Test',
                  Icons.play_arrow,
                  () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (context) => const TypingTestScreen(),
                      ),
                    );
                  },
                  Colors.green,
                ),
                const SizedBox(height: 20),
                
                // Leaderboard Button
                _buildButton(
                  context,
                  'Leaderboard',
                  Icons.leaderboard,
                  () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (context) => const LeaderboardScreen(),
                      ),
                    );
                  },
                  Colors.amber,
                ),
                const SizedBox(height: 20),
                
                // Settings Button
                _buildButton(
                  context,
                  'Settings',
                  Icons.settings,
                  () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                  Colors.deepPurple,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, 
    String text, 
    IconData icon, 
    VoidCallback onPressed,
    Color color,
  ) {
    return SizedBox(
      width: 250,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 