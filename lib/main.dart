import 'package:flutter/material.dart';
import 'main_shell.dart';

void main() {
  runApp(const EcuToolkitApp());
}

class EcuToolkitApp extends StatelessWidget {
  const EcuToolkitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ECU Toolkit Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E), // VS Code Grey
        primaryColor: const Color(0xFF007ACC), // Engineer Blue
        cardColor: const Color(0xFF2D2D2D), // Lighter Grey for panels
        dividerColor: const Color(0xFF3E3E42),
        
        // Define standard Text Styles
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFCCCCCC)),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w300),
        ),
        
        // Define Button Styles
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007ACC),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        
        useMaterial3: true,
      ),
      home: const MainShell(),
    );
  }
}