import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vehicle.dart';
import '../providers/vehicle_provider.dart';

class AddVehicleScreen extends StatefulWidget {
  final Vehicle? vehicle;
  final String customerId;

  const AddVehicleScreen({
    super.key,
    required this.customerId,
    this.vehicle,
  });

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _registrationController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _variantController;
  late final TextEditingController _yearController;
  late final TextEditingController _mileageController;
  late final TextEditingController _vinController;
  late final TextEditingController _engineController;
  late final TextEditingController _notesController;

  String _fuelType = 'Petrol';
  DateTime? _insuranceExpiry;
  DateTime? _pucExpiry;

  bool _isSaving = false;

  bool get isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();

    final vehicle = widget.vehicle;

    _registrationController = TextEditingController(
      text: vehicle?.registrationNumber ?? '',
    );

    _brandController = TextEditingController(
      text: vehicle?.brand ?? '',
    );

    _modelController = TextEditingController(
      text: vehicle?.model ?? '',
    );

    _variantController = TextEditingController(
      text: vehicle?.variant ?? '',
    );

    _yearController = TextEditingController(
      text: vehicle?.manufacturingYear ?? '',
    );

    _mileageController = TextEditingController(
      text: vehicle != null && vehicle.currentMileage > 0
          ? vehicle.currentMileage.toString()
          : '',
    );

    _vinController = TextEditingController(
      text: vehicle?.vin ?? '',
    );

    _engineController = TextEditingController(
      text: vehicle?.engineNumber ?? '',
    );

    _notesController = TextEditingController(
      text: vehicle?.notes ?? '',
    );

