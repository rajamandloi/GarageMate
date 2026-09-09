import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reminder.dart';
import '../providers/reminder_provider.dart';

import '../../customers/models/customer.dart';
import '../../customers/providers/customer_provider.dart';

import '../../vehicles/models/vehicle.dart';
import '../../vehicles/providers/vehicle_provider.dart';

class AddReminderScreen extends StatefulWidget {
  final String? customerId;
  final String? vehicleId;

  const AddReminderScreen({
    super.key,
    this.customerId,
    this.vehicleId,
  });

  @override
  State<AddReminderScreen> createState() =>
      _AddReminderScreenState();
}

class _AddReminderScreenState
    extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _mileageController = TextEditingController();

  ReminderType _type = ReminderType.service;

  DateTime? _dueDate;

  String? _selectedCustomerId;
  String? _selectedVehicleId;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    _selectedCustomerId = widget.customerId;
    _selectedVehicleId = widget.vehicleId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final customerProvider =
        context.read<CustomerProvider>();

    final vehicleProvider =
        context.read<VehicleProvider>();

    if (customerProvider.customers.isEmpty &&
        !customerProvider.isLoading) {
      await customerProvider.fetchCustomers();
    }

    if (vehicleProvider.vehicles.isEmpty &&
        !vehicleProvider.isLoading) {
      await vehicleProvider.fetchVehicles();
    }

    if (!mounted) return;

    setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now,
      lastDate: DateTime(
        now.year + 10,
        now.month,
        now.day,
      ),
    );

    if (selected == null) return;

    setState(() {
      _dueDate = selected;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCustomerId == null ||
        _selectedCustomerId!.isEmpty) {
      _showMessage(
        'Please select a customer.',
      );
      return;
    }

    if (_selectedVehicleId == null ||
        _selectedVehicleId!.isEmpty) {
      _showMessage(
        'Please select a vehicle.',
      );
      return;
    }

    if (_dueDate == null &&
        _mileageController.text.trim().isEmpty) {
      _showMessage(
        'Please set a due date or due mileage.',
      );
      return;
    }

    final dueMileage =
        double.tryParse(
      _mileageController.text.trim(),
    );

    if (_mileageController.text.trim().isNotEmpty &&
        dueMileage == null) {
      _showMessage(
        'Please enter a valid mileage.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final reminder = Reminder(
      id: '',
      customerId: _selectedCustomerId!,
      vehicleId: _selectedVehicleId!,
      type: _type,
      dueDate: _dueDate,
      dueMileage: dueMileage,
      title: _titleController.text.trim(),
      message: _messageController.text.trim(),
      status: ReminderStatus.upcoming,
    );

    final success = await context
        .read<ReminderProvider>()
        .createReminder(reminder);

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Reminder created successfully.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } else {
      final error =
          context.read<ReminderProvider>().error;

      _showMessage(
        error ?? 'Unable to create reminder.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String _typeLabel(ReminderType type) {
    switch (type) {
      case ReminderType.service:
        return 'Service';

      case ReminderType.payment:
        return 'Payment';

      case ReminderType.general:
        return 'General';

      case ReminderType.specialOffer:
        return 'Special Offer';
    }
  }

  IconData _typeIcon(ReminderType type) {
    switch (type) {
      case ReminderType.service:
        return Icons.build_rounded;

      case ReminderType.payment:
        return Icons.payments_outlined;

      case ReminderType.general:
        return Icons.notifications_outlined;

      case ReminderType.specialOffer:
        return Icons.local_offer_outlined;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Reminder',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            40,
          ),
          children: [
            // --------------------------------------------------
            // CUSTOMER
            // --------------------------------------------------

            const _SectionTitle(
              title: 'Customer',
            ),

            const SizedBox(height: 10),

            Consumer<CustomerProvider>(
              builder: (
                context,
                provider,
                child,
              ) {
                if (provider.isLoading &&
                    provider.customers.isEmpty) {
                  return const LinearProgressIndicator();
                }

                return DropdownButtonFormField<String>(
                  initialValue:
                      _validCustomerValue(
                    provider.customers,
                  ),
                  decoration:
                      const InputDecoration(
                    labelText: 'Select Customer',
                    prefixIcon: Icon(
                      Icons.person_outline_rounded,
                    ),
                  ),
                  items: provider.customers
                      .map(
                        (Customer customer) {
                      return DropdownMenuItem<String>(
                        value: customer.id,
                        child: Text(
                          customer.name,
                          overflow:
                              TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ).toList(),
                  onChanged: widget.customerId != null
                      ? null
                      : (value) {
                          setState(() {
                            _selectedCustomerId =
                                value;

                            _selectedVehicleId =
                                null;
                          });
                        },
                  validator: (value) {
                    if (_selectedCustomerId ==
                            null ||
                        _selectedCustomerId!
                            .isEmpty) {
                      return 'Select a customer';
                    }

                    return null;
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------
            // VEHICLE
            // --------------------------------------------------

            const _SectionTitle(
              title: 'Vehicle',
            ),

            const SizedBox(height: 10),

            Consumer2<
                CustomerProvider,
                VehicleProvider>(
              builder: (
                context,
                customerProvider,
                vehicleProvider,
                child,
              ) {
                final vehicles =
                    _selectedCustomerId == null
                        ? vehicleProvider.vehicles
                        : vehicleProvider.vehicles
                            .where(
                              (vehicle) =>
                                  vehicle.customerId ==
                                  _selectedCustomerId,
                            )
                            .toList();

                return DropdownButtonFormField<String>(
                  initialValue:
                      _validVehicleValue(
                    vehicles,
                  ),
                  decoration:
                      const InputDecoration(
                    labelText: 'Select Vehicle',
                    prefixIcon: Icon(
                      Icons
                          .directions_car_outlined,
                    ),
                  ),
                  items: vehicles
                      .map(
                        (Vehicle vehicle) {
                      return DropdownMenuItem<String>(
                        value: vehicle.id,
                        child: Text(
                          _vehicleLabel(
                            vehicle,
                          ),
                          overflow:
                              TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ).toList(),
                  onChanged:
                      widget.vehicleId != null
                          ? null
                          : (value) {
                              setState(() {
                                _selectedVehicleId =
                                    value;
                              });
                            },
                  validator: (value) {
                    if (_selectedVehicleId ==
                            null ||
                        _selectedVehicleId!
                            .isEmpty) {
                      return 'Select a vehicle';
                    }

                    return null;
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------
            // TYPE
            // --------------------------------------------------

            const _SectionTitle(
              title: 'Reminder Type',
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<ReminderType>(
              initialValue: _type,
              decoration:
                  const InputDecoration(
                labelText: 'Type',
                prefixIcon: Icon(
                  Icons.notifications_outlined,
                ),
              ),
              items: ReminderType.values
                  .map(
                    (type) {
                  return DropdownMenuItem<
                      ReminderType>(
                    value: type,
                    child: Row(
                      children: [
                        Icon(
                          _typeIcon(type),
                          size: 20,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          _typeLabel(type),
                        ),
                      ],
                    ),
                  );
                },
              ).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _type = value;
                });
              },
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------
            // TITLE
            // --------------------------------------------------

            const _SectionTitle(
              title: 'Reminder Details',
            ),

            const SizedBox(height: 10),

            TextFormField(
              controller: _titleController,
              textCapitalization:
                  TextCapitalization.sentences,
              decoration:
                  const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. General Service',
                prefixIcon: Icon(
                  Icons.title_rounded,
                ),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter reminder title';
                }

                return null;
              },
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _messageController,
              textCapitalization:
                  TextCapitalization.sentences,
              maxLines: 3,
              decoration:
                  const InputDecoration(
                labelText: 'Message',
                hintText:
                    'Enter reminder message',
                prefixIcon: Icon(
                  Icons.message_outlined,
                ),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter reminder message';
                }

                return null;
              },
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------
            // DUE DATE
            // --------------------------------------------------

            const _SectionTitle(
              title: 'Due Date',
            ),

            const SizedBox(height: 10),

            InkWell(
              onTap: _selectDate,
              borderRadius:
                  BorderRadius.circular(14),
              child: InputDecorator(
                decoration:
                    const InputDecoration(
                  labelText: 'Due Date',
                  prefixIcon: Icon(
                    Icons
                        .calendar_today_outlined,
                  ),
                ),
                child: Text(
                  _dueDate == null
                      ? 'Select due date'
                      : _formatDate(
                          _dueDate!,
                        ),
                  style: TextStyle(
                    color: _dueDate == null
                        ? theme
                            .colorScheme
                            .onSurfaceVariant
                        : theme
                            .colorScheme
                            .onSurface,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // --------------------------------------------------
            // DUE MILEAGE
            // --------------------------------------------------

            TextFormField(
              controller:
                  _mileageController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration:
                  const InputDecoration(
                labelText:
                    'Due Mileage (optional)',
                hintText: 'e.g. 25000',
                prefixIcon: Icon(
                  Icons.speed_rounded,
                ),
                suffixText: 'km',
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return null;
                }

                if (double.tryParse(
                      value.trim(),
                    ) ==
                    null) {
                  return 'Enter valid mileage';
                }

                return null;
              },
            ),

            const SizedBox(height: 30),

            // --------------------------------------------------
            // CREATE BUTTON
            // --------------------------------------------------

            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed:
                    _isSubmitting
                        ? null
                        : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons
                            .add_alert_rounded,
                      ),
                label: Text(
                  _isSubmitting
                      ? 'Creating...'
                      : 'Create Reminder',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validCustomerValue(
    List<Customer> customers,
  ) {
    if (_selectedCustomerId == null) {
      return null;
    }

    final exists = customers.any(
      (customer) =>
          customer.id == _selectedCustomerId,
    );

    return exists
        ? _selectedCustomerId
        : null;
  }

  String? _validVehicleValue(
    List<Vehicle> vehicles,
  ) {
    if (_selectedVehicleId == null) {
      return null;
    }

    final exists = vehicles.any(
      (vehicle) =>
          vehicle.id == _selectedVehicleId,
    );

    return exists
        ? _selectedVehicleId
        : null;
  }

  String _vehicleLabel(Vehicle vehicle) {
    final parts = <String>[];

    if (vehicle.brand.trim().isNotEmpty) {
      parts.add(vehicle.brand);
    }

    if (vehicle.model.trim().isNotEmpty) {
      parts.add(vehicle.model);
    }

    if (parts.isEmpty) {
      return vehicle.registrationNumber;
    }

    return '${parts.join(' ')} • '
        '${vehicle.registrationNumber}';
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(
            fontWeight: FontWeight.w800,
          ),
    );
  }
}