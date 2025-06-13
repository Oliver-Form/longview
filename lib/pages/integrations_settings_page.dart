import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'hevy_integration_page.dart';

class IntegrationsSettingsPage extends StatefulWidget {
  const IntegrationsSettingsPage({Key? key}) : super(key: key);

  @override
  _IntegrationsSettingsPageState createState() => _IntegrationsSettingsPageState();
}

class _IntegrationsSettingsPageState extends State<IntegrationsSettingsPage> {
  final _storage = const FlutterSecureStorage();
  bool _hevyConnected = false;

  @override
  void initState() {
    super.initState();
    _loadConnectionStatus();
  }

  Future<void> _loadConnectionStatus() async {
    final key = await _storage.read(key: 'hevy_api_key');
    setState(() => _hevyConnected = key != null && key.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Integrations')),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
            leading: Image.asset('assets/hevy.png', width: 70, height: 70),
            title: const Text('Hevy'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _hevyConnected ? Icons.check : Icons.close,
                  color: _hevyConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  _hevyConnected ? 'Connected' : 'Not connected',
                  style: TextStyle(
                    color: _hevyConnected ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HevyIntegrationPage(),
                ),
              );
              _loadConnectionStatus();
            },
          ),
          const Divider(),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
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

