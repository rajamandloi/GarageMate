import 'package:flutter/material.dart';

import '../../../core/services/api_service.dart';


class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // ============================================================
  // SEND RESET EMAIL
  // ============================================================

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.post(
        '/auth/forgot-password',
        {
          'email': _emailController.text.trim(),
        },
      );

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'If this email is registered, a reset email has been sent.',
            ),
          ),
        );

        // We don't know from the generic backend response
        // whether the email actually exists.
        //
        // User can open the reset screen after checking email.
       
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message']?.toString() ??
                  'Unable to process request',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Forgot Password',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            30,
            24,
            24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ==================================================
                // ICON
                // ==================================================

                Center(
                  child: Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_reset_rounded,
                      size: 42,
                      color:
                          theme.colorScheme.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ==================================================
                // TITLE
                // ==================================================

                Center(
                  child: Text(
                    'Reset your password',
                    textAlign: TextAlign.center,
                    style: theme
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Center(
                  child: Text(
                    'Enter the email address associated with your GarageMate account.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // ==================================================
                // EMAIL LABEL
                // ==================================================

                Text(
                  'Email Address',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                // ==================================================
                // EMAIL FIELD
                // ==================================================

                TextFormField(
                  controller: _emailController,
                  keyboardType:
                      TextInputType.emailAddress,
                  textInputAction:
                      TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: 'Enter your registered email',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                    ),
                  ),
                  validator: (value) {
                    final email =
                        value?.trim() ?? '';

                    if (email.isEmpty) {
                      return 'Please enter your email';
                    }

                    final emailRegex = RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    );

                    if (!emailRegex.hasMatch(email)) {
                      return 'Please enter a valid email';
                    }

                    return null;
                  },
                  onFieldSubmitted: (_) {
                    if (!_isLoading) {
                      _sendResetEmail();
                    }
                  },
                ),

                const SizedBox(height: 24),

                // ==================================================
                // SEND BUTTON
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed:
                        _isLoading
                            ? null
                            : _sendResetEmail,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.2,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                          ),
                    label: Text(
                      _isLoading
                          ? 'Sending...'
                          : 'Send Reset Email',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // BACK TO LOGIN
                // ==================================================

                Center(
                  child: TextButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.pop(context);
                          },
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                    ),
                    label: const Text(
                      'Back to Login',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}