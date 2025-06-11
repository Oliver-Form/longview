import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({Key? key}) : super(key: key);

  @override
  _RecordPageState createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  bool _isTracking = false;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  StreamSubscription<Position>? _positionSubscription;
  Position? _lastPosition;
  double _distance = 0.0;
  GeoPoint? _currentPoint;
  final MapController _osmController = MapController.withUserPosition(trackUserLocation: const UserTrackingOption(enableTracking: false, unFollowUser: false));

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
      _currentPoint = GeoPoint(latitude: pos.latitude, longitude: pos.longitude);
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
    ).listen((Position position) {
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
      // update current location
      _currentPoint = GeoPoint(latitude: position.latitude, longitude: position.longitude);
      // center map on new position
      _osmController.changeLocation(_currentPoint!);
      setState(() {});
    });
  }

  void _stopTracking() {
    setState(() {
      _isTracking = false;
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _currentPoint == null
                  ? const Center(child: CircularProgressIndicator())
                  : OSMFlutter(
                      controller: _osmController,
                      osmOption: OSMOption(
                        showZoomController: true,
                        zoomOption: ZoomOption(
                          initZoom: 15.0,
                          minZoomLevel: 3.0,
                          maxZoomLevel: 18.0,
                          stepZoom: 1.0,
                        ),
                        userLocationMarker: UserLocationMaker(
                          personMarker: MarkerIcon(
                            icon: Icon(
                              Icons.my_location,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          directionArrowMarker: MarkerIcon(
                            icon: Icon(
                              Icons.navigation,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                        staticPoints: [
                          StaticPositionGeoPoint(
                            'current',
                            MarkerIcon(
                              icon: Icon(
                                Icons.my_location,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            // wrap in list for multiple points
                            [_currentPoint!],
                          ),
                        ],
                      ),
                      onLocationChanged: (GeoPoint point) {
                        // optional callback when location updates
                      },
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

