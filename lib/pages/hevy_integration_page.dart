import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HevyIntegrationPage extends StatefulWidget {
  const HevyIntegrationPage({Key? key}) : super(key: key);

  @override
  _HevyIntegrationPageState createState() => _HevyIntegrationPageState();
}

class _HevyIntegrationPageState extends State<HevyIntegrationPage> {
  final _storage = const FlutterSecureStorage();
  final _controller = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    final key = await _storage.read(key: 'hevy_api_key');
    if (key != null) {
      _controller.text = key;
    }
    setState(() => _loading = false);
  }

  Future<void> _saveKey() async {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      await _storage.write(key: 'hevy_api_key', value: text);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hevy Integration')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'API Key',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saveKey,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
    );
  }
}

