import 'package:flutter/material.dart';
import 'package:veil/features/browser/browser_screen.dart';
import 'package:veil/features/settings/settings_screen.dart';
import 'package:veil/features/bookmarks/bookmarks_screen.dart';
import 'package:veil/features/history/history_screen.dart';
import 'package:veil/features/sessions/sessions_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String settings = '/settings';
  static const String bookmarks = '/bookmarks';
  static const String history = '/history';
  static const String sessions = '/sessions';
  
  static Map<String, WidgetBuilder> get routes => {
    home: (context) => const BrowserScreen(),
    settings: (context) => const SettingsScreen(),
    bookmarks: (context) => const BookmarksScreen(),
    history: (context) => const HistoryScreen(),
    sessions: (context) => const SessionsScreen(),
  };
}