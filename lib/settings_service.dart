import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  bool enablePhotoBackground;
  String? photoBackgroundPath;
  double backgroundOpacity;
  double controlOpacity;
  
  Color accentColor;
  bool enableCustomColor;
  bool isDarkMode;
  
  bool simulateFluentDesign;

  AppSettings({
    this.enablePhotoBackground = false,
    this.photoBackgroundPath,
    this.backgroundOpacity = 0.4,
    this.controlOpacity = 0.92,
    this.accentColor = const Color(0xFFD0BCFF),
    this.enableCustomColor = false,
    this.isDarkMode = true,
    this.simulateFluentDesign = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'enablePhotoBackground': enablePhotoBackground,
      'photoBackgroundPath': photoBackgroundPath,
      'backgroundOpacity': backgroundOpacity,
      'controlOpacity': controlOpacity,
      'accentColor': accentColor.value,
      'enableCustomColor': enableCustomColor,
      'isDarkMode': isDarkMode,
      'simulateFluentDesign': simulateFluentDesign,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      enablePhotoBackground: json['enablePhotoBackground'] ?? false,
      photoBackgroundPath: json['photoBackgroundPath'],
      backgroundOpacity: json['backgroundOpacity'] ?? 0.4,
      controlOpacity: json['controlOpacity'] ?? 0.92,
      accentColor: Color(json['accentColor'] ?? 0xFFD0BCFF),
      enableCustomColor: json['enableCustomColor'] ?? false,
      isDarkMode: json['isDarkMode'] ?? true,
      simulateFluentDesign: json['simulateFluentDesign'] ?? false,
    );
  }
}

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  late SharedPreferences _prefs;
  AppSettings _settings = AppSettings();
  
  AppSettings get settings => _settings;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
  }

  void _loadSettings() {
    final jsonString = _prefs.getString('app_settings');
    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString);
        _settings = AppSettings.fromJson(json);
        notifyListeners();
      } catch (e) {
        debugPrint('加载设置失败: $e');
      }
    }
  }

  Future<void> _saveSettings() async {
    final jsonString = jsonEncode(_settings.toJson());
    await _prefs.setString('app_settings', jsonString);
    notifyListeners();
  }

  void setEnablePhotoBackground(bool value) {
    _settings.enablePhotoBackground = value;
    _saveSettings();
  }

  void setPhotoBackgroundPath(String? path) {
    _settings.photoBackgroundPath = path;
    _saveSettings();
  }

  void setPhotoBackground(String? path) {
    _settings.photoBackgroundPath = path;
    _saveSettings();
  }

  void setBackgroundOpacity(double value) {
    _settings.backgroundOpacity = value;
    _saveSettings();
  }

  void setControlOpacity(double value) {
    _settings.controlOpacity = value;
    _saveSettings();
  }

  void setAccentColor(Color color) {
    _settings.accentColor = color;
    _saveSettings();
  }

  void setEnableCustomColor(bool value) {
    _settings.enableCustomColor = value;
    _saveSettings();
  }

  void setIsDarkMode(bool value) {
    _settings.isDarkMode = value;
    _saveSettings();
  }

  void setDarkMode(bool value) {
    _settings.isDarkMode = value;
    _saveSettings();
  }

  void setSimulateFluentDesign(bool value) {
    _settings.simulateFluentDesign = value;
    _saveSettings();
  }

  void resetToDefaults() {
    _settings = AppSettings();
    _saveSettings();
  }
}
