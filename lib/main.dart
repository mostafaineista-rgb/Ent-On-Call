import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/notification_service.dart';
import 'styles/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('--- APP STARTING ---');
  
  try {
    debugPrint('Initializing Notifications...');
    await NotificationService.init();
    debugPrint('Notifications Initialized.');
    
    debugPrint('Initializing Date Formatting...');
    await initializeDateFormatting('ar', null);
    debugPrint('Date Formatting Initialized.');
  } catch (e, stack) {
    debugPrint('ERROR DURING INITIALIZATION: $e');
    debugPrint(stack.toString());
    // We continue to runApp() so the user doesn't see a black screen
  }
  
  debugPrint('Running App...');
  runApp(const EntOnCallApp());
}

class EntOnCallApp extends StatelessWidget {
  const EntOnCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ENT ON-CALL',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'IQ'),
      supportedLocales: const [
        Locale('ar', 'IQ'), // Arabic (Iraq)
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}
