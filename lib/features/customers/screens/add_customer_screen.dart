import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/phone_helper.dart';
import '../../vehicles/providers/vehicle_provider.dart';
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

  // CUSTOMER
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;

  // VEHICLE
  late final TextEditingController _registrationController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _mileageController;

  String _fuelType = 'Petrol';

  bool _isSaving = false;

  bool get isEditing => widget.customer != null;

  static const List<String> _fuelTypes = [
    'Petrol',
    'Diesel',
    'CNG',
    'Electric',
    'Hybrid',
    'LPG',
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    final customer = widget.customer;

    _nameController = TextEditingController(
      text: customer?.name ?? '',
    );

    _phoneController = TextEditingController(
      text: PhoneHelper.extractTenDigits(
        customer?.phone ?? '',
      ),
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

    _brandController = TextEditingController();
    _modelController = TextEditingController();
    _yearController = TextEditingController();
    _mileageController = TextEditingController();
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
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _mileageController.dispose();

    super.dispose();
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final customerProvider = context.read<CustomerProvider>();
    final vehicleProvider = context.read<VehicleProvider>();

    final mileage = double.tryParse(
          _mileageController.text.trim(),
        ) ??
        0;

    // ============================================================
    // EDIT MODE — सिर्फ customer update
    // ============================================================
    if (isEditing) {
      final updated = Customer(
        id: widget.customer!.id,
        name: _nameController.text.trim(),
        phone: PhoneHelper.toWhatsAppNumber(
          _phoneController.text.trim(),
        ),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        vehicleCount: widget.customer!.vehicleCount,
        lastServiceDate: widget.customer!.lastServiceDate,
        nextServiceDate: widget.customer!.nextServiceDate,
      );

      final success =
          await customerProvider.updateCustomer(updated);

      if (!mounted) return;

      setState(() => _isSaving = false);

      if (success) {
        Navigator.pop(context, updated);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              customerProvider.error ??
                  'Unable to update customer',
            ),
          ),
        );
      }
      return;
    }

    // ============================================================
    // CREATE MODE — customer + vehicle दोनों
    // ============================================================

    final newCustomer = Customer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      phone: PhoneHelper.toWhatsAppNumber(
        _phoneController.text.trim(),
      ),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      vehicleCount: 0,
      lastServiceDate: null,
      nextServiceDate: null,
    );

    final created = await customerProvider.createCustomerWithVehicle(
      customer: newCustomer,
      vehicleRegistrationNumber:
          _registrationController.text.trim(),
      vehicleBrand: _brandController.text.trim(),
      vehicleModel: _modelController.text.trim(),
      vehicleFuelType: _fuelType,
      vehicleManufacturingYear:
          _yearController.text.trim(),
      vehicleMileage: mileage,
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (created != null) {
      // Refresh vehicles list too
      await vehicleProvider.fetchVehicles();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Customer और Vehicle successfully save हो गए ✅',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      Navigator.pop(context, created);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          customerProvider.error ??
              'Unable to save customer',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Customer' : 'Add Customer',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ==================================================
              // CUSTOMER INFORMATION
              // ==================================================
              _sectionTitle('Customer Information'),
              const SizedBox(height: 12),

              // NAME
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

              const SizedBox(height: 16),

              // PHONE
              _phoneField(
                label: 'Mobile Number',
                controller: _phoneController,
              ),

              const SizedBox(height: 16),

              // EMAIL
              _field(
                label: 'Email (Optional)',
                controller: _emailController,
                hint: 'customer@email.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return null;
                  }
                  if (!value.contains('@')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ADDRESS
              _field(
                label: 'Address (Optional)',
                controller: _addressController,
                hint: 'Enter address',
                icon: Icons.location_on_outlined,
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              // ==================================================
              // VEHICLE INFORMATION
              // ==================================================
              _sectionTitle('Vehicle Information'),
              const SizedBox(height: 12),

              // REGISTRATION NUMBER
              _field(
                label: 'Vehicle Number',
                controller: _registrationController,
                hint: 'e.g. MP09AB1234',
                icon: Icons.directions_car_outlined,
                textCapitalization:
                    TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[A-Za-z0-9]'),
                  ),
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Vehicle number is required';
                  }

                  final reg =
                      _normalizeRegistrationNumber(value);

                  if (reg.length < 6) {
                    return 'Enter a valid vehicle number';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // BRAND
              _field(
                label: 'Brand',
                controller: _brandController,
                hint: 'Honda, Maruti, Hyundai, etc.',
                icon: Icons.branding_watermark_outlined,
                textCapitalization:
                    TextCapitalization.words,
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Brand is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // MODEL
              _field(
                label: 'Model',
                controller: _modelController,
                hint: 'City, Swift, i20, etc.',
                icon: Icons.car_repair_outlined,
                textCapitalization:
                    TextCapitalization.words,
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Model is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // FUEL TYPE
              _fuelField(),

              const SizedBox(height: 16),

              // MANUFACTURING YEAR (optional)
              _field(
                label: 'Manufacturing Year (Optional)',
                controller: _yearController,
                hint: '2020',
                icon: Icons.calendar_today_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
              ),

              const SizedBox(height: 16),

              // CURRENT MILEAGE (optional)
              _field(
                label: 'Current Mileage (Optional)',
                controller: _mileageController,
                hint: '18500',
                icon: Icons.speed_rounded,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(7),
                ],
              ),

              const SizedBox(height: 30),

              // ==================================================
              // SAVE
              // ==================================================
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : isEditing
                            ? 'Update Customer'
                            : 'Save Customer & Vehicle',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  // ============================================================
  // PHONE FIELD
  // ============================================================

  Widget _phoneField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: InputDecoration(
            hintText: '9876543210',
            prefixIcon: Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.phone_outlined),
                  SizedBox(width: 8),
                  Text(
                    '+91',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 90,
              minHeight: 40,
            ),
            counterText: '',
          ),
          validator: PhoneHelper.validateIndianMobile,
        ),
      ],
    );
  }

  // ============================================================
  // FUEL TYPE DROPDOWN
  // ============================================================

  Widget _fuelField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fuel Type',
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _fuelType,
          decoration: const InputDecoration(
            prefixIcon: Icon(
              Icons.local_gas_station_outlined,
            ),
          ),
          items: _fuelTypes
              .map(
                (fuel) => DropdownMenuItem(
                  value: fuel,
                  child: Text(fuel),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _fuelType = value);
          },
        ),
      ],
    );
  }

  // ============================================================
  // NORMAL FIELD
  // ============================================================

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
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          textCapitalization: textCapitalization,
          maxLines: maxLines,
          validator: validator,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
          ),
        ),
      ],
    );
  }
}