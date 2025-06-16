import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';

class LocationStorage {
  static const String _routePointsKey = 'routePoints';
  static const String _startTimeKey = 'startTimestamp';
  static const String _lastTimeKey = 'lastTimestamp';
  
  /// Store a new route point
  static Future<void> addRoutePoint(double latitude, double longitude) async {
    final prefs = await SharedPreferences.getInstance();
    final routeJson = prefs.getString(_routePointsKey) ?? '[]';
    final List<dynamic> points = json.decode(routeJson);
    
    points.add({
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    await prefs.setString(_routePointsKey, json.encode(points));
    await prefs.setString(_lastTimeKey, DateTime.now().toIso8601String());
  }
  
  /// Get all stored route points
  static Future<List<LatLng>> getRoutePoints() async {
    final prefs = await SharedPreferences.getInstance();
    final routeJson = prefs.getString(_routePointsKey) ?? '[]';
    final List<dynamic> points = json.decode(routeJson);
    
    return points.map<LatLng>((point) {
      return LatLng(point['latitude'], point['longitude']);
    }).toList();
  }
  
  /// Store the run start time
  static Future<void> setStartTime(String isoTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_startTimeKey, isoTime);
  }
  
  /// Get the stored start time
  static Future<String?> getStartTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_startTimeKey);
  }
  
  /// Get the stored last time update
  static Future<String?> getLastTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastTimeKey);
  }
  
  /// Calculate total distance from stored route points
  static Future<double> calculateDistance() async {
    final points = await getRoutePoints();
    if (points.length < 2) return 0.0;
    
    double totalDistance = 0.0;
    final Distance distance = Distance();
    
    for (int i = 1; i < points.length; i++) {
      totalDistance += distance.as(
        LengthUnit.Meter,
        points[i-1],
        points[i],
      );
    }
    
    return totalDistance;
  }
  
  /// Clear all stored route data
  static Future<void> clearRouteData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_routePointsKey);
    await prefs.remove(_startTimeKey);
    await prefs.remove(_lastTimeKey);
  }
  
  /// Check if there's an active run
  static Future<bool> hasActiveRun() async {
    final startTime = await getStartTime();
    return startTime != null;
  }
}
