import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/language_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../language/screens/language_chooser_screen.dart';
import '../../onboarding/screens/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // ✅ Language choose ho gayi ya nahi
  bool _showLanguageChooser = false;

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
    // --------------------------------------------------------
    // 1. Wait for splash animation
    // --------------------------------------------------------
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // --------------------------------------------------------
    // 2. Check if language has been chosen (first launch)
    // --------------------------------------------------------
    final hasLanguage = await LanguageService.hasChosenLanguage();

    if (!mounted) return;

    if (!hasLanguage) {
      // First launch → show language chooser
      setState(() {
        _showLanguageChooser = true;
      });
      return;
    }

    // --------------------------------------------------------
    // 3. Continue with normal flow
    // --------------------------------------------------------
    await _continueAppFlow();
  }

  Future<void> _continueAppFlow() async {
    await ApiService.initialize();

    if (!mounted) return;

    if (!ApiService.isLoggedIn) {
      _goToOnboarding();
      return;
    }

    try {
      final response = await ApiService.get('/auth/me');

      if (!mounted) return;

      if (response['success'] == true) {
        _goToDashboard();
        return;
      }

      await ApiService.logoutLocal();

      if (!mounted) return;

      _goToLogin();
    } catch (error) {
      debugPrint('Session restore error: $error');

      await ApiService.logoutLocal();

      if (!mounted) return;

      _goToLogin();
    }
  }

  // ============================================================
  // LANGUAGE CHOSEN CALLBACK
  // ============================================================

  Future<void> _onLanguageChosen() async {
    // Language saved — continue app flow
    if (!mounted) return;

    setState(() {
      _showLanguageChooser = false;
    });

    await _continueAppFlow();
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _goToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const DashboardScreen(),
      ),
      (route) => false,
    );
  }

  void _goToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  void _goToOnboarding() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const OnboardingScreen(),
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
    // ========================================================
    // Show language chooser on first launch
    // ========================================================
    if (_showLanguageChooser) {
      return LanguageChooserScreen(
        onLanguageChosen: _onLanguageChosen,
      );
    }

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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: const Icon(
                        Icons.build_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      AppConstants.appName,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      AppConstants.tagline,
                      style:
                          Theme.of(context).textTheme.bodyMedium,
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