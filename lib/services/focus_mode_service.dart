import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FocusModeService extends ChangeNotifier {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  late SharedPreferences _prefs;
  
  bool _isActive = false;
  DateTime? _startTime;
  Timer? _timer;
  int _timeLimit = 30; // minutes
  List<String> _allowedDomains = [];
  String? _currentDomain;
  Map<String, int> _domainTimeSpent = {};
  
  bool get isActive => _isActive;
  int get timeLimit => _timeLimit;
  List<String> get allowedDomains => _allowedDomains;
  Map<String, int> get domainTimeSpent => _domainTimeSpent;
  
  Future<void> initialize() async {
    // Initialize notifications
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
    
    // Load saved data
    _prefs = await SharedPreferences.getInstance();
    _isActive = _prefs.getBool('focus_mode_active') ?? false;
    _timeLimit = _prefs.getInt('focus_mode_time_limit') ?? 30;
    _allowedDomains = _prefs.getStringList('focus_mode_allowed_domains') ?? [];
    
    // Load domain time spent
    final Map<String, dynamic>? savedTimeSpent = 
        _prefs.getString('focus_mode_domain_time_spent') != null 
            ? Map<String, dynamic>.from(
                Map<String, dynamic>.from(_prefs.getString('focus_mode_domain_time_spent') as Map)
              ) 
            : null;
    
    if (savedTimeSpent != null) {
      _domainTimeSpent = savedTimeSpent.map((key, value) => MapEntry(key, value as int));
    }
    
    // Restart timer if focus mode was active
    if (_isActive) {
      _startFocusMode();
    }
  }
  
  Future<void> startFocusMode({int? timeLimit, List<String>? allowedDomains}) async {
    if (timeLimit != null) {
      _timeLimit = timeLimit;
      await _prefs.setInt('focus_mode_time_limit', timeLimit);
    }
    
    if (allowedDomains != null) {
      _allowedDomains = allowedDomains;
      await _prefs.setStringList('focus_mode_allowed_domains', allowedDomains);
    }
    
    _isActive = true;
    _startTime = DateTime.now();
    await _prefs.setBool('focus_mode_active', true);
    
    _startFocusMode();
    notifyListeners();
  }
  
  void _startFocusMode() {
    // Start a timer to check domain usage
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentDomain != null) {
        _updateDomainTime(_currentDomain!);
      }
    });
  }
  
  Future<void> stopFocusMode() async {
    _isActive = false;
    _timer?.cancel();
    _timer = null;
    
    await _prefs.setBool('focus_mode_active', false);
    
    // Save domain time spent
    await _saveDomainTimeSpent();
    
    notifyListeners();
  }
  
  void updateCurrentDomain(String url) {
    if (!_isActive) return;
    
    final Uri uri = Uri.parse(url);
    final String domain = uri.host;
    
    if (_currentDomain != domain) {
      // Save time for previous domain
      if (_currentDomain != null) {
        _updateDomainTime(_currentDomain!);
      }
      
      _currentDomain = domain;
      
      // Check if domain is allowed
      if (_allowedDomains.isNotEmpty && !_allowedDomains.contains(domain)) {
        _showOffTaskNotification(domain);
      }
    }
  }
  
  void _updateDomainTime(String domain) {
    final int currentTime = _domainTimeSpent[domain] ?? 0;
    _domainTimeSpent[domain] = currentTime + 5; // Add 5 seconds
  }
  
  Future<void> _saveDomainTimeSpent() async {
    await _prefs.setString('focus_mode_domain_time_spent', _domainTimeSpent.toString());
  }
  
  Future<void> _showOffTaskNotification(String domain) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'focus_mode_channel',
      'Focus Mode Notifications',
      channelDescription: 'Notifications for Focus Mode',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    
    await _notifications.show(
      0,
      'Off Task Alert',
      'You are browsing $domain which is not in your allowed list.',
      details,
    );
  }
  
  Map<String, int> getDomainTimeReport() {
    return _domainTimeSpent;
  }
  
  void resetDomainTimeReport() {
    _domainTimeSpent.clear();
    _saveDomainTimeSpent();
    notifyListeners();
  }
}