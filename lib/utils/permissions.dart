import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Request all required permissions for the app
Future<bool> requestPermissions(BuildContext context) async {
  // Location permissions
  final locationStatus = await Permission.location.request();
  if (locationStatus != PermissionStatus.granted) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is required')),
      );
    }
    return false;
  }
  
  // Background location permissions
  final backgroundStatus = await Permission.locationAlways.request();
  if (backgroundStatus != PermissionStatus.granted) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Background location permission is required for tracking when app is in background')),
      );
    }
    return false;
  }
  
  return true;
}
