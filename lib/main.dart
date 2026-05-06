import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/notification_service.dart';
import 'styles/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await ServiceLocator.setup();
    await NotificationService.init();
    await initializeDateFormatting('ar', null);
  } catch (e) {
    debugPrint('Init error: $e');
  }

  runApp(
    const ProviderScope(
      child: EntOnCallApp(),
    ),
  );
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
