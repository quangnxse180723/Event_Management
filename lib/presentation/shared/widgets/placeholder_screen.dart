import 'package:flutter/material.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              'Chức năng "$title" đang được phát triển.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}