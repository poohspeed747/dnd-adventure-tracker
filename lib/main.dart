// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../graph_provider.dart';
import '../home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => GraphProvider()..tryLoadAutoSave(),
      child: const DndMapApp(),
    ),
  );
}

class DndMapApp extends StatelessWidget {
  const DndMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'D&D Adventure Map',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1F6FEB),
          surface: Color(0xFF161B22),
        ),
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Color(0xFF58A6FF),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF1F6FEB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF1F2937),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
