import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'main_shell.dart';
import 'native/ttctk.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    // Print to console and also forward to default error handler
    debugPrint('Flutter error: ${details.exceptionAsString()}');
    FlutterError.presentError(details);
  };

  debugPrint('Starting EcuToolkitApp');

  // Initialize native libraries here
  TTCTK.instance.loadLibrary();

  // If the native ttctk library failed to load, show an error window and do not start the main app.
  if (!TTCTK.instance.available) {
    runApp(const _ToolkitMissingApp());
    return;
  }

  // Initialize the toolkit (logging, environment). Treat non-zero return as error.
  final initStatus = TTCTK.instance.initLibrary(5, null); // Log level 5 (debug), no log file
  if (initStatus != 0) {
    runApp(_ToolkitInitFailedApp(status: initStatus));
    return;
  }

  runApp(const EcuToolkitApp());
}

class _ToolkitMissingApp extends StatelessWidget {
  const _ToolkitMissingApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ECU Toolkit Studio - Missing Library',
      home: Scaffold(
        appBar: AppBar(title: const Text('ECU Toolkit Studio')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 12),
                const Text('TTC Toolkit library not found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('The native TTC Toolkit library could not be loaded.\nPlease ensure the toolkit is installed and the runtime library is available for this application.', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => io.exit(1),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolkitInitFailedApp extends StatelessWidget {
  final int status;
  const _ToolkitInitFailedApp({required this.status});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ECU Toolkit Studio - Initialization Failed',
      home: Scaffold(
        appBar: AppBar(title: const Text('ECU Toolkit Studio')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 12),
                const Text('TTC Toolkit initialization failed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Toolkit initialization returned status code: $status', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => io.exit(1),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EcuToolkitApp extends StatefulWidget {
  const EcuToolkitApp({super.key});

  @override
  State<EcuToolkitApp> createState() => _EcuToolkitAppState();
}

class _EcuToolkitAppState extends State<EcuToolkitApp> {
  ThemeMode _themeMode = ThemeMode.light;

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