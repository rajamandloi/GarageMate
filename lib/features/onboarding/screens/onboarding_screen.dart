import 'package:flutter/material.dart';
import '../../auth/screens/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      icon: Icons.notifications_active_rounded,
      title: 'Never Miss a Customer Service',
      description:
          'Keep track of every upcoming service and automatically remind your customers at the right time.',
    ),
    _OnboardingData(
      icon: Icons.directions_car_filled_rounded,
      title: 'Track Every Vehicle',
      description:
          'Manage customers, vehicles, mileage and complete service history from one simple place.',
    ),
    _OnboardingData(
      icon: Icons.event_available_rounded,
      title: 'Automatically Remind Customers',
      description:
          'Create smart reminders based on service dates, mileage, insurance, PUC and more.',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const LoginScreen(),
    ),
  );
}

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: const Text('Skip'),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration
                        Container(
                          width: 190,
                          height: 190,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            page.icon,
                            size: 88,
                            color: theme.colorScheme.primary,
                          ),
                        ),

                        const SizedBox(height: 55),

                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 18),

                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Page indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) {
                  final isActive = index == _currentPage;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 28),

            // Continue button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _nextPage,
                  child: Text(
                    _currentPage == _pages.length - 1
                        ? 'Get Started'
                        : 'Continue',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

