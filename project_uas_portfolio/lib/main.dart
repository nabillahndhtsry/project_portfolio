import 'package:flutter/material.dart';
import 'home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Portfolio Nabillah', // (c) Judul Aplikasi
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: const HomeScreen(), // LANGSUNG BUKA HOME, BUKAN LOGIN
    );
  }
}