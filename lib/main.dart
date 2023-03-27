import 'package:flutter/material.dart';
import 'home.dart';

void main() {
  runApp(const MyApp());
}

const String ssd = "SSD MobileNet";

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "Find My Dog",
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}
