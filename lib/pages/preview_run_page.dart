import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stride/models/run.dart';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class PreviewRunPage extends StatefulWidget {
  final List<LatLng> routePoints;
  final String formattedTime;
  final String formattedDistance;
  final String startTime;
  final String endTime;

  const PreviewRunPage({
    Key? key,
    required this.routePoints,
    required this.formattedTime,
    required this.formattedDistance,
    required this.startTime,
    required this.endTime,
  }) : super(key: key);

  @override
  State<PreviewRunPage> createState() => _PreviewRunPageState();
}

class _PreviewRunPageState extends State<PreviewRunPage> {
  final GlobalKey _mapKey = GlobalKey();
  ui.Image? _mapImage;
  String _imagePath = '';
  final TextEditingController _commentController = TextEditingController();
  final _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    // no pre-capture; image will be captured on Save
  }

  Future<void> _captureMapImage() async {
    try {
      RenderRepaintBoundary? boundary = _mapKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('RepaintBoundary not found for map snapshot');
        return;
      }
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      setState(() => _mapImage = image);
      // optionally write PNG to disk
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/run_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      setState(() => _imagePath = file.path);
    } catch (e, st) {
      debugPrint('Error in _captureMapImage: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview Run')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Time: ${widget.formattedTime}', style: Theme.of(context).textTheme.headlineSmall),
            Text('Distance: ${widget.formattedDistance}', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 200,
              child: RepaintBoundary(
                key: _mapKey,
                child: FlutterMap(
                  options: MapOptions(
                    interactiveFlags: InteractiveFlag.none,
                    bounds: LatLngBounds.fromPoints(widget.routePoints),
                    boundsOptions: FitBoundsOptions(padding: EdgeInsets.all(12)),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                      subdomains: ['a','b','c','d'],
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(points: widget.routePoints, color: Colors.blue, strokeWidth: 4.0),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(labelText: 'Add your comments'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                // capture snapshot
                await _captureMapImage();
                // save run locally
                final prefs = await SharedPreferences.getInstance();
                final existing = prefs.getString('runs') ?? '[]';
                final list = Run.listFromJson(existing);
                final runCount = list.length + 1;
                list.add(Run(
                  startTime: widget.startTime,
                  endTime: widget.endTime,
                  time: widget.formattedTime,
                  distance: widget.formattedDistance,
                  imagePath: _imagePath,
                  comment: _commentController.text,
                ));
                await prefs.setString('runs', Run.listToJson(list));
                // post to Hevy API if connected
                final key = await _secureStorage.read(key: 'hevy_api_key');
                if (key != null && key.isNotEmpty) {
                  // parse duration seconds
                  final parts = widget.formattedTime.split(':');
                  final durationSeconds = int.parse(parts[0]) * 3600 + int.parse(parts[1]) * 60 + int.parse(parts[2]);
                  // parse distance meters
                  final kmValue = double.tryParse(widget.formattedDistance.split(' ').first) ?? 0.0;
                  final distanceMeters = (kmValue * 1000).round();
                  // prepare payload per Hevy API spec
                  final payload = {
                    'workout': {
                      'title': 'Longview run #$runCount',
                      'description': _commentController.text,
                      'start_time': widget.startTime,
                      'end_time': widget.endTime,
                      'is_private': false,
                      'exercises': [
                        {
                          'exercise_template_id': 'AC1BB830',
                          'superset_id': null,
                          'sets': [
                            {
                              'type': 'normal',
                              'weight_kg': null,
                              'reps': null,
                              'distance_meters': distanceMeters,
                              'duration_seconds': durationSeconds,
                              'custom_metric': null,
                              'rpe': null,
                            }
                          ],
                        }
                      ],
                    },
                  };
                  final response = await http.post(
                    Uri.parse('https://api.hevyapp.com/v1/workouts'),
                    headers: {
                      'accept': 'application/json',
                      'api-key': key,
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode(payload),
                  );
                  if (response.statusCode != 201) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('201 not returned')),
                    );
                  }
                }
                Navigator.pop(context);
              },
              child: const Text('Save Run'),
            ),
          ],
        ),
      ),
    );
  }
}

// add 