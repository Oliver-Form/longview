import 'package:flutter/material.dart';
import 'map_appearance_settings_page.dart';

class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appearance Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Map Appearance'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MapAppearanceSettingsPage(),
                ),
              );
            },
          ),
          const Divider(),
        ],
      ),
    );
  }
}