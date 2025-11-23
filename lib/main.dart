import 'package:flutter/material.dart';
import 'main_shell.dart';

void main() {
  runApp(const EcuToolkitApp());
}

class EcuToolkitApp extends StatefulWidget {
  const EcuToolkitApp({super.key});

  @override
  State<EcuToolkitApp> createState() => _EcuToolkitAppState();
}

class _EcuToolkitAppState extends State<EcuToolkitApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1E1E1E), // VS Code Grey
      primaryColor: const Color(0xFF007ACC), // Engineer Blue
      cardColor: const Color(0xFF2D2D2D), // Lighter Grey for panels
      dividerColor: const Color(0xFF3E3E42),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Color(0xFFCCCCCC)),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w300),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF007ACC),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      useMaterial3: true,
    );

    final lightTheme = ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      primaryColor: const Color(0xFF007ACC),
      cardColor: const Color(0xFFF5F5F5),
      dividerColor: const Color(0xFFE0E0E0),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Color(0xFF222222)),
        titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.w300),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF007ACC),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'ECU Toolkit Studio',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: MainShell(onToggleTheme: _toggleTheme, isDark: _themeMode == ThemeMode.dark),
    );
  }
}