import 'dart:convert';
import 'package:flutter/services.dart';

class BackgroundLocationService {
  static const MethodChannel _channel = MethodChannel('stride/tracking');

  /// (No-op on Flutter side init; Android handles service setup)
  static Future<void> init() async {}

  /// Start native background tracking service
  static Future<void> start() async {
    await _channel.invokeMethod('startTracking');
  }

  /// Stop native background tracking service
  static Future<void> stop() async {
    await _channel.invokeMethod('stopTracking');
  }

  /// Pause tracking
  static Future<void> pause() async {
    await _channel.invokeMethod('pauseTracking');
  }

  /// Resume tracking
  static Future<void> resume() async {
    await _channel.invokeMethod('resumeTracking');
  }

  /// Get current tracking status
  static Future<Map<String, dynamic>> getStatus() async {
    final String response = await _channel.invokeMethod('getTrackingStatus');
    return json.decode(response);
  }
}