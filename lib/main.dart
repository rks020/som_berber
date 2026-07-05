import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'providers/salon_provider.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://eqkkkxjjyixtrwoutmkq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVxa2treGpqeWl4dHJ3b3V0bWtxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMxNDkxMzgsImV4cCI6MjA5ODcyNTEzOH0.7QIx4jJkcrCIfMKHkL4wd4K5xoU4avIujqWabRyt7EQ',
  );

  // Initialize Turkish date formatting locale
  await initializeDateFormatting('tr_TR', null);

  // Initialize SalonProvider and load data
  final salonProvider = SalonProvider();
  await salonProvider.init();

  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  runApp(
    ChangeNotifierProvider(
      create: (_) => salonProvider,
      child: const YilmazBarberApp(),
    ),
  );
}

class YilmazBarberApp extends StatefulWidget {
  const YilmazBarberApp({super.key});

  @override
  State<YilmazBarberApp> createState() => _YilmazBarberAppState();
}

class _YilmazBarberAppState extends State<YilmazBarberApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _saveTokenIfAdmin();
  }

  Future<void> _saveTokenIfAdmin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('is_admin_logged_in') == true) {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await Supabase.instance.client.from('admin_device_tokens').upsert({'token': token}, onConflict: 'token');
        }
      }
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload data when the app comes back to foreground
      context.read<SalonProvider>().reloadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yılmaz Hair Barber',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
      ],
      locale: const Locale('tr', 'TR'),
      home: const AuthScreen(),
    );
  }
}

