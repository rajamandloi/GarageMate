import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/staff_provider.dart';

class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({super.key});

  @override
  State<AddStaffScreen> createState() =>
      _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  String _staffRole = 'mechanic';
  bool _useCustomPassword = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  static const _roles = [
    {
      'value': 'manager',
      'label': 'Manager',
      'desc': 'Full access (except subscription)',
      'icon': Icons.manage_accounts_rounded,
      'color': Colors.blue,
    },
    {
      'value': 'mechanic',
      'label': 'Mechanic',
      'desc': 'Services & vehicles',
      'icon': Icons.build_rounded,
      'color': Colors.orange,
    },
    {
      'value': 'accountant',
      'label': 'Accountant',
      'desc': 'Payments & invoices',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Colors.green,
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = context.read<StaffProvider>();

    final result = await provider.addStaff(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      staffRole: _staffRole,
      password: _useCustomPassword
          ? _passwordController.text.trim()
          : null,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (result != null) {
      final whatsappSent =
          result['whatsappSent'] == true;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  whatsappSent
                      ? Icons.check_circle_rounded
                      : Icons.warning_amber_rounded,
                  color: whatsappSent
                      ? Colors.green
                      : Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 10),
                const Text('Staff Added'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  whatsappSent
                      ? '✅ WhatsApp invite sent successfully!'
                      : '⚠️ WhatsApp invite failed. Please share credentials manually:',
                ),
                if (!whatsappSent &&
                    result['plainPassword'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Login Credentials:',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Phone: ${_phoneController.text}',
                        ),
                        Text(
                          'Password: ${result['plainPassword']}',
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () =>
                    Navigator.pop(dialogContext),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.error ?? 'Unable to add staff',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
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
          'Add Staff Member',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            // INFO CARD
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Staff ko WhatsApp par login credentials bhej diye jayenge.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // NAME
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Staff Name',
                hintText: 'e.g. Rajesh Kumar',
                prefixIcon: Icon(Icons.person_outline_rounded),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // PHONE
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                labelText: 'WhatsApp Number',
                hintText: '9876543210',
                prefixText: '+91 ',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
                counterText: '',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Phone number is required';
                }
                if (value.length != 10) {
                  return 'Enter 10-digit mobile number';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // ROLE SELECTION
            Text(
              'Select Role',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ..._roles.map((role) {
              final isSelected = _staffRole == role['value'];
              final color = role['color'] as Color;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () {
                    setState(() => _staffRole = role['value'] as String);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.08)
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? color
                            : theme.colorScheme.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            role['icon'] as IconData,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                role['label'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                role['desc'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? color
                              : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // PASSWORD OPTION
            SwitchListTile(
              value: _useCustomPassword,
              onChanged: (value) {
                setState(() {
                  _useCustomPassword = value;
                  if (!value) _passwordController.clear();
                });
              },
              title: const Text(
                'Set Custom Password',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Warna auto-generated password bhej diya jayega',
                style: TextStyle(fontSize: 12),
              ),
              contentPadding: EdgeInsets.zero,
            ),

            // CUSTOM PASSWORD
            if (_useCustomPassword) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Minimum 6 characters',
                  prefixIcon:
                      const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (!_useCustomPassword) return null;
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  if (value.length < 6) {
                    return 'Minimum 6 characters';
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 30),

            // SUBMIT
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.person_add_rounded),
                label: Text(
                  _isSubmitting
                      ? 'Adding...'
                      : 'Add Staff & Send Invite',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}