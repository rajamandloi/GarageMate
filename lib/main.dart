import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/providers/language_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/language_service.dart';
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
import 'features/subscription/providers/subscription_provider.dart';
import 'features/search/providers/search_provider.dart';
import 'features/analytics/providers/analytics_provider.dart';
import 'features/invoice_settings/providers/invoice_settings_provider.dart';
import 'features/staff/providers/staff_provider.dart';
import 'core/providers/user_provider.dart';

import 'l10n/app_localizations.dart';

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

class _GarageMateAppState extends State<GarageMateApp> {
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
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (error) {
        debugPrint('Deep link error: $error');
      },
    );

    try {
      final initialUri = await _appLinks.getInitialLink();

      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (error) {
      debugPrint('Initial deep link error: $error');
    }
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('GarageMate deep link: $uri');

    if (uri.scheme != 'garagemate') return;
    if (uri.host != 'reset-password') return;

    final token = uri.queryParameters['token'];

    if (token == null || token.isEmpty) {
      debugPrint('Reset token missing');
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final navigator = navigatorKey.currentState;
      if (navigator == null) return;

      navigator.push(
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(token: token),
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
          create: (_) => LanguageProvider()..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider()..init(),
        ),
        ChangeNotifierProvider(
  create: (_) => UserProvider(),
),
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
        ChangeNotifierProvider(
          create: (_) => SubscriptionProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => SearchProvider(),
        ),
        ChangeNotifierProvider(
  create: (_) => AnalyticsProvider(),
),
ChangeNotifierProvider(
  create: (_) => InvoiceSettingsProvider(),
),
ChangeNotifierProvider(
  create: (_) => StaffProvider(),
),
      ],
      child: Consumer2<LanguageProvider, ThemeProvider>(
        builder: (
          context,
          languageProvider,
          themeProvider,
          child,
        ) {
          // Wait until language is loaded
          if (languageProvider.isLoading) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              home: const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }

          return MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'GarageMate',

            // ================================================
            // LOCALIZATION
            // ================================================
            locale: languageProvider.locale,
            supportedLocales:
                LanguageService.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            // ================================================
            // THEME
            // ================================================
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,

            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

// ============================================================
// GLOBAL NAVIGATOR KEY
// ============================================================

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();