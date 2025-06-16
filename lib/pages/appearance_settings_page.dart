import 'package:flutter/material.dart';

class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: Center(
        child: Text(
          'Appearance settings go here',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
