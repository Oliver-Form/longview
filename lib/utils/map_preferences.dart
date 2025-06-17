import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class MapPreferences {
  static final StreamController<void> _onChangeController = StreamController<void>.broadcast();

  /// Stream that emits when map preferences change
  static Stream<void> get onChange => _onChangeController.stream;
  
  static const String _darkModeKey = 'map_dark_mode';
  static const String _showLabelsKey = 'map_show_labels';
  
  /// Save map dark mode preference
  static Future<void> setDarkMode(bool darkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, darkMode);
    _onChangeController.add(null);
  }
  
  /// Get map dark mode preference
  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? true; // Default to dark mode
  }
  
  /// Save map labels preference
  static Future<void> setShowLabels(bool showLabels) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showLabelsKey, showLabels);
    _onChangeController.add(null);
  }
  
  /// Get map labels preference
  static Future<bool> getShowLabels() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showLabelsKey) ?? true; // Default to showing labels
  }
  
  /// Get the appropriate URL template based on current preferences
  static Future<String> getMapUrlTemplate() async {
    final darkMode = await getDarkMode();
    final showLabels = await getShowLabels();
    
    if (darkMode) {
      return showLabels 
          ? 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
          : 'https://basemaps.cartocdn.com/rastertiles/dark_nolabels/{z}/{x}/{y}.png';
    } else {
      return showLabels 
          ? 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png'
          : 'https://basemaps.cartocdn.com/rastertiles/light_nolabels/{z}/{x}/{y}.png';
    }
  }
}
