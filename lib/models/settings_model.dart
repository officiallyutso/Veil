import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 0)
class Settings {
  @HiveField(0)
  bool useSystemColors;
  
  @HiveField(1)
  ThemeMode themeMode;
  
  @HiveField(2)
  bool enableJavaScript;
  
  @HiveField(3)
  bool blockTrackers;
  
  @HiveField(4)
  bool enableIncognitoByDefault;
  
  @HiveField(5)
  String defaultSearchEngine;
  
  @HiveField(6)
  bool enableFocusMode;
  
  @HiveField(7)
  int focusModeTimeLimit; // in minutes
  
  @HiveField(8)
  bool enableGestureNavigation;
  
  @HiveField(9)
  bool enableGlassMode;
  
  @HiveField(10)
  bool adaptToLighting;
  
  @HiveField(11)
  String activePersona;
  
  Settings({
    this.useSystemColors = true,
    this.themeMode = ThemeMode.system,
    this.enableJavaScript = true,
    this.blockTrackers = true,
    this.enableIncognitoByDefault = false,
    this.defaultSearchEngine = 'Google',
    this.enableFocusMode = false,
    this.focusModeTimeLimit = 30,
    this.enableGestureNavigation = true,
    this.enableGlassMode = false,
    this.adaptToLighting = false,
    this.activePersona = 'Default',
  });
}

@HiveType(typeId: 1)
class Persona {
  @HiveField(0)
  String name;
  
  @HiveField(1)
  bool blockTrackers;
  
  @HiveField(2)
  bool enableJavaScript;
  
  @HiveField(3)
  bool clearCookiesOnExit;
  
  Persona({
    required this.name,
    this.blockTrackers = true,
    this.enableJavaScript = true,
    this.clearCookiesOnExit = false,
  });
}