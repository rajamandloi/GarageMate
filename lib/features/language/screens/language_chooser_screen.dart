import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/language_provider.dart';

class LanguageChooserScreen extends StatelessWidget {
  final VoidCallback onLanguageChosen;

  const LanguageChooserScreen({
    super.key,
    required this.onLanguageChosen,
  });

  Future<void> _chooseLanguage(
    BuildContext context,
    String code,
  ) async {
    final provider = context.read<LanguageProvider>();
    await provider.changeLanguage(code);
    onLanguageChosen();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // ICON
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(
                    Icons.language_rounded,
                    size: 52,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // TITLE (bilingual)
              Text(
                'Choose Your Language',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'अपनी भाषा चुनें',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'You can change this anytime in Settings\n'
                'आप इसे कभी भी सेटिंग्स में बदल सकते हैं',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 40),

              // ENGLISH BUTTON
              _LanguageButton(
                title: 'English',
                subtitle: 'Continue in English',
                flag: '🇬🇧',
                onTap: () => _chooseLanguage(context, 'en'),
              ),

              const SizedBox(height: 14),

              // HINDI BUTTON
              _LanguageButton(
                title: 'हिंदी',
                subtitle: 'हिंदी में जारी रखें',
                flag: '🇮🇳',
                onTap: () => _chooseLanguage(context, 'hi'),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final String flag;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.title,
    required this.subtitle,
    required this.flag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Text(
                flag,
                style: const TextStyle(fontSize: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}