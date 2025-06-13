import 'package:flutter/material.dart';

class IntegrationsSettingsPage extends StatelessWidget {
  const IntegrationsSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Integrations')),
      body: Center(
        child: Text(
          'Integrations settings go here',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
