import 'package:flutter/material.dart';
import 'package:md_codebar_scanner/screens/main_screens.dart';
import 'package:md_codebar_scanner/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barcode Scanner',
      theme: AppTheme.lightTheme,
      home: MainScreen(),
    );
  }
}
