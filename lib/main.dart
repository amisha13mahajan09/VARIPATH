import 'package:flutter/material.dart';
import 'starter_screen.dart';
import 'services/app_language.dart';

void main() {
  runApp(const VariPathApp());
}

class VariPathApp extends StatelessWidget {
  const VariPathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appLanguageNotifier,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'वारी-पथ',
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Lexend',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2D4678),
            ),
          ),
          home: const StarterScreen(),
        );
      },
    );
  }
}