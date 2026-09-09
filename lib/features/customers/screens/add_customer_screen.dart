import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../providers/customer_provider.dart';

class AddCustomerScreen extends StatefulWidget {
  final Customer? customer;

  // Scanner se aane wala vehicle number.
  final String? initialRegistrationNumber;

  const AddCustomerScreen({
    super.key,
    this.customer,
    this.initialRegistrationNumber,
  });

  @override
  State<AddCustomerScreen> createState() =>
      _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _registrationController;

  bool _isSaving = false;

  bool get isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();

    final customer = widget.customer;

    _nameController = TextEditingController(
      text: customer?.name ?? '',
    );

    _phoneController = TextEditingController(
      text: customer?.phone ?? '',
    );

    _emailController = TextEditingController(
      text: customer?.email ?? '',
    );

    _addressController = TextEditingController(
      text: customer?.address ?? '',
    );

    _registrationController = TextEditingController(
      text: _normalizeRegistrationNumber(
        widget.initialRegistrationNumber ?? '',
      ),
    );
  }

  String _normalizeRegistrationNumber(String value) {
    return value
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _registrationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final customer = Customer(
      id: widget.customer?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      vehicleCount: widget.customer?.vehicleCount ?? 0,
      lastServiceDate: widget.customer?.lastServiceDate,
      nextServiceDate: widget.customer?.nextServiceDate,
    );

    final provider = context.read<CustomerProvider>();

    final bool success;

    if (isEditing) {
      success = await provider.updateCustomer(customer);
    } else {
      success = await provider.createCustomer(customer);
    }

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (success) {
      /*
       * Customer save ho gaya.
       *
       * Vehicle ko abhi yahan directly save nahi kar rahe,
       * kyunki VehicleProvider/model ka exact create method
       * next step me existing project structure ke according
       * connect karenge.
       *
       * Scanned registration number:
       * _registrationController.text
       */

      Navigator.pop(context, customer);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.error ?? 'Unable to save customer',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Customer' : 'Add Customer',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // -------------------------------------------------
              // VEHICLE NUMBER
              // -------------------------------------------------
              _field(
                label: 'Vehicle Number',
                controller: _registrationController,
                hint: 'e.g. MP09AB1234',
                icon: Icons.directions_car_outlined,
                textCapitalization:
                    TextCapitalization.characters,
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Vehicle number is required';
                  }

                  final registration =
                      _normalizeRegistrationNumber(value);

                  if (registration.length < 6) {
                    return 'Enter a valid vehicle number';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              // -------------------------------------------------
              // CUSTOMER NAME
              // -------------------------------------------------
              _field(
                label: 'Customer Name',
                controller: _nameController,
                hint: 'Enter full name',
                icon: Icons.person_outline_rounded,
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Customer name is required';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              // -------------------------------------------------
              // MOBILE NUMBER
              // -------------------------------------------------
              _field(
                label: 'Mobile Number',
                controller: _phoneController,
                hint: '10-digit mobile number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  final phone =
                      value?.replaceAll(
                            RegExp(r'[^0-9]'),
                            '',
                          ) ??
                          '';

                  if (phone.isEmpty) {
                    return 'Mobile number is required';
                  }

                  if (phone.length != 10) {
                    return 'Enter a valid 10-digit number';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              // -------------------------------------------------
              // EMAIL
              // -------------------------------------------------
              _field(
                label: 'Email',
                controller: _emailController,
                hint: 'customer@email.com',
                icon: Icons.email_outlined,
                keyboardType:
                    TextInputType.emailAddress,
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return null;
                  }

                  if (!value.contains('@')) {
                    return 'Enter a valid email address';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              // -------------------------------------------------
              // ADDRESS
              // -------------------------------------------------
              _field(
                label: 'Address',
                controller: _addressController,
                hint: 'Enter customer address',
                icon: Icons.location_on_outlined,
                maxLines: 3,
              ),

              const SizedBox(height: 30),

              // -------------------------------------------------
              // SAVE BUTTON
              // -------------------------------------------------
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed:
                      _isSaving ? null : _save,
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
                        : isEditing
                            ? 'Update Customer'
                            : 'Save Customer',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization =
        TextCapitalization.none,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization:
              textCapitalization,
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