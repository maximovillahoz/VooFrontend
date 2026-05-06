import 'package:flutter/material.dart';
import '../screens/welcome/welcome_screen.dart';

class VooApp extends StatelessWidget {
  const VooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VOO',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0B0B0F),
      ),
      home: const WelcomeScreen(),
    );
  }
}