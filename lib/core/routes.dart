import 'package:flutter/material.dart';
import 'package:veil/screens/browser_screen.dart';
import 'package:veil/screens/settings_screen.dart';
import 'package:veil/screens/bookmarks_screen.dart';
import 'package:veil/screens/history_screen.dart';
import 'package:veil/screens/sessions_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String settings = '/settings';
  static const String bookmarks = '/bookmarks';
  static const String history = '/history';
  static const String sessions = '/sessions';
  static const String notes = '/notes';
  static const String receipts = '/receipts';
  
  static Map<String, WidgetBuilder> get routes => {
    home: (context) => const BrowserScreen(),
    settings: (context) => const SettingsScreen(),
    bookmarks: (context) => const BookmarksScreen(),
    history: (context) => const HistoryScreen(),
    sessions: (context) => const SessionsScreen(),
  };
}