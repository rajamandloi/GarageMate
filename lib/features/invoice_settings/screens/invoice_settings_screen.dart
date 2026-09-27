import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/services/api_service.dart';
import '../providers/invoice_settings_provider.dart';

class InvoiceSettingsScreen extends StatefulWidget {
  const InvoiceSettingsScreen({super.key});

  @override
  State<InvoiceSettingsScreen> createState() =>
      _InvoiceSettingsScreenState();
}

class _InvoiceSettingsScreenState
    extends State<InvoiceSettingsScreen> {
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _footerController;
  late final TextEditingController _termsController;
  late final TextEditingController _upiController;

  Color _primaryColor = const Color(0xFF4A6CF7);
  Color _secondaryColor = const Color(0xFF25D366);

  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    _footerController = TextEditingController();
    _termsController = TextEditingController();
    _upiController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadSettings();
    });
  }

  Future<void> _loadSettings() async {
    final provider = context.read<InvoiceSettingsProvider>();
    await provider.fetchSettings();

    if (!mounted) return;

    final s = provider.settings;

    setState(() {
      _footerController.text = s.footerMessage;
      _termsController.text = s.termsAndConditions;
      _upiController.text = s.upiId;
      _primaryColor = _hexToColor(s.primaryColor);
      _secondaryColor = _hexToColor(s.secondaryColor);
      _initialized = true;
    });
  }

  @override
  void dispose() {
    _footerController.dispose();
    _termsController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  // ============================================================
  // HEX ↔ COLOR
  // ============================================================

  Color _hexToColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFF4A6CF7);
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  // ============================================================
  // COLOR PICKER
  // ============================================================

  Future<void> _pickColor({
    required String title,
    required Color initial,
    required Function(Color) onPicked,
  }) async {
    Color selected = initial;

    final result = await showDialog<Color>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: initial,
              onColorChanged: (c) => selected = c,
              enableAlpha: false,
              labelTypes: const [],
              pickerAreaHeightPercent: 0.7,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, selected),
              child: const Text('Select'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      onPicked(result);
    }
  }

  // ============================================================
  // UPLOAD LOGO
  // ============================================================

  Future<void> _pickLogo() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(
                  sheetContext,
                  ImageSource.gallery,
                ),
              ),
              ListTile(
                leading:
                    const Icon(Icons.camera_alt_outlined),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(
                  sheetContext,
                  ImageSource.camera,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (source == null || !mounted) return;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (picked == null || !mounted) return;

    final provider = context.read<InvoiceSettingsProvider>();
    final success = await provider.uploadLogo(picked.path);

    if (!mounted) return;

    if (success) {
      _showSnack('Logo uploaded successfully');
    } else {
      _showSnack(
        provider.error ?? 'Unable to upload logo',
        isError: true,
      );
    }
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    final provider = context.read<InvoiceSettingsProvider>();

    final success = await provider.updateSettings(
      primaryColor: _colorToHex(_primaryColor),
      secondaryColor: _colorToHex(_secondaryColor),
      footerMessage: _footerController.text.trim(),
      termsAndConditions: _termsController.text.trim(),
      upiId: _upiController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      _showSnack('Settings saved successfully');
    } else {
      _showSnack(
        provider.error ?? 'Unable to save settings',
        isError: true,
      );
    }
  }

  // ============================================================
  // PREVIEW
  // ============================================================

  void _showPreview() {
    final provider = context.read<InvoiceSettingsProvider>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: _InvoicePreview(
                garageName: provider.garageName,
                primaryColor: _primaryColor,
                secondaryColor: _secondaryColor,
                footerMessage: _footerController.text.trim(),
                terms: _termsController.text.trim(),
                upiId: _upiController.text.trim(),
                logoUrl: provider.settings.logo,
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
          'Invoice Settings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Preview',
            onPressed: _initialized ? _showPreview : null,
            icon: const Icon(Icons.preview_rounded),
          ),
        ],
      ),
      body: Consumer<InvoiceSettingsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && !_initialized) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              _buildLogoSection(provider, theme),
              const SizedBox(height: 24),
              _buildColorsSection(theme),
              const SizedBox(height: 24),
              _buildFooterSection(theme),
              const SizedBox(height: 24),
              _buildTermsSection(theme),
              const SizedBox(height: 24),
              _buildUpiSection(theme),
              const SizedBox(height: 32),
              _buildSaveButton(provider),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // LOGO SECTION
  // ============================================================

  Widget _buildLogoSection(
    InvoiceSettingsProvider provider,
    ThemeData theme,
  ) {
    final logoUrl = provider.settings.logo;

    return _SectionCard(
      title: 'Garage Logo',
      icon: Icons.image_rounded,
      child: Column(
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            child: logoUrl.isEmpty
                ? Center(
                    child: Icon(
                      Icons.business_rounded,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      '${ApiService.baseUrl.replaceAll('/api', '')}$logoUrl',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(
                          Icons.broken_image_rounded,
                          size: 48,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: provider.isUploadingLogo
                  ? null
                  : _pickLogo,
              icon: provider.isUploadingLogo
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.upload_rounded),
              label: Text(
                provider.isUploadingLogo
                    ? 'Uploading...'
                    : logoUrl.isEmpty
                        ? 'Upload Logo'
                        : 'Change Logo',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Square image recommended (500x500 px). PNG with transparent background works best.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COLORS SECTION
  // ============================================================

  Widget _buildColorsSection(ThemeData theme) {
    return _SectionCard(
      title: 'Brand Colors',
      icon: Icons.palette_rounded,
      child: Column(
        children: [
          _ColorRow(
            label: 'Primary Color',
            subtitle: 'Header background',
            color: _primaryColor,
            onTap: () => _pickColor(
              title: 'Primary Color',
              initial: _primaryColor,
              onPicked: (c) =>
                  setState(() => _primaryColor = c),
            ),
          ),
          const Divider(height: 24),
          _ColorRow(
            label: 'Secondary Color',
            subtitle: 'Total amount & accents',
            color: _secondaryColor,
            onTap: () => _pickColor(
              title: 'Secondary Color',
              initial: _secondaryColor,
              onPicked: (c) =>
                  setState(() => _secondaryColor = c),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FOOTER SECTION
  // ============================================================

  Widget _buildFooterSection(ThemeData theme) {
    return _SectionCard(
      title: 'Footer Message',
      icon: Icons.message_rounded,
      child: TextField(
        controller: _footerController,
        maxLength: 200,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Thank you for choosing our garage!',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  // ============================================================
  // TERMS SECTION
  // ============================================================

  Widget _buildTermsSection(ThemeData theme) {
    return _SectionCard(
      title: 'Terms & Conditions',
      icon: Icons.gavel_rounded,
      child: TextField(
        controller: _termsController,
        maxLength: 500,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText:
              'e.g. Payment due within 7 days. Warranty: 30 days on parts.',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  // ============================================================
  // UPI SECTION
  // ============================================================

  Widget _buildUpiSection(ThemeData theme) {
    return _SectionCard(
      title: 'UPI Payment',
      icon: Icons.qr_code_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _upiController,
            decoration: const InputDecoration(
              hintText: 'yourname@upi',
              labelText: 'UPI ID',
              prefixIcon: Icon(Icons.account_balance_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'A QR code will be automatically generated on your invoices for customers to pay via UPI.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SAVE BUTTON
  // ============================================================

  Widget _buildSaveButton(InvoiceSettingsProvider provider) {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: provider.isSaving ? null : _save,
        icon: provider.isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.save_rounded),
        label: Text(
          provider.isSaving ? 'Saving...' : 'Save Settings',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SECTION CARD
// ============================================================

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ============================================================
// COLOR ROW
// ============================================================

class _ColorRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ColorRow({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// INVOICE PREVIEW
// ============================================================

class _InvoicePreview extends StatelessWidget {
  final String garageName;
  final Color primaryColor;
  final Color secondaryColor;
  final String footerMessage;
  final String terms;
  final String upiId;
  final String logoUrl;

  const _InvoicePreview({
    required this.garageName,
    required this.primaryColor,
    required this.secondaryColor,
    required this.footerMessage,
    required this.terms,
    required this.upiId,
    required this.logoUrl,
  });

  // ============================================================
  // SMART CONTRAST COLOR
  // ============================================================

  Color _getContrastColor(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final headerTextColor = _getContrastColor(primaryColor);
    final totalTextColor = _getContrastColor(secondaryColor);
    final mutedHeaderColor =
        _getContrastColor(primaryColor).withOpacity(0.75);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // HEADER
            // ==================================================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  // Logo
                  if (logoUrl.isNotEmpty)
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          '${ApiService.baseUrl.replaceAll('/api', '')}$logoUrl',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.business_rounded,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.business_rounded,
                        color: headerTextColor,
                      ),
                    ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          garageName,
                          style: TextStyle(
                            color: headerTextColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Address, City\nPhone | Email',
                          style: TextStyle(
                            color: mutedHeaderColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'INVOICE',
                        style: TextStyle(
                          color: headerTextColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '#INV-2026-00001',
                        style: TextStyle(
                          color: headerTextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ==================================================
            // BODY
            // ==================================================
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --------------------------------------------
                  // CUSTOMER + VEHICLE
                  // --------------------------------------------
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BILL TO',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Customer Name',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Phone: 9876543210',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VEHICLE',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'MP09AB1234',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Honda City',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // --------------------------------------------
                  // AMOUNTS TABLE
                  // --------------------------------------------
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius:
                                const BorderRadius.vertical(
                              top: Radius.circular(5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Description',
                                  style: TextStyle(
                                    color: headerTextColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Text(
                                'Amount',
                                style: TextStyle(
                                  color: headerTextColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),

                        _previewRow('Labour Charges', 'Rs. 500.00'),
                        _previewRow('Parts Charges', 'Rs. 1000.00'),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: secondaryColor,
                            borderRadius:
                                const BorderRadius.vertical(
                              bottom: Radius.circular(5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'TOTAL',
                                  style: TextStyle(
                                    color: totalTextColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Text(
                                'Rs. 1500.00',
                                style: TextStyle(
                                  color: totalTextColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --------------------------------------------
                  // UPI QR SECTION
                  // --------------------------------------------
                  if (upiId.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      'PAYMENT',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          child: const Icon(
                            Icons.qr_code_2_rounded,
                            size: 50,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'UPI ID:',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                upiId,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Pay via any UPI app\n(GPay, PhonePe, Paytm)',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  // --------------------------------------------
                  // TERMS
                  // --------------------------------------------
                  if (terms.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      'TERMS & CONDITIONS',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      terms,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black87,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  // --------------------------------------------
                  // FOOTER
                  // --------------------------------------------
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      children: [
                        Text(
                          footerMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Powered by GarageMate',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PREVIEW ROW (single definition)
  // ============================================================

  Widget _previewRow(String label, String amount) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}