import 'package:flutter/material.dart';

class IntegrationsSettingsPage extends StatelessWidget {
  const IntegrationsSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Integrations')),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          ListTile(
            leading: Image.asset('assets/hevy.png', width: 40, height: 40),
            title: const Text('Hevy'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.close, color: Colors.red),
                SizedBox(width: 4),
                Text('Not connected', style: TextStyle(color: Colors.red)),
              ],
            ),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: Image.asset('assets/strava.png', width: 40, height: 40),
            title: const Text('Strava'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.close, color: Colors.red),
                SizedBox(width: 4),
                Text('Not connected', style: TextStyle(color: Colors.red)),
              ],
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// ok, in 