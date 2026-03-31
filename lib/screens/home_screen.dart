import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskTracker'),
      ),
      body: const Center(
        child: Text('Home Screen - To be implemented'),
      ),
    );
  }
}