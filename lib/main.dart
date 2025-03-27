import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:typedojo/models/settings_model.dart';
import 'package:typedojo/models/typing_test_service.dart';
import 'package:typedojo/screens/home_screen.dart';
import 'package:typedojo/services/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  try {
    await DatabaseHelper.instance.database;
    print('Database initialized successfully');
  } catch (e) {
    print('Error initializing database: $e');
  }
  
  // Initialize settings
  final settingsModel = SettingsModel();
  await settingsModel.loadSettings();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => settingsModel),
        ChangeNotifierProvider(create: (context) => TypingTestService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context);
    
    return MaterialApp(
      title: 'TypeDojo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
    );
  }
}
