import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app_theme.dart';
import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('faceBox');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Face Recognition App',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}