    _fuelType = vehicle?.fuelType ?? 'Petrol';
    _insuranceExpiry = vehicle?.insuranceExpiry;
    _pucExpiry = vehicle?.pucExpiry;
  }

  @override
  void dispose() {
    _registrationController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _variantController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    _vinController.dispose();
    _engineController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final mileage =
        double.tryParse(_mileageController.text.trim()) ?? 0;

    final vehicle = Vehicle(
      id: widget.vehicle?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      customerId: widget.customerId,
      customerName: widget.vehicle?.customerName,
      customerPhone: widget.vehicle?.customerPhone,
      customerEmail: widget.vehicle?.customerEmail,
      customerAddress: widget.vehicle?.customerAddress,
      registrationNumber:
          _registrationController.text.trim().toUpperCase(),
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      variant: _variantController.text.trim(),
      manufacturingYear: _yearController.text.trim(),
      fuelType: _fuelType,
      currentMileage: mileage,
      vin: _vinController.text.trim().toUpperCase(),
      engineNumber: _engineController.text.trim().toUpperCase(),
      notes: _notesController.text.trim(),
      insuranceExpiry: _insuranceExpiry,
      pucExpiry: _pucExpiry,
    );

    final provider = context.read<VehicleProvider>();

    final bool success;

    if (isEditing) {
      success = await provider.updateVehicle(vehicle);
    } else {
      success = await provider.createVehicle(vehicle);
    }

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (success) {
      Navigator.pop(context, vehicle);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.error ?? 'Unable to save vehicle',
        ),
      ),
    );
  }

  Future<void> _selectDate({
    required bool insurance,
  }) async {
    final currentDate =
        insurance ? _insuranceExpiry : _pucExpiry;

    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      if (insurance) {
        _insuranceExpiry = picked;
      } else {
        _pucExpiry = picked;
      }
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Not selected';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Vehicle' : 'Add Vehicle',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _sectionTitle(
                'Vehicle Information',
                Icons.directions_car_outlined,
              ),

              const SizedBox(height: 16),

              _field(
                label: 'Registration Number',
                controller: _registrationController,
                hint: 'MP09AB1234',
                icon: Icons.confirmation_number_outlined,
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Registration number is required';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: _field(
                      label: 'Brand',
                      controller: _brandController,
                      hint: 'Maruti',
                      icon: Icons.branding_watermark_outlined,
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Required';
                        }

                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      label: 'Model',
                      controller: _modelController,
                      hint: 'Swift',
                      icon: Icons.directions_car_outlined,
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Required';
                        }

                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: _field(
                      label: 'Variant',
                      controller: _variantController,
                      hint: 'VXI',
                      icon: Icons.tune_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      label: 'Manufacturing Year',
                      controller: _yearController,
                      hint: '2022',
                      icon: Icons.calendar_today_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return null;
                        }

                        final year =
                            int.tryParse(value.trim());

                        if (year == null ||
                            year < 1900 ||
                            year > DateTime.now().year) {
                          return 'Invalid year';
                        }

                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              DropdownButtonFormField<String>(
                initialValue: _fuelType,
                decoration: const InputDecoration(
                  labelText: 'Fuel Type',
                  prefixIcon: Icon(
                    Icons.local_gas_station_outlined,
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Petrol',
                    child: Text('Petrol'),
                  ),
                  DropdownMenuItem(
                    value: 'Diesel',
                    child: Text('Diesel'),
                  ),
                  DropdownMenuItem(
                    value: 'CNG',
                    child: Text('CNG'),
                  ),
                  DropdownMenuItem(
                    value: 'Electric',
                    child: Text('Electric'),
                  ),
                  DropdownMenuItem(
                    value: 'Hybrid',
                    child: Text('Hybrid'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _fuelType = value;
                  });
                },
              ),

              const SizedBox(height: 18),

              _field(
                label: 'Current Mileage',
                controller: _mileageController,
                hint: '45000',
                icon: Icons.speed_outlined,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),

              const SizedBox(height: 30),

              _sectionTitle(
                'Vehicle Identification',
                Icons.fingerprint_rounded,
              ),

              const SizedBox(height: 16),

              _field(
                label: 'VIN / Chassis Number',
                controller: _vinController,
                hint: 'Enter VIN / chassis number',
                icon: Icons.qr_code_2_rounded,
                textCapitalization:
                    TextCapitalization.characters,
              ),

              const SizedBox(height: 18),

              _field(
                label: 'Engine Number',
                controller: _engineController,
                hint: 'Enter engine number',
                icon: Icons.settings_outlined,
                textCapitalization:
                    TextCapitalization.characters,
              ),

              const SizedBox(height: 30),

              _sectionTitle(
                'Documents',
                Icons.description_outlined,
              ),

              const SizedBox(height: 16),

              _dateCard(
                title: 'Insurance Expiry',
                date: _insuranceExpiry,
                icon: Icons.shield_outlined,
                onTap: () {
                  _selectDate(insurance: true);
                },
                onClear: _insuranceExpiry == null
                    ? null
                    : () {
                        setState(() {
                          _insuranceExpiry = null;
                        });
                      },
              ),

              const SizedBox(height: 12),

              _dateCard(
                title: 'PUC Expiry',
                date: _pucExpiry,
                icon: Icons.verified_outlined,
                onTap: () {
                  _selectDate(insurance: false);
                },
                onClear: _pucExpiry == null
                    ? null
                    : () {
                        setState(() {
                          _pucExpiry = null;
                        });
                      },
              ),

              const SizedBox(height: 30),

              _sectionTitle(
                'Additional Notes',
                Icons.notes_rounded,
              ),

              const SizedBox(height: 16),

              _field(
                label: 'Notes',
                controller: _notesController,
                hint: 'Any additional information...',
                icon: Icons.notes_rounded,
                maxLines: 4,
              ),

              const SizedBox(height: 30),

              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : isEditing
                            ? 'Update Vehicle'
                            : 'Save Vehicle',
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }

  Widget _dateCard({
    required String title,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(date),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium,
                  ),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                onPressed: onClear,
                icon: const Icon(
                  Icons.close_rounded,
                ),
              )
            else
              const Icon(
                Icons.calendar_month_rounded,
              ),
          ],
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
          textCapitalization: textCapitalization,
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