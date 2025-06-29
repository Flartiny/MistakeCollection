import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mistake_collection/providers/mistake_provider.dart';
import 'package:mistake_collection/screens/home_screen.dart';
import 'package:mistake_collection/screens/add_mistake_screen.dart';
import 'package:mistake_collection/screens/mistake_book_screen.dart';
import 'package:mistake_collection/screens/review_screen.dart';
import 'package:mistake_collection/screens/settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MistakeProvider(),
      child: MaterialApp(
        title: '错题收集',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/add': (context) => const AddMistakeScreen(),
          '/book': (context) => const MistakeBookScreen(),
          '/review': (context) => const ReviewScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
} 