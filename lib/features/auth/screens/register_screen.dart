import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/notification_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

enum _RegistrationStep {
  details,
  emailOtp,
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailOtpFormKey = GlobalKey<FormState>();

  final _garageController = TextEditingController();
  final _ownerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailOtpController = TextEditingController();

  _RegistrationStep _step = _RegistrationStep.details;

  String? _registrationId;

  Timer? _emailResendTimer;

  int _emailResendSeconds = 60;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  bool _emailVerified = false;

  @override
  void dispose() {
    _emailResendTimer?.cancel();

    _garageController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailOtpController.dispose();

    super.dispose();
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('Bad state: ', '')
        .trim();
  }

  String? _required(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final digits = (value ?? '').replaceAll(
      RegExp(r'\D'),
      '',
    );

    if (digits.isEmpty) {
      return 'Mobile number is required';
    }

    if (digits.length != 10 ||
        !RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
      return 'Enter a valid Indian mobile number';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Email is required';
    }

    if (!RegExp(
      r'^[^\s@]+@[^\s@]{2,}\.[^\s@]{2,}$',
    ).hasMatch(email)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  String _normalizedPhone() {
    final digits = _phoneController.text.replaceAll(
      RegExp(r'\D'),
      '',
    );

    return '+91$digits';
  }

  Future<void> _startRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text !=
        _confirmPasswordController.text) {
      _showError('Passwords do not match.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.post(
        '/auth/register/start',
        {
          'garageName': _garageController.text.trim(),
          'ownerName': _ownerController.text.trim(),
          'phone': _normalizedPhone(),
          'email': _emailController.text.trim().toLowerCase(),
          'password': _passwordController.text,
          'address': '',
          'city': '',
        },
      );

      final id = response['registrationId']?.toString();

      if (response['success'] != true ||
          id == null ||
          id.isEmpty) {
        throw Exception(
          response['message'] ??
              'Unable to start registration.',
        );
      }

      _registrationId = id;
      _emailVerified = false;

      _emailOtpController.clear();

      _startEmailResendTimer();

      if (!mounted) return;

      setState(() {
        _step = _RegistrationStep.emailOtp;
      });
    } catch (error) {
      if (mounted) {
        _showError(_cleanError(error));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyEmailOtp() async {
    if (!_emailOtpFormKey.currentState!.validate() ||
        _registrationId == null) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.post(
        '/auth/register/verify-email',
        {
          'registrationId': _registrationId,
          'otp': _emailOtpController.text.trim(),
        },
      );

      if (response['success'] != true) {
        throw Exception(
          response['message'] ??
              'Email verification failed.',
        );
      }

      _emailVerified = true;

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      await _completeRegistration();
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        _showError(_cleanError(error));
      }
    }
  }

  Future<void> _resendEmailOtp() async {
    if (_registrationId == null ||
        _emailResendSeconds > 0 ||
        _isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.post(
        '/auth/register/resend-email',
        {
          'registrationId': _registrationId,
        },
      );

      if (response['success'] != true) {
        throw Exception(
          response['message'] ??
              'Unable to resend email OTP.',
        );
      }

      _emailOtpController.clear();

      _startEmailResendTimer();

      if (mounted) {
        _showMessage(
          'A new email OTP has been sent.',
        );
      }
    } catch (error) {
      if (mounted) {
        _showError(_cleanError(error));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _completeRegistration() async {
    if (_registrationId == null ||
        !_emailVerified) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final fcmToken =
          await NotificationService.getToken();

      final response = await ApiService.post(
        '/auth/register/complete',
        {
          'registrationId': _registrationId,
          if (fcmToken != null &&
              fcmToken.isNotEmpty)
            'fcmToken': fcmToken,
        },
      );

      if (response['success'] != true) {
        throw Exception(
          response['message'] ??
              'Unable to complete registration.',
        );
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      await _showRegistrationCompleteDialog();

      if (!mounted) return;

      Navigator.of(context).popUntil(
        (route) => route.isFirst,
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        _showError(_cleanError(error));
      }
    }
  }

  Future<void> _showRegistrationCompleteDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);

        return AlertDialog(
          icon: Icon(
            Icons.verified_rounded,
            size: 60,
            color: theme.colorScheme.primary,
          ),
          title: const Text(
            'Registration Complete',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Your email has been verified successfully.\n\n'
            'Your GarageMate account has been created and is now waiting for Super Admin approval.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _startEmailResendTimer() {
    _emailResendTimer?.cancel();

    if (!mounted) return;

    setState(() {
      _emailResendSeconds = 60;
    });

    _emailResendTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_emailResendSeconds <= 1) {
          timer.cancel();

          setState(() {
            _emailResendSeconds = 0;
          });
        } else {
          setState(() {
            _emailResendSeconds--;
          });
        }
      },
    );
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showMessage(
    String message, {
    int seconds = 3,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: seconds),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _step == _RegistrationStep.details
              ? 'Create Account'
              : 'Verify Email',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            10,
            24,
            30,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(
              milliseconds: 180,
            ),
            child:
                _step == _RegistrationStep.details
                    ? _buildDetails(theme)
                    : _buildEmailOtp(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('details'),
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _header(
            theme,
            'Set up your garage',
            'Verify your email address before your GarageMate account is created.',
          ),
          _label(
            context,
            'Garage Name',
          ),
          TextFormField(
            controller: _garageController,
            textInputAction:
                TextInputAction.next,
            maxLength: 150,
            decoration:
                const InputDecoration(
              hintText:
                  'e.g. Sharma Auto Garage',
              prefixIcon: Icon(
                Icons.garage_outlined,
              ),
            ),
            validator: (v) => _required(
              v,
              'Garage name',
            ),
          ),
          const SizedBox(height: 18),
          _label(
            context,
            'Owner Name',
          ),
          TextFormField(
            controller: _ownerController,
            textInputAction:
                TextInputAction.next,
            maxLength: 120,
            decoration:
                const InputDecoration(
              hintText:
                  'Enter owner name',
              prefixIcon: Icon(
                Icons.person_outline_rounded,
              ),
            ),
            validator: (v) => _required(
              v,
              'Owner name',
            ),
          ),
          const SizedBox(height: 18),
          _label(
            context,
            'Mobile Number',
          ),
          TextFormField(
            controller: _phoneController,
            keyboardType:
                TextInputType.phone,
            textInputAction:
                TextInputAction.next,
            maxLength: 10,
            decoration:
                const InputDecoration(
              hintText:
                  'Enter 10-digit mobile number',
              prefixIcon: Icon(
                Icons.phone_outlined,
              ),
              helperText:
                  'Used as your garage contact number. SMS verification is not required.',
            ),
            validator: _validatePhone,
          ),
          const SizedBox(height: 18),
          _label(
            context,
            'Email',
          ),
          TextFormField(
            controller: _emailController,
            keyboardType:
                TextInputType.emailAddress,
            textInputAction:
                TextInputAction.next,
            maxLength: 254,
            autocorrect: false,
            decoration:
                const InputDecoration(
              hintText:
                  'Enter email address',
              prefixIcon: Icon(
                Icons.email_outlined,
              ),
              helperText:
                  'A verification OTP will be sent to this email.',
            ),
            validator: _validateEmail,
          ),
          const SizedBox(height: 18),
          _label(
            context,
            'Password',
          ),
          TextFormField(
            controller: _passwordController,
            obscureText:
                _obscurePassword,
            textInputAction:
                TextInputAction.next,
            maxLength: 128,
            autocorrect: false,
            decoration:
                InputDecoration(
              hintText:
                  'Create password',
              prefixIcon:
                  const Icon(
                Icons.lock_outline_rounded,
              ),
              suffixIcon:
                  IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword =
                        !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons
                          .visibility_outlined
                      : Icons
                          .visibility_off_outlined,
                ),
              ),
            ),
            validator: (v) {
              if (v == null ||
                  v.isEmpty) {
                return 'Password is required';
              }

              if (v.length < 6) {
                return 'Password must be at least 6 characters';
              }

              return null;
            },
          ),
          const SizedBox(height: 18),
          _label(
            context,
            'Confirm Password',
          ),
          TextFormField(
            controller:
                _confirmPasswordController,
            obscureText:
                _obscureConfirmPassword,
            textInputAction:
                TextInputAction.done,
            maxLength: 128,
            decoration:
                InputDecoration(
              hintText:
                  'Confirm password',
              prefixIcon:
                  const Icon(
                Icons.lock_reset_outlined,
              ),
              suffixIcon:
                  IconButton(
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword =
                        !_obscureConfirmPassword;
                  });
                },
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons
                          .visibility_outlined
                      : Icons
                          .visibility_off_outlined,
                ),
              ),
            ),
            validator: (v) {
              if (v == null ||
                  v.isEmpty) {
                return 'Please confirm your password';
              }

              if (v !=
                  _passwordController
                      .text) {
                return 'Passwords do not match';
              }

              return null;
            },
          ),
          const SizedBox(height: 30),
          _primaryButton(
            'Send Email Verification Code',
            _startRegistration,
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Your account is created only after email verification succeeds.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(
                color: theme.colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailOtp(ThemeData theme) {
    return Form(
      key: _emailOtpFormKey,
      child: Column(
        key: const ValueKey(
          'emailOtp',
        ),
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _header(
            theme,
            'Verify your email',
            'We sent a 6-digit OTP to ${_emailController.text.trim().toLowerCase()}.',
          ),
          TextFormField(
            controller:
                _emailOtpController,
            keyboardType:
                TextInputType.number,
            maxLength: 6,
            autofocus: true,
            decoration:
                const InputDecoration(
              labelText: 'Email OTP',
              prefixIcon: Icon(
                Icons
                    .mark_email_read_outlined,
              ),
            ),
            validator: (v) {
              return RegExp(
                r'^\d{6}$',
              ).hasMatch(
                v?.trim() ?? '',
              )
                  ? null
                  : 'Enter the 6-digit OTP';
            },
          ),
          const SizedBox(height: 22),
          _primaryButton(
            'Verify Email & Create Account',
            _verifyEmailOtp,
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed:
                  _emailResendSeconds ==
                              0 &&
                          !_isLoading
                      ? _resendEmailOtp
                      : null,
              child: Text(
                _emailResendSeconds == 0
                    ? 'Resend Email OTP'
                    : 'Resend in ${_emailResendSeconds}s',
              ),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _step =
                            _RegistrationStep
                                .details;
                      });
                    },
              child: const Text(
                'Back',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(
    ThemeData theme,
    String title,
    String subtitle,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 30,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme
                .headlineSmall
                ?.copyWith(
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme
                .bodyMedium
                ?.copyWith(
              color: theme.colorScheme
                  .onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton(
    String text,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed:
            _isLoading
                ? null
                : onPressed,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.2,
                ),
              )
            : Text(
                text,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _label(
    BuildContext context,
    String text,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(
          fontWeight:
              FontWeight.w600,
        ),
      ),
    );
  }
}