import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/api_service.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final _formKey =
      GlobalKey<FormState>();

  final _emailController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
          '${ApiService.baseUrl}/auth/login',
        ),
        headers: {
          'Content-Type':
              'application/json',
        },
        body: jsonEncode({
          'email':
              _emailController.text.trim(),

          'password':
              _passwordController.text,

          // Backend compatibility.
          // Session persistence is now handled
          // using secure refresh tokens.
          'rememberMe':
              _rememberMe,
        }),
      );

      final data =
          jsonDecode(response.body);

      if (!mounted) return;

      // ========================================================
      // LOGIN SUCCESS
      // ========================================================

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data['success'] == true) {
        final accessToken =
            data['accessToken'] ??
            data['token'];

        final refreshToken =
            data['refreshToken'];

        // ------------------------------------------------------
        // VALIDATE TOKENS
        // ------------------------------------------------------

        if (accessToken == null ||
            accessToken
                .toString()
                .trim()
                .isEmpty) {
          throw Exception(
            'Access token was not received.',
          );
        }

        if (refreshToken == null ||
            refreshToken
                .toString()
                .trim()
                .isEmpty) {
          throw Exception(
            'Refresh token was not received.',
          );
        }

        // ------------------------------------------------------
        // SAVE SESSION SECURELY
        // ------------------------------------------------------

        await ApiService.saveSession(
          accessToken:
              accessToken.toString(),
          refreshToken:
              refreshToken.toString(),
        );

        if (!mounted) return;

        // ------------------------------------------------------
        // GO TO DASHBOARD
        // ------------------------------------------------------

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const DashboardScreen(),
          ),
          (route) => false,
        );

        return;
      }

      // ========================================================
      // LOGIN FAILED
      // ========================================================

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            data['message'] ??
                'Login failed',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            error
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                ),
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
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            24,
            32,
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
                // LOGO
                // ==================================================

                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration:
                        BoxDecoration(
                      color: theme
                          .colorScheme
                          .primary,
                      borderRadius:
                          BorderRadius
                              .circular(22),
                    ),
                    child:
                        const Icon(
                      Icons
                          .build_rounded,
                      size: 38,
                      color:
                          Colors.white,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 24,
                ),

                // ==================================================
                // TITLE
                // ==================================================

                Center(
                  child: Text(
                    'Welcome Back',
                    style: theme
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                      fontWeight:
                          FontWeight
                              .w800,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Center(
                  child: Text(
                    'Sign in to manage your garage',
                    textAlign:
                        TextAlign
                            .center,
                    style: theme
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                      color: theme
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 40,
                ),

                // ==================================================
                // EMAIL
                // ==================================================

                Text(
                  'Email or Mobile Number',
                  style: theme
                      .textTheme
                      .labelLarge
                      ?.copyWith(
                    fontWeight:
                        FontWeight
                            .w600,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                TextFormField(
                  controller:
                      _emailController,
                  keyboardType:
                      TextInputType
                          .emailAddress,
                  textInputAction:
                      TextInputAction
                          .next,
                  decoration:
                      const InputDecoration(
                    hintText:
                        'Enter email or mobile number',
                    prefixIcon:
                        Icon(
                      Icons
                          .person_outline_rounded,
                    ),
                  ),
                  validator:
                      (value) {
                    if (value ==
                            null ||
                        value
                            .trim()
                            .isEmpty) {
                      return 'Please enter email or mobile number';
                    }

                    return null;
                  },
                ),

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // PASSWORD
                // ==================================================

                Text(
                  'Password',
                  style: theme
                      .textTheme
                      .labelLarge
                      ?.copyWith(
                    fontWeight:
                        FontWeight
                            .w600,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                TextFormField(
                  controller:
                      _passwordController,
                  obscureText:
                      _obscurePassword,
                  textInputAction:
                      TextInputAction
                          .done,
                  onFieldSubmitted:
                      (_) {
                    if (!_isLoading) {
                      _login();
                    }
                  },
                  decoration:
                      InputDecoration(
                    hintText:
                        'Enter your password',
                    prefixIcon:
                        const Icon(
                      Icons
                          .lock_outline_rounded,
                    ),
                    suffixIcon:
                        IconButton(
                      onPressed:
                          () {
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
                  validator:
                      (value) {
                    if (value ==
                            null ||
                        value.isEmpty) {
                      return 'Please enter your password';
                    }

                    if (value.length <
                        6) {
                      return 'Password must be at least 6 characters';
                    }

                    return null;
                  },
                ),

                const SizedBox(
                  height: 12,
                ),

                // ==================================================
                // REMEMBER ME + FORGOT PASSWORD
                // ==================================================

                Row(
                  children: [
                    Checkbox(
                      value:
                          _rememberMe,
                      onChanged:
                          _isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _rememberMe =
                                        value ??
                                            true;
                                  });
                                },
                    ),

                    const Text(
                      'Keep me signed in',
                    ),

                    const Spacer(),

                    TextButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                  Navigator
                                      .push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                              const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                      child:
                          const Text(
                        'Forgot Password?',
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // LOGIN BUTTON
                // ==================================================

                SizedBox(
                  width:
                      double.infinity,
                  height: 56,
                  child:
                      FilledButton(
                    onPressed:
                        _isLoading
                            ? null
                            : _login,
                    child:
                        _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2.5,
                                ),
                              )
                            : const Text(
                                'Login',
                                style:
                                    TextStyle(
                                  fontSize:
                                      16,
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                ),
                              ),
                  ),
                ),

                const SizedBox(
                  height: 28,
                ),

                // ==================================================
                // DIVIDER
                // ==================================================

                Row(
                  children: [
                    Expanded(
                      child:
                          Divider(
                        color: theme
                            .colorScheme
                            .outlineVariant,
                      ),
                    ),

                    Padding(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 14,
                      ),
                      child: Text(
                        'OR',
                        style: theme
                            .textTheme
                            .labelMedium,
                      ),
                    ),

                    Expanded(
                      child:
                          Divider(
                        color: theme
                            .colorScheme
                            .outlineVariant,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 28,
                ),

                // ==================================================
                // REGISTER
                // ==================================================

                Center(
                  child:
                      TextButton(
                    onPressed:
                        _isLoading
                            ? null
                            : () {
                                Navigator
                                    .push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) =>
                                            const RegisterScreen(),
                                  ),
                                );
                              },
                    child:
                        const Text(
                      'Create a new garage account',
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight
                                .w700,
                      ),
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