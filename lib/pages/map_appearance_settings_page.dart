import 'package:flutter/material.dart';

class MapAppearanceSettingsPage extends StatelessWidget {
  const MapAppearanceSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map appearance')),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          const Divider(),
          
        ],
      ),
    );
  }
}