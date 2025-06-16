import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../background_location_service.dart';
import '../location_storage.dart';
import '../utils/permissions.dart';
import 'preview_run_page.dart';

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
    
    // Request permissions
    if (!await requestPermissions(context)) {
      return;
    }
    
    // Record start time in ISO 8601 UTC
    final nowUtc = DateTime.now().toUtc();
    final nowStart = nowUtc.toIso8601String();
    
    setState(() {
      _startIso = nowStart;
      _startPoint = _currentPoint;
      _endPoint = null;
      _isTracking = true;
      _distance = 0;
    });
    
    // Store start time and initial point
    await LocationStorage.clearRouteData();
    await LocationStorage.setStartTime(nowStart);
    if (_currentPoint != null) {
      await LocationStorage.addRoutePoint(_currentPoint!.latitude, _currentPoint!.longitude);
    }
    
    // Start native background tracking service
    await BackgroundLocationService.start();
    
    _stopwatch.reset();
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
    
    // Setup foreground position tracking for UI updates
    _lastPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
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
      final updated = LatLng(position.latitude, position.longitude);
      _currentPoint = updated;
      _routePoints.add(updated);
      
      // Store the new point
      await LocationStorage.addRoutePoint(updated.latitude, updated.longitude);
      
      // Update map camera if the map is mounted
      if (mounted) {
        try {
          _mapController.move(updated, 15.0);
        } catch (e) {
          // Ignore map controller errors
        }
      }
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
    
    // Stop native background tracking
    BackgroundLocationService.stop();
  }

  void _finishRun() {
    // Stop tracking and send data to preview screen
    _stopTracking();
    
    // Record end time in ISO 8601 UTC
    _endIso = DateTime.now().toUtc().toIso8601String();
    
    // Clear stored route data as we're finishing the run
    LocationStorage.clearRouteData();
    
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
    ).then((result) {
      // If result is true, clear markers (run was saved or discarded)
      // If result is false, resume the run
      if (result == true) {
        setState(() {
          _startPoint = null;
          _endPoint = null;
          // Reset tracking state
          _isTracking = false;
          _isPaused = false;
          _stopwatch.reset();
          // Keep _currentPoint to maintain the blue current position marker
          // Keep _routePoints to maintain the route line
        });
      } else if (result == false) {
        // User pressed back button, resume the run in paused state
        setState(() {
          _isTracking = true;
          _isPaused = true;
        });
      }
    });
  }
  
  // pause the run (stop counters, location updates)
  void _pauseTracking() {
    setState(() {
      _isPaused = true;
    });
    
    _stopwatch.stop();
    _timer?.cancel();
    _positionSubscription?.pause();
    
    // Pause native background tracking
    BackgroundLocationService.stop();
  }

  // resume after pause
  void _resumeTracking() {
    setState(() {
      _isPaused = false;
    });
    
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    _positionSubscription?.resume();
    
    // Resume native background tracking
    BackgroundLocationService.start();
  }

  Future<void> _checkTrackingStatus() async {
    try {
      final status = await BackgroundLocationService.getStatus();
      final isTracking = status['isTracking'] as bool;
      final isPaused = status['isPaused'] as bool;
      
      if (isTracking && !_isTracking) {
        // If service is tracking but UI isn't, restore UI state
        final startTime = status['startTime'];
        final routePointsJson = status['routePoints'];
        
        if (startTime != null && routePointsJson != null) {
          // Initialize from native service data
          final routePointsList = json.decode(routePointsJson) as List;
          _routePoints.clear();
          
          for (final point in routePointsList) {
            final lat = point['latitude'] as double;
            final lng = point['longitude'] as double;
            _routePoints.add(LatLng(lat, lng));
          }
          
          if (_routePoints.isNotEmpty) {
            _currentPoint = _routePoints.last;
            _startPoint = _routePoints.first;
            
            // Calculate distance between points
            _distance = 0.0;
            for (int i = 1; i < _routePoints.length; i++) {
              _distance += Geolocator.distanceBetween(
                _routePoints[i-1].latitude, _routePoints[i-1].longitude,
                _routePoints[i].latitude, _routePoints[i].longitude,
              );
            }
            
            _startIso = startTime;
            _isPaused = isPaused;
            
            // Start/resume UI timer
            _stopwatch.reset();
            _stopwatch.start();
            
            setState(() {
              _isTracking = true;
            });
            
            _timer = Timer.periodic(const Duration(seconds: 1), (_) {
              setState(() {});
            });
            
            // Start position updates for UI
            _startPositionUpdates();
          }
        }
      }
    } catch (e) {
      print('Error checking tracking status: $e');
    }
  }
  
  void _startPositionUpdates() {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (_isPaused) return;
      
      if (_lastPosition != null) {
        final meters = Geolocator.distanceBetween(
          _lastPosition!.latitude, _lastPosition!.longitude,
          position.latitude, position.longitude,
        );
        _distance += meters;
      }
      
      _lastPosition = position;
      final updated = LatLng(position.latitude, position.longitude);
      _currentPoint = updated;
      _routePoints.add(updated);
      
      // Update map camera if the map is mounted
      if (mounted) {
        try {
          _mapController.move(updated, 15.0); // Use explicit zoom level
        } catch (e) {
          // Ignore map errors during position updates
        }
      }
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    // Initialize location and check tracking status
    _initCurrentLocation();
    _checkTrackingStatus();
  }

  Future<void> _checkForActiveRun() async {
    if (await LocationStorage.hasActiveRun()) {
      // Get route points from storage
      final points = await LocationStorage.getRoutePoints();
      if (points.isNotEmpty) {
        _routePoints.clear();
        _routePoints.addAll(points);
        _currentPoint = points.last;
        _startPoint = points.first;
        
        // Calculate distance
        _distance = await LocationStorage.calculateDistance();
        
        // Get start time and calculate elapsed time
        final startTimeStr = await LocationStorage.getStartTime();
        if (startTimeStr != null) {
          _startIso = startTimeStr;
          final startTime = DateTime.parse(startTimeStr);
          final lastTimeStr = await LocationStorage.getLastTime();
          final lastTime = lastTimeStr != null 
              ? DateTime.parse(lastTimeStr) 
              : DateTime.now();
          
          final elapsedMillis = lastTime.difference(startTime).inMilliseconds;
          _stopwatch.reset();
          _stopwatch.start();
          // Add the previously elapsed time
          for (int i = 0; i < elapsedMillis ~/ 1000; i++) {
            _stopwatch.elapsed;
          }
          
          setState(() {
            _isTracking = true;
          });
          
          // Start timer for UI updates
          _timer = Timer.periodic(const Duration(seconds: 1), (_) {
            setState(() {});
          });
          
          // Resume foreground tracking
          _resumeTracking();
        }
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionSubscription?.cancel();
    _mapController.dispose();
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
                        onMapReady: () {
                          // Map is ready for use
                          if (_currentPoint != null && mounted) {
                            try {
                              _mapController.move(_currentPoint!, 15.0);
                            } catch (e) {
                              // Ignore map controller errors during initialization
                            }
                          }
                        },
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

