import 'package:flutter/material.dart';
import 'general_settings_page.dart';

class GeneralSettingsPage extends StatelessWidget {
  const GeneralSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('General')),
      body: Center(
        child: Text(
          'General settings go here',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
