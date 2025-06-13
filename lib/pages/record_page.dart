import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({Key? key}) : super(key: key);

  @override
  _RecordPageState createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> with AutomaticKeepAliveClientMixin<RecordPage> {
  bool _isTracking = false;
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
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
    setState(() {
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    _formattedTime,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    _formattedDistance,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isTracking ? _stopTracking : _startTracking,
              child: Text(_isTracking ? 'Stop' : 'Start'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

