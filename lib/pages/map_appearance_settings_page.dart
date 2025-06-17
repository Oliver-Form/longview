import 'package:flutter/material.dart';
import '../utils/map_preferences.dart';

class MapAppearanceSettingsPage extends StatefulWidget {
  const MapAppearanceSettingsPage({Key? key}) : super(key: key);

  @override
  State<MapAppearanceSettingsPage> createState() => _MapAppearanceSettingsPageState();
}

class _MapAppearanceSettingsPageState extends State<MapAppearanceSettingsPage> {
  bool _isDarkMode = true;
  bool _showLabels = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final darkMode = await MapPreferences.getDarkMode();
    final showLabels = await MapPreferences.getShowLabels();
    
    setState(() {
      _isDarkMode = darkMode;
      _showLabels = showLabels;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map appearance')),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
          children: [
            const SizedBox(height: 16),
            const Divider(),
            SwitchListTile(
              title: const Text('Dark mode'),
              subtitle: const Text('Toggle between dark and light map theme'),
              value: _isDarkMode,
              onChanged: (value) async {
                await MapPreferences.setDarkMode(value);
                setState(() => _isDarkMode = value);
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Show labels'),
              subtitle: const Text('Toggle map labels visibility'),
              value: _showLabels,
              onChanged: (value) async {
                await MapPreferences.setShowLabels(value);
                setState(() => _showLabels = value);
              },
            ),
            const Divider(),
          ],
        ),
    );
  }
}

