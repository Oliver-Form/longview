import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'preview_run_page.dart'; // Import the new PreviewRunPage

class RecordPage extends StatefulWidget {
  const RecordPage({Key? key}) : super(key: key);

  @override
  _RecordPageState createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> with AutomaticKeepAliveClientMixin<RecordPage> {
  bool _isTracking = false;
  bool _isPaused = false;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  StreamSubscription<Position>? _positionSubscription;
  Position? _lastPosition;
  double _distance = 0.0;
  LatLng? _currentPoint;
  LatLng? _startPoint;
  LatLng? _endPoint;
  final MapController _mapController = MapController();
  final List<LatLng> _routePoints = [];

  String _startIso = '';
  String _endIso = '';

  String get _formattedTime {
    final duration = _stopwatch.elapsed;
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  String get _formattedDistance {
    final km = _distance / 1000;
    return "${km.toStringAsFixed(2)} km";
  }

  String get _formattedPace {
    if (_distance > 0) {
      final paceSeconds = _stopwatch.elapsed.inSeconds / (_distance / 1000);
      final minutes = paceSeconds ~/ 60;
      final seconds = (paceSeconds % 60).round();
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      return "$minutes'${twoDigits(seconds)}\" /km";
    } else {
      return "--'--\" /km";
    }
  }

  Future<void> _initCurrentLocation() async {
    try {
      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _currentPoint = LatLng(pos.latitude, pos.longitude);
      _routePoints.clear();
      _routePoints.add(_currentPoint!);
      setState(() {});
    } catch (e) {
      // handle error
    }
  }

  Future<void> _startTracking() async {
    _isPaused = false;
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
    // record start time in ISO 8601 UTC
    final nowStart = DateTime.now().toUtc().toIso8601String();
    setState(() {
      _startIso = nowStart;
      // place green circle at start location
      _startPoint = _currentPoint;
      _endPoint = null;
      _isTracking = true;
      _distance = 0;
    });
    _stopwatch.reset();
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
    _lastPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
        intervalDuration: const Duration(milliseconds: 500),
      ),
    ).listen((Position position) async {
      if (_lastPosition != null) {
        final meters = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        _distance += meters;
      }
      _lastPosition = position;
      // update current location and map marker
      final updated = LatLng(position.latitude, position.longitude);
      _currentPoint = updated;
      _routePoints.add(updated);
      // update camera via flutter_map controller
      _mapController.move(updated, _mapController.zoom);
      setState(() {});
    });
  }

  // fully stop and mark end of run
  void _stopTracking() {
    setState(() {
      _isTracking = false;
      // place red square at stop location
      _endPoint = _currentPoint;
    });
    _stopwatch.stop();
    _timer?.cancel();
    _positionSubscription?.cancel();
  }

  void _finishRun() {
    // Stop tracking and send data to preview screen
    _stopTracking();
    // record end time in ISO 8601 UTC
    _endIso = DateTime.now().toUtc().toIso8601String();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewRunPage(
          routePoints: _routePoints,
          formattedTime: _formattedTime,
          formattedDistance: _formattedDistance,
          startTime: _startIso,
          endTime: _endIso,
        ),
      ),
    );
  }
  
  // pause the run (stop counters, location updates)
  void _pauseTracking() {
    setState(() {
      _isPaused = true;
    });
    _stopwatch.stop();
    _timer?.cancel();
    _positionSubscription?.pause();
  }

  // resume after pause
  void _resumeTracking() {
    setState(() {
      _isPaused = false;
    });
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    _positionSubscription?.resume();
  }

  @override
  void initState() {
    super.initState();
    _initCurrentLocation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _currentPoint == null
                  ? const Center(child: CircularProgressIndicator())
                  : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        center: _currentPoint!,
                        zoom: 15.0,
                        // restrict zoom levels to prevent blank tiles
                        minZoom: 5.0,
                        maxZoom: 18.0,
                        // disable rotation gestures
                        interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                          subdomains: ['a', 'b', 'c', 'd'],
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              color: Colors.blue,
                              strokeWidth: 4.0,
                              isDotted: true,
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            if (_startPoint != null)
                              Marker(
                                point: _startPoint!,
                                builder: (_) => Icon(Icons.circle, color: Colors.green, size: 20),
                              ),
                            if (_currentPoint != null)
                              Marker(
                                point: _currentPoint!,
                                builder: (_) => Icon(Icons.circle, color: Colors.blue, size: 20),
                              ),
                            if (_endPoint != null)
                              Marker(
                                point: _endPoint!,
                                builder: (_) => Icon(Icons.stop, color: Colors.red, size: 20),
                              ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            // Bottom controls: big Start button initially, otherwise Pause/Resume + Finish
            if (!_isTracking) ...[
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                  onPressed: _startTracking,
                  child: const Text('Start', style: TextStyle(fontSize: 18)),
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(_formattedTime, style: Theme.of(context).textTheme.headlineMedium),
                    Text(_formattedDistance, style: Theme.of(context).textTheme.headlineMedium),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(_formattedPace, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isPaused ? _resumeTracking : _pauseTracking,
                    icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                    label: const Text(''),
                  ),
                  ElevatedButton(
                    onPressed: _finishRun,
                    child: const Text('Finish'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
} 

// 