import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/service_record.dart';
import '../../customers/models/customer.dart';
import '../../vehicles/models/vehicle.dart';
import '../../customers/providers/customer_provider.dart';
import '../../vehicles/providers/vehicle_provider.dart';

class AddServiceScreen extends StatefulWidget {
  final List<Customer>? customers;
  final List<Vehicle>? vehicles;

  final ServiceRecord? service;

  // Customer Details se open karne ke liye
  final String? initialCustomerId;
  final String? initialVehicleId;

  const AddServiceScreen({
    super.key,
    this.customers,
    this.vehicles,
    this.service,
    this.initialCustomerId,
    this.initialVehicleId,
  });

  @override
  State<AddServiceScreen> createState() =>
      _AddServiceScreenState();
}

class _AddServiceScreenState
    extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedCustomerId;
  String? _selectedVehicleId;

  late final TextEditingController _mileageController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _partsController;
  late final TextEditingController _laborController;
  late final TextEditingController _partsCostController;
  late final TextEditingController _discountController;
  late final TextEditingController _taxController;
  late final TextEditingController _paidController;
  late final TextEditingController _mechanicController;
  late final TextEditingController _notesController;
  late final TextEditingController _nextMileageController;

  String _serviceType = 'General Service';
  String _paymentMethod = 'Cash';

  DateTime? _nextServiceDate;

  // ============================================================
  // LOCAL DATA
  // ============================================================

  List<Customer> _customers = [];

  // ✅ Vehicles for currently selected customer (fresh fetch)
  List<Vehicle> _customerVehicles = [];

  bool _isLoadingCustomers = true;
  bool _isLoadingVehicles = false;
  String? _dataError;

  bool get isEditing => widget.service != null;

  List<String> get _serviceTypes => const [
        'General Service',
        'Oil Change',
        'Brake Service',
        'AC Service',
        'Wheel Alignment',
        'Wheel Balancing',
        'Battery Replacement',
        'Tyre Replacement',
        'Engine Service',
        'Full Service',
        'Other',
      ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    final service = widget.service;

    _selectedCustomerId =
        service?.customerId ?? widget.initialCustomerId;

    _selectedVehicleId =
        service?.vehicleId ?? widget.initialVehicleId;

    _mileageController = TextEditingController(
      text: service?.mileage.toStringAsFixed(0) ?? '',
    );

    _descriptionController = TextEditingController(
      text: service?.description ?? '',
    );

    _partsController = TextEditingController(
      text: service?.partsUsed ?? '',
    );

    _laborController = TextEditingController(
      text: service?.laborCost.toStringAsFixed(0) ?? '',
    );

    _partsCostController = TextEditingController(
      text: service?.partsCost.toStringAsFixed(0) ?? '',
    );

    _discountController = TextEditingController(
      text: service?.discount.toStringAsFixed(0) ?? '0',
    );

    _taxController = TextEditingController(
      text: service?.tax.toStringAsFixed(0) ?? '0',
    );

    _paidController = TextEditingController(
      text: service?.paidAmount.toStringAsFixed(0) ?? '0',
    );

    _mechanicController = TextEditingController(
      text: service?.mechanic ?? '',
    );

    _notesController = TextEditingController(
      text: service?.notes ?? '',
    );

    _nextMileageController = TextEditingController(
      text: service?.nextServiceMileage?.toStringAsFixed(0) ?? '',
    );

    _serviceType = service?.serviceType ?? 'General Service';
    _paymentMethod = service?.paymentMethod ?? 'Cash';
    _nextServiceDate = service?.nextServiceDate;

    for (final controller in [
      _laborController,
      _partsCostController,
      _discountController,
      _taxController,
      _paidController,
    ]) {
      controller.addListener(_refresh);
    }

    // ✅ Load customers + initial vehicles
    _loadInitialData();
  }

  // ============================================================
  // LOAD INITIAL DATA
  // ============================================================

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingCustomers = true;
      _dataError = null;
    });

    try {
      final customerProvider = context.read<CustomerProvider>();

      // ✅ Always fetch customers if empty
      if (customerProvider.customers.isEmpty &&
          !customerProvider.isLoading) {
        await customerProvider.fetchCustomers();
      }

      if (!mounted) return;

      final customers = customerProvider.customers.isNotEmpty
          ? customerProvider.customers
          : (widget.customers ?? <Customer>[]);

      setState(() {
        _customers = customers;
        _isLoadingCustomers = false;
      });

      // ✅ If a customer is already pre-selected
      //    (e.g. from Customer Detail screen),
      //    load their vehicles immediately.
      if (_selectedCustomerId != null) {
        await _loadVehiclesForCustomer(_selectedCustomerId!);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _dataError = e.toString().replaceAll('Exception: ', '');
        _isLoadingCustomers = false;
      });
    }
  }

  // ============================================================
  // LOAD VEHICLES FOR A SPECIFIC CUSTOMER
  // ============================================================

  Future<void> _loadVehiclesForCustomer(
    String customerId,
  ) async {
    setState(() {
      _isLoadingVehicles = true;
      _customerVehicles = [];
    });

    try {
      final vehicleProvider = context.read<VehicleProvider>();

      // ✅ Yahan hum SPECIFIC customer ke vehicles fetch kar rahe hain
      await vehicleProvider.fetchCustomerVehicles(customerId);

      if (!mounted) return;

      // ✅ Filter only current customer's vehicles
      //    (defensive — in case provider returns mixed data)
      final vehicles = vehicleProvider.vehicles
          .where((v) => v.customerId == customerId)
          .toList();

      setState(() {
        _customerVehicles = vehicles;
        _isLoadingVehicles = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _customerVehicles = [];
        _isLoadingVehicles = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load vehicles: ${e.toString().replaceAll('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _mileageController.dispose();
    _descriptionController.dispose();
    _partsController.dispose();
    _laborController.dispose();
    _partsCostController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    _paidController.dispose();
    _mechanicController.dispose();
    _notesController.dispose();
    _nextMileageController.dispose();

    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
  }

  // ============================================================
  // HELPERS
  // ============================================================

  double _number(TextEditingController controller) {
    return double.tryParse(controller.text.trim()) ?? 0;
  }

  double get _subtotal =>
      _number(_laborController) +
      _number(_partsCostController);

  double get _discount => _number(_discountController);
  double get _tax => _number(_taxController);

  double get _total {
    final value = _subtotal - _discount + _tax;
    return value < 0 ? 0 : value;
  }

  double get _paid => _number(_paidController);

  double get _pending {
    final value = _total - _paid;
    return value < 0 ? 0 : value;
  }

  PaymentStatus get _paymentStatus {
    if (_paid <= 0) return PaymentStatus.pending;
    if (_paid >= _total) return PaymentStatus.paid;
    return PaymentStatus.partiallyPaid;
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _selectNextServiceDate() async {
    final today = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _nextServiceDate ??
          today.add(const Duration(days: 180)),
      firstDate: today,
      lastDate: DateTime(today.year + 5),
    );

    if (selected == null) return;

    setState(() {
      _nextServiceDate = selected;
    });
  }

  // ============================================================
  // SAVE
  // ============================================================

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCustomerId == null) {
      _showError('Please select a customer.');
      return;
    }

    if (_selectedVehicleId == null) {
      _showError('Please select a vehicle.');
      return;
    }

    if (_paid > _total) {
      _showError(
        'Paid amount cannot be greater than total amount.',
      );
      return;
    }

    final service = ServiceRecord(
      id: widget.service?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      customerId: _selectedCustomerId!,
      vehicleId: _selectedVehicleId!,
      serviceDate:
          widget.service?.serviceDate ?? DateTime.now(),
      serviceType: _serviceType,
      mileage: _number(_mileageController),
      description: _descriptionController.text.trim(),
      partsUsed: _partsController.text.trim(),
      laborCost: _number(_laborController),
      partsCost: _number(_partsCostController),
      discount: _discount,
      tax: _tax,
      totalAmount: _total,
      paidAmount: _paid,
      paymentStatus: _paymentStatus,
      paymentMethod: _paymentMethod,
      nextServiceDate: _nextServiceDate,
      nextServiceMileage: double.tryParse(
        _nextMileageController.text.trim(),
      ),
      mechanic: _mechanicController.text.trim(),
      notes: _notesController.text.trim(),
    );

    Navigator.pop(context, service);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
          isEditing ? 'Edit Service' : 'Add Service',
        ),
      ),
      body: _isLoadingCustomers
          ? const Center(child: CircularProgressIndicator())
          : _dataError != null
              ? _buildErrorView()
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _sectionTitle('Service Information'),
                      const SizedBox(height: 12),

                      // ============================================
                      // CUSTOMER DROPDOWN
                      // ============================================
                      _dropdown(
                        label: 'Customer',
                        value: _selectedCustomerId,
                        items: _customers
                            .map(
                              (customer) => DropdownMenuItem<String>(
                                value: customer.id,
                                child: Text(customer.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) async {
                          if (value == null) return;

                          setState(() {
                            _selectedCustomerId = value;
                            _selectedVehicleId = null;
                            _customerVehicles = [];
                          });

                          // ✅ Fetch fresh vehicles for this customer
                          await _loadVehiclesForCustomer(value);
                        },
                      ),

                      const SizedBox(height: 16),

                      // ============================================
                      // VEHICLE DROPDOWN
                      // ============================================
                      _buildVehicleDropdown(),

                      const SizedBox(height: 16),

                      _dropdown(
                        label: 'Service Type',
                        value: _serviceType,
                        items: _serviceTypes
                            .map(
                              (type) => DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _serviceType = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      _field(
                        label: 'Current Mileage',
                        controller: _mileageController,
                        hint: '18500',
                        icon: Icons.speed_rounded,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Mileage is required';
                          }

                          if (double.tryParse(value) == null) {
                            return 'Enter a valid mileage';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      _field(
                        label: 'Service Description',
                        controller: _descriptionController,
                        hint: 'Describe the work performed',
                        icon: Icons.description_outlined,
                        maxLines: 3,
                      ),

                      const SizedBox(height: 16),

                      _field(
                        label: 'Parts Used',
                        controller: _partsController,
                        hint: 'Engine oil, filter, brake pads...',
                        icon: Icons.inventory_2_outlined,
                        maxLines: 3,
                      ),

                      const SizedBox(height: 28),

                      _sectionTitle('Cost Breakdown'),
                      const SizedBox(height: 12),

                      _field(
                        label: 'Labor Cost',
                        controller: _laborController,
                        hint: '0',
                        icon: Icons.engineering_outlined,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),

                      const SizedBox(height: 16),

                      _field(
                        label: 'Parts Cost',
                        controller: _partsCostController,
                        hint: '0',
                        icon: Icons.build_outlined,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),

                      const SizedBox(height: 16),

                      _field(
                        label: 'Discount',
                        controller: _discountController,
                        hint: '0',
                        icon: Icons.discount_outlined,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),

                      const SizedBox(height: 16),

                      _field(
                        label: 'Tax',
                        controller: _taxController,
                        hint: '0',
                        icon: Icons.receipt_long_outlined,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),

                      const SizedBox(height: 18),

                      _AmountSummary(
                        subtotal: _subtotal,
                        discount: _discount,
                        tax: _tax,
                        total: _total,
                      ),

                      const SizedBox(height: 28),

                      _sectionTitle('Payment'),
                      const SizedBox(height: 12),

                      _field(
                        label: 'Paid Amount',
                        controller: _paidController,
                        hint: '0',
                        icon: Icons.payments_outlined,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),

                      const SizedBox(height: 16),

                      _dropdown(
                        label: 'Payment Method',
                        value: _paymentMethod,
                        items: const [
                          DropdownMenuItem(
                            value: 'Cash',
                            child: Text('Cash'),
                          ),
                          DropdownMenuItem(
                            value: 'UPI',
                            child: Text('UPI'),
                          ),
                          DropdownMenuItem(
                            value: 'Card',
                            child: Text('Card'),
                          ),
                          DropdownMenuItem(
                            value: 'Bank Transfer',
                            child: Text('Bank Transfer'),
                          ),
                          DropdownMenuItem(
                            value: 'Other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _paymentMethod = value;
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _pending > 0
                              ? Theme.of(context)
                                  .colorScheme
                                  .errorContainer
                              : Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons
                                  .account_balance_wallet_outlined,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Pending Amount',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '₹${_pending.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      _sectionTitle('Next Service'),
                      const SizedBox(height: 12),

                      InkWell(
                        onTap: _selectNextServiceDate,
                        borderRadius: BorderRadius.circular(14),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Next Service Date',
                            prefixIcon: Icon(
                              Icons.event_available_outlined,
                            ),
                          ),
                          child: Text(
                            _nextServiceDate == null
                                ? 'Select date'
                                : _formatDate(_nextServiceDate!),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      _field(
                        label: 'Next Service Mileage',
                        controller: _nextMileageController,
                        hint: '23500',
                        icon: Icons.speed_rounded,
                        keyboardType: TextInputType.number,
                      ),

                      const SizedBox(height: 16),

                      _field(
                        label: 'Mechanic',
                        controller: _mechanicController,
                        hint: 'Mechanic name',
                        icon: Icons.person_outline_rounded,
                      ),

                      const SizedBox(height: 16),

                      _field(
                        label: 'Notes',
                        controller: _notesController,
                        hint: 'Additional notes',
                        icon: Icons.notes_rounded,
                        maxLines: 3,
                      ),

                      const SizedBox(height: 30),

                      SizedBox(
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.save_rounded),
                          label: Text(
                            isEditing
                                ? 'Update Service'
                                : 'Save Service',
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  // ============================================================
  // VEHICLE DROPDOWN
  // ============================================================

  Widget _buildVehicleDropdown() {
    // Case 1: No customer selected
    if (_selectedCustomerId == null) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Vehicle',
          prefixIcon: Icon(Icons.directions_car_outlined),
          enabled: false,
        ),
        child: const Text(
          'Select a customer first',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Case 2: Loading vehicles
    if (_isLoadingVehicles) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Vehicle',
          prefixIcon: Icon(Icons.directions_car_outlined),
        ),
        child: Row(
          children: const [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading vehicles...'),
          ],
        ),
      );
    }

    // Case 3: No vehicles for customer
    if (_customerVehicles.isEmpty) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: 'Vehicle',
          prefixIcon: const Icon(Icons.directions_car_outlined),
          errorText: 'No vehicles found for this customer',
        ),
        child: const Text(
          'Please add a vehicle first',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Case 4: Vehicles available
    return _dropdown(
      label: 'Vehicle',
      value: _selectedVehicleId,
      items: _customerVehicles
          .map(
            (vehicle) => DropdownMenuItem<String>(
              value: vehicle.id,
              child: Text(
                '${vehicle.registrationNumber} - '
                '${vehicle.brand} ${vehicle.model}',
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedVehicleId = value;
        });
      },
    );
  }

  // ============================================================
  // ERROR VIEW
  // ============================================================

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _dataError!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadInitialData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SHARED WIDGETS
  // ============================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleLarge
          ?.copyWith(fontWeight: FontWeight.w800),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      items: items,
      onChanged: onChanged,
      isExpanded: true,
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

// ============================================================
// AMOUNT SUMMARY WIDGET
// ============================================================

class _AmountSummary extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double tax;
  final double total;

  const _AmountSummary({
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _row('Subtotal', subtotal),
          _row('Discount', -discount),
          _row('Tax', tax),
          const Divider(height: 20),
          _row('Total', total, bold: true),
        ],
      ),
    );
  }

  Widget _row(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w800 : null,
              ),
            ),
          ),
          Text(
            '₹${value.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : null,
              fontSize: bold ? 17 : null,
            ),
          ),
        ],
      ),
    );
  }
}