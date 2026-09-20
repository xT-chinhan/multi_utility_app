import 'package:flutter/material.dart';
import 'services/audio_alarm_service.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AudioAlarmService.instance.init();
  runApp(const SmartUtilityApp());
}

class SmartUtilityApp extends StatefulWidget {
  const SmartUtilityApp({super.key});

  @override
  State<SmartUtilityApp> createState() => _SmartUtilityAppState();
}

class _SmartUtilityAppState extends State<SmartUtilityApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Utility Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: MainScreen(
        onToggleTheme: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}
