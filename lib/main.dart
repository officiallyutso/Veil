import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:veil/core/app_theme.dart';
import 'package:veil/core/routes.dart';
import 'package:veil/features/browser/browser_screen.dart';
import 'package:veil/models/settings_model.dart';
import 'package:veil/services/bookmark_service.dart';
import 'package:veil/services/history_service.dart';
import 'package:veil/services/session_service.dart';
import 'package:veil/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Register Hive adapters
  // Adapters will be implemented later
  
  // Initialize services
  final settingsService = SettingsService();
  await settingsService.initialize();
  
  final bookmarkService = BookmarkService();
  await bookmarkService.initialize();
  
  final historyService = HistoryService();
  await historyService.initialize();
  
  final sessionService = SessionService();
  await sessionService.initialize();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => settingsService),
        ChangeNotifierProvider(create: (_) => bookmarkService),
        ChangeNotifierProvider(create: (_) => historyService),
        ChangeNotifierProvider(create: (_) => sessionService),
      ],
      child: const VeilApp(),
    ),
  );
}

class VeilApp extends StatelessWidget {
  const VeilApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = Provider.of<SettingsService>(context);
    
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;
        
        if (settingsService.settings.useSystemColors && lightDynamic != null && darkDynamic != null) {
          lightColorScheme = lightDynamic;
          darkColorScheme = darkDynamic;
        } else {
          lightColorScheme = AppTheme.lightColorScheme;
          darkColorScheme = AppTheme.darkColorScheme;
        }
        
        return MaterialApp(
          title: 'Veil Browser',
          theme: AppTheme.lightTheme(lightColorScheme),
          darkTheme: AppTheme.darkTheme(darkColorScheme),
          themeMode: settingsService.settings.themeMode,
          initialRoute: AppRoutes.home,
          routes: AppRoutes.routes,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
