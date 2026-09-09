import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';

import 'firebase_options.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'features/customers/providers/customer_provider.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/reminders/providers/reminder_provider.dart';
import 'features/services/providers/service_provider.dart';
import 'features/splash/screens/splash_screen.dart';
import 'features/vehicles/providers/vehicle_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // FIREBASE
  // ============================================================

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.initialize();

  // ============================================================
  // START APP
  // ============================================================

  runApp(const GarageMateApp());
}

class GarageMateApp extends StatefulWidget {
  const GarageMateApp({super.key});

  @override
  State<GarageMateApp> createState() =>
      _GarageMateAppState();
}

class _GarageMateAppState
    extends State<GarageMateApp> {
  final AppLinks _appLinks = AppLinks();

  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();

    _initDeepLinks();
  }

  // ============================================================
  // DEEP LINKS
  // ============================================================

  Future<void> _initDeepLinks() async {
    // App already running / resumed
    _linkSubscription =
        _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (error) {
        debugPrint(
          'Deep link error: $error',
        );
      },
    );

    // App opened directly from email link
    try {
      final initialUri =
          await _appLinks.getInitialLink();

      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (error) {
      debugPrint(
        'Initial deep link error: $error',
      );
    }
  }

  // ============================================================
  // HANDLE DEEP LINK
  // ============================================================

  void _handleDeepLink(Uri uri) {
    debugPrint(
      'GarageMate deep link: $uri',
    );

    if (uri.scheme != 'garagemate') {
      return;
    }

    if (uri.host != 'reset-password') {
      return;
    }

    final token =
        uri.queryParameters['token'];

    if (token == null || token.isEmpty) {
      debugPrint(
        'Reset token missing',
      );

      return;
    }

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!mounted) return;

      final navigator =
          navigatorKey.currentState;

      if (navigator == null) {
        return;
      }

      navigator.push(
        MaterialPageRoute(
          builder: (_) =>
              ResetPasswordScreen(
            token: token,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();

    super.dispose();
  }

  // ============================================================
  // APP
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CustomerProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => VehicleProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => ServiceProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => ReminderProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => DashboardProvider(),
        ),
      ],

      child: MaterialApp(
        navigatorKey: navigatorKey,

        debugShowCheckedModeBanner: false,

        title: 'GarageMate',

        theme: AppTheme.lightTheme,

        darkTheme: AppTheme.darkTheme,

        themeMode: ThemeMode.system,

        home: const SplashScreen(),
      ),
    );
  }
}

// ============================================================
// GLOBAL NAVIGATOR KEY
// ============================================================

final GlobalKey<NavigatorState>
    navigatorKey =
    GlobalKey<NavigatorState>();