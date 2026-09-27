import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/api_service.dart';

class WhatsAppSendScreen extends StatefulWidget {
  const WhatsAppSendScreen({super.key});

  @override
  State<WhatsAppSendScreen> createState() =>
      _WhatsAppSendScreenState();
}

class _WhatsAppSendScreenState extends State<WhatsAppSendScreen> {
  // ============================================================
  // STATE
  // ============================================================

  final TextEditingController _phoneController =
      TextEditingController();
  final TextEditingController _messageController =
      TextEditingController();

  List<Map<String, dynamic>> _customers = [];
  bool _isLoadingCustomers = true;
  String? _errorMessage;

  String? _selectedCustomerName;

  // Pre-defined message templates
  static const List<Map<String, String>> _quickTemplates = [
    {
      'label': 'Invoice Reminder',
      'message':
          'Aapka payment pending hai. Kripya jaldi payment karein. Thank you!',
    },
    {
      'label': 'Service Reminder',
      'message':
          'Aapki gaadi ki next service due hai. Kripya appointment book karein. Thank you!',
    },
    {
      'label': 'Thank You',
      'message':
          'Thank you for visiting our garage! Aapki service complete ho gayi hai. Have a great day!',
    },
    {
      'label': 'Payment Received',
      'message':
          'Thank you! Aapka payment receive ho gaya hai. Kripya receipt check karein.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD CUSTOMERS
  // ============================================================

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoadingCustomers = true;
      _errorMessage = null;
    });

    try {
      // ✅ ApiService mein already helper hai
      final customers = await ApiService.fetchCustomers();

      if (!mounted) return;

      setState(() {
        _customers = customers;
        _isLoadingCustomers = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoadingCustomers = false;
      });
    }
  }

  // ============================================================
  // OPEN WHATSAPP
  // ============================================================

  Future<void> _openWhatsApp() async {
    final phone = _phoneController.text.trim();
    final message = _messageController.text.trim();

    // Validate
    if (phone.isEmpty) {
      _showSnack('Kripya customer ka phone number daalein');
      return;
    }

    if (message.isEmpty) {
      _showSnack('Kripya message type karein');
      return;
    }

    // Normalize phone
    String digits = phone.replaceAll(RegExp(r'\D'), '');

    if (digits.length == 10) {
      digits = '91$digits';
    }

    if (digits.length < 10 || digits.length > 15) {
      _showSnack('Invalid phone number');
      return;
    }

    // Build WhatsApp URL
    final encodedMessage = Uri.encodeComponent(message);
    final url = Uri.parse(
      'https://wa.me/$digits?text=$encodedMessage',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showSnack('WhatsApp install nahi hai is device pe');
      }
    } catch (e) {
      _showSnack('WhatsApp open nahi ho paya: $e');
    }
  }

  // ============================================================
  // SHOW SNACK
  // ============================================================

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ============================================================
  // PICK CUSTOMER
  // ============================================================

  void _showCustomerPicker() {
    if (_customers.isEmpty) {
      _showSnack('Koi customer nahi mila');
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Customer Select Karein',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _customers.length,
                    itemBuilder: (context, index) {
                      final customer = _customers[index];
                      final name =
                          (customer['name'] ?? 'Unknown').toString();
                      final phone =
                          (customer['phone'] ?? '').toString();

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Text(
                            name.isNotEmpty
                                ? name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(phone),
                        onTap: () {
                          _phoneController.text = phone;
                          _selectedCustomerName = name;

                          // Auto-prefix "Dear Name," if message not empty
                          final currentMsg =
                              _messageController.text.trim();
                          if (currentMsg.isNotEmpty &&
                              !currentMsg.startsWith('Dear')) {
                            _messageController.text =
                                'Dear $name,\n\n$currentMsg';
                          }

                          setState(() {});
                          Navigator.pop(sheetContext);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // APPLY QUICK TEMPLATE
  // ============================================================

  void _applyQuickTemplate(String message) {
    final name = _selectedCustomerName;

    if (name != null && name.isNotEmpty) {
      _messageController.text = 'Dear $name,\n\n$message';
    } else {
      _messageController.text = message;
    }

    setState(() {});
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
          'Send on WhatsApp',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // INFO BANNER
            // ==================================================
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'WhatsApp khulega — message already type hoga. Bas Send button dabayein.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // PHONE
            // ==================================================
            Text(
              'Customer Phone',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Enter phone number',
                prefixIcon: const Icon(
                  Icons.phone_rounded,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.people_rounded),
                  tooltip: 'Customer list',
                  onPressed: _isLoadingCustomers
                      ? null
                      : _showCustomerPicker,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Customer list button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _isLoadingCustomers
                    ? null
                    : _showCustomerPicker,
                icon: _isLoadingCustomers
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.people_alt_rounded,
                        size: 16,
                      ),
                label: const Text('Customer se select karein'),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // QUICK TEMPLATES
            // ==================================================
            Text(
              'Quick Templates',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickTemplates.map((template) {
                return ActionChip(
                  label: Text(template['label']!),
                  onPressed: () => _applyQuickTemplate(
                    template['message']!,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // MESSAGE
            // ==================================================
            Text(
              'Message',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 8,
              minLines: 5,
              decoration: const InputDecoration(
                hintText: 'Message type karein ya upar se template chunein',
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // OPEN WHATSAPP BUTTON
            // ==================================================
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: _openWhatsApp,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                ),
                icon: const Icon(Icons.chat_rounded),
                label: const Text(
                  'Open WhatsApp & Send',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // NOTE
            // ==================================================
            Text(
              'Note: WhatsApp khulega, message already filled hoga. Send button dabakar bhej dein.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}