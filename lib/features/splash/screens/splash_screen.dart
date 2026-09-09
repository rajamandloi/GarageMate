import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/api_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../onboarding/screens/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.75,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _controller.forward();

    _initializeApp();
  }

  // ============================================================
  // INITIALIZE APP
  // ============================================================

  Future<void> _initializeApp() async {
    // Give splash animation enough time to display.
    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    // ==========================================================
    // RESTORE SAVED SESSION
    // ==========================================================

    await ApiService.initialize();

    if (!mounted) return;

    // ==========================================================
    // NO SAVED SESSION
    // ==========================================================

    if (!ApiService.isLoggedIn) {
      _goToOnboarding();
      return;
    }

    // ==========================================================
    // SAVED SESSION EXISTS
    // ==========================================================

    try {
      // Ask backend for current user.
      //
      // If access token is expired, ApiService will
      // automatically use refresh token and retry /auth/me.
      final response =
          await ApiService.get('/auth/me');

      if (!mounted) return;

      if (response['success'] == true) {
        // Session is valid.
        _goToDashboard();
        return;
      }

      // Unexpected response.
      await ApiService.logoutLocal();

      if (!mounted) return;

      _goToLogin();
    } catch (error) {
      debugPrint(
        'Session restore error: $error',
      );

      // --------------------------------------------------------
      // IMPORTANT
      // --------------------------------------------------------
      //
      // If the backend is temporarily unreachable, do NOT
      // immediately destroy the saved session.
      //
      // The refresh token remains safely stored.
      //
      // We only send the user to Login when the session itself
      // is actually invalid/expired.
      //
      // For now, if /auth/me fails after refresh, go to Login.
      // --------------------------------------------------------

      await ApiService.logoutLocal();

      if (!mounted) return;

      _goToLogin();
    }
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _goToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const DashboardScreen(),
      ),
      (route) => false,
    );
  }

  void _goToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const LoginScreen(),
      ),
      (route) => false,
    );
  }

  void _goToOnboarding() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const OnboardingScreen(),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration:
                          BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary,
                        borderRadius:
                            BorderRadius.circular(
                          26,
                        ),
                      ),
                      child: const Icon(
                        Icons.build_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    Text(
                      AppConstants.appName,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      AppConstants.tagline,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}