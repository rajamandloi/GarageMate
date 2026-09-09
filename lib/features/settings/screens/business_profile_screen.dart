
import 'package:flutter/material.dart';

import '../../../core/services/api_service.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() =>
      _BusinessProfileScreenState();
}

class _BusinessProfileScreenState
    extends State<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _garageNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _garageNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final response =
          await ApiService.get('/garage/profile');

      final data = response['garage'];

      if (data is Map) {
        _garageNameController.text =
            data['name']?.toString() ?? '';

        _ownerNameController.text =
            data['ownerName']?.toString() ?? '';

        _phoneController.text =
            data['phone']?.toString() ?? '';

        _emailController.text =
            data['email']?.toString() ?? '';

        _addressController.text =
            data['address']?.toString() ?? '';

        _cityController.text =
            data['city']?.toString() ?? '';
      }
    } catch (error) {
      _error = error.toString();
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final response = await ApiService.put(
        '/garage/profile',
        {
          'name': _garageNameController.text.trim(),
          'ownerName': _ownerNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
        },
      );

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Business profile updated successfully',
            ),
          ),
        );

        Navigator.pop(context);
      } else {
        setState(() {
          _error =
              response['message']?.toString() ??
              'Unable to update profile';
        });
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Business Profile',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  40,
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color:
                                theme.colorScheme.primary,
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.store_rounded,
                            color: theme.colorScheme
                                .onPrimary,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Garage Profile',
                                style: theme
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight:
                                          FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage your garage information',
                                style: theme
                                    .textTheme
                                    .bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _field(
                    label: 'Garage Name',
                    controller:
                        _garageNameController,
                    icon: Icons.store_outlined,
                    hint: 'Enter garage name',
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Garage name is required';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  _field(
                    label: 'Owner Name',
                    controller:
                        _ownerNameController,
                    icon: Icons.person_outline_rounded,
                    hint: 'Enter owner name',
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Owner name is required';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  _field(
                    label: 'Mobile Number',
                    controller: _phoneController,
                    icon: Icons.phone_outlined,
                    hint: '10-digit mobile number',
                    keyboardType:
                        TextInputType.phone,
                    validator: (value) {
                      final phone =
                          value?.replaceAll(
                                RegExp(r'[^0-9]'),
                                '',
                              ) ??
                              '';

                      if (phone.isEmpty) {
                        return 'Phone number is required';
                      }

                      if (phone.length != 10) {
                        return 'Enter a valid 10-digit number';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  _field(
                    label: 'Email',
                    controller:
                        _emailController,
                    icon: Icons.email_outlined,
                    hint: 'garage@email.com',
                    keyboardType:
                        TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Email is required';
                      }

                      if (!value.contains('@')) {
                        return 'Enter a valid email';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  _field(
                    label: 'Address',
                    controller:
                        _addressController,
                    icon:
                        Icons.location_on_outlined,
                    hint: 'Enter garage address',
                    maxLines: 3,
                  ),

                  const SizedBox(height: 18),

                  _field(
                    label: 'City',
                    controller:
                        _cityController,
                    icon: Icons.location_city_outlined,
                    hint: 'Enter city',
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding:
                          const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme
                            .colorScheme
                            .errorContainer,
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: theme
                              .colorScheme
                              .onErrorContainer,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),

                  SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      onPressed:
                          _isSaving
                              ? null
                              : _saveProfile,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.save_rounded,
                            ),
                      label: Text(
                        _isSaving
                            ? 'Saving...'
                            : 'Save Changes',
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
          ),
        ),
      ],
    );
  }
}

