import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/api_service.dart';
import '../../../core/utils/phone_helper.dart';
import '../../../features/auth/screens/login_screen.dart';
import '../../subscription/providers/subscription_provider.dart';
import '../../subscription/screens/subscription_screen.dart';

class GarageProfileScreen extends StatefulWidget {
  const GarageProfileScreen({super.key});

  @override
  State<GarageProfileScreen> createState() =>
      _GarageProfileScreenState();
}

class _GarageProfileScreenState
    extends State<GarageProfileScreen> {
  bool _isLoading = true;
  bool _isUploadingImage = false;
  bool _isLoggingOut = false;

  String? _error;

  final ImagePicker _imagePicker = ImagePicker();

  Map<String, dynamic>? _user;
  Map<String, dynamic>? _garage;

  // ============================================================
  // ADMIN WHATSAPP NUMBER (sirf 10 digit)
  // ============================================================

  static const String _adminPhone = '8889353432';

  @override
  void initState() {
    super.initState();
    _loadProfile();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SubscriptionProvider>().fetchUsage();
    });
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final response = await ApiService.get('/auth/me');

      if (!mounted) return;

      final userData = response['user'];

      if (userData is Map) {
        _user = Map<String, dynamic>.from(userData);

        final garageData = userData['garage'];

        if (garageData is Map) {
          _garage = Map<String, dynamic>.from(garageData);
        } else {
          _garage = null;
        }
      } else {
        _user = null;
        _garage = null;
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = error.toString();
      });
    }
  }

  // ============================================================
  // CHANGE PROFILE IMAGE
  // ============================================================

  Future<void> _changeGarageProfileImage() async {
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context, ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context, ImageSource.camera);
                  },
                ),
              ],
            ),
          );
        },
      );

      if (source == null || !mounted) return;

      final XFile? pickedImage = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedImage == null || !mounted) return;

      setState(() {
        _isUploadingImage = true;
      });

      final response =
          await ApiService.uploadGarageProfileImage(
        pickedImage.path,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        await _loadProfile();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Garage profile picture updated'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message']?.toString() ??
                  'Unable to update profile picture',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await ApiService.logoutLocal();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $error'),
        ),
      );
    }
  }

  // ============================================================
  // EDIT PROFILE FIELD
  // ============================================================

  Future<void> _editField({
    required String title,
    required String initialValue,
    required String field,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => EditProfileFieldScreen(
          title: title,
          initialValue: initialValue == 'Not provided'
              ? ''
              : initialValue,
          keyboardType: keyboardType,
          maxLines: maxLines,
        ),
      ),
    );

    if (!mounted || result == null) return;

    final success = await _updateProfileField(field, result);

    if (!mounted) return;

    if (success) {
      await _loadProfile();
    }
  }

  // ============================================================
  // UPDATE PROFILE API
  // ============================================================

  Future<bool> _updateProfileField(
    String field,
    String value,
  ) async {
    try {
      final Map<String, dynamic> body = {};

      switch (field) {
        case 'phone':
          body['ownerPhone'] = value;
          break;

        case 'garageName':
          body['name'] = value;
          break;

        case 'ownerName':
          body['ownerName'] = value;
          break;

        case 'garagePhone':
          body['garagePhone'] = value;
          break;

        case 'garageEmail':
          body['garageEmail'] = value;
          break;

        case 'garageAddress':
          body['address'] = value;
          break;

        case 'city':
          body['city'] = value;
          break;

        default:
          return false;
      }

      final response = await ApiService.put(
        '/garage/profile',
        body,
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
            ),
          );
        }

        return true;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message']?.toString() ??
                  'Unable to update profile',
            ),
          ),
        );
      }

      return false;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }

      return false;
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _value(dynamic value) {
    if (value == null ||
        value.toString().trim().isEmpty) {
      return 'Not provided';
    }

    return value.toString();
  }

  /// ✅ Phone display — 10 digit only
  String _displayPhone(dynamic value) {
    if (value == null ||
        value.toString().trim().isEmpty) {
      return 'Not provided';
    }

    final ten = PhoneHelper.extractTenDigits(
      value.toString(),
    );

    if (ten.length == 10) {
      return '+91 $ten';
    }

    return value.toString();
  }

  String _formatStatus(dynamic value) {
    final status = value?.toString() ?? '';

    if (status.isEmpty) {
      return 'Unknown';
    }

    return status[0].toUpperCase() + status.substring(1);
  }

  String _formatDate(dynamic value) {
    if (value == null ||
        value.toString().trim().isEmpty) {
      return 'Not set';
    }

    final date = DateTime.tryParse(value.toString());

    if (date == null) {
      return value.toString();
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatDateFromDateTime(DateTime? date) {
    if (date == null) return 'Not set';

    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  // ============================================================
  // WHATSAPP CONTACT (using helper)
  // ============================================================

  Future<void> _contactOnWhatsApp(String planName) async {
    final planLabel = planName == 'pro'
        ? 'Pro (₹199/month)'
        : planName == 'business'
            ? 'Business (₹499/month)'
            : planName == 'founder'
                ? "Founder's Plan (₹149/month)"
                : planName;

    final message = '''
Hello GarageMate Team,

I want to upgrade my subscription.

🏢 Garage: ${_value(_garage?['name'])}
👤 Owner: ${_value(_user?['name'])}
📞 Phone: ${_value(_garage?['phone'])}
📧 Email: ${_value(_garage?['email'])}

📦 Plan: $planLabel

Please guide me on the next steps for payment.
''';

    // ✅ Helper use karo — 91 automatically lagega
    final url = PhoneHelper.buildWhatsAppUrl(
      phone: _adminPhone,
      message: message,
    );

    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to open WhatsApp. Please install WhatsApp.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open WhatsApp: $e'),
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
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(theme)
              : RefreshIndicator(
                  onRefresh: () async {
                    await _loadProfile();
                    if (!mounted) return;
                    await context
                        .read<SubscriptionProvider>()
                        .fetchUsage();
                  },
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      20,
                      20,
                      40,
                    ),
                    children: [
                      _buildProfileHeader(theme),

                      const SizedBox(height: 24),

                      const _SectionTitle(
                        title: 'Owner Information',
                      ),

                      const SizedBox(height: 10),

                      _ProfileCard(
                        icon: Icons.person_outline_rounded,
                        title: 'Name',
                        value: _value(_user?['name']),
                      ),

                      const SizedBox(height: 10),

                      _ProfileCard(
                        icon: Icons.email_outlined,
                        title: 'Email',
                        value: _value(_user?['email']),
                      ),

                      const SizedBox(height: 10),

                      _ProfileCard(
                        icon: Icons.phone_outlined,
                        title: 'Phone',
                        value: _displayPhone(_user?['phone']),
                        editable: true,
                        onEdit: () {
                          _editField(
                            title: 'Phone',
                            initialValue:
                                PhoneHelper.extractTenDigits(
                              _user?['phone']?.toString() ?? '',
                            ),
                            field: 'phone',
                            keyboardType: TextInputType.phone,
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      const _SectionTitle(
                        title: 'Garage Information',
                      ),

                      const SizedBox(height: 10),

                      _ProfileCard(
                        icon: Icons.store_outlined,
                        title: 'Garage Name',
                        value: _value(_garage?['name']),
                        editable: true,
                        onEdit: () {
                          _editField(
                            title: 'Garage Name',
                            initialValue:
                                _value(_garage?['name']),
                            field: 'garageName',
                          );
                        },
                      ),

                      const SizedBox(height: 10),

                      _ProfileCard(
                        icon: Icons.badge_outlined,
                        title: 'Owner Name',
                        value: _value(_garage?['ownerName']),
                        editable: true,
                        onEdit: () {
                          _editField(
                            title: 'Owner Name',
                            initialValue:
                                _value(_garage?['ownerName']),
                            field: 'ownerName',
                          );
                        },
                      ),

                      const SizedBox(height: 10),

                      _ProfileCard(
                        icon: Icons.phone_outlined,
                        title: 'Garage Phone',
                        value: _displayPhone(_garage?['phone']),
                        editable: true,
                        onEdit: () {
                          _editField(
                            title: 'Garage Phone',
                            initialValue:
                                PhoneHelper.extractTenDigits(
                              _garage?['phone']?.toString() ?? '',
                            ),
                            field: 'garagePhone',
                            keyboardType: TextInputType.phone,
                          );
                        },
                      ),

                      const SizedBox(height: 10),

                      _ProfileCard(
                        icon: Icons.email_outlined,
                        title: 'Garage Email',
                        value: _value(_garage?['email']),
                        editable: true,
                        onEdit: () {
                          _editField(
                            title: 'Garage Email',
                            initialValue:
                                _value(_garage?['email']),
                            field: 'garageEmail',
                            keyboardType:
                                TextInputType.emailAddress,
                          );
                        },
                      ),

                      const SizedBox(height: 10),

                      _ProfileCard(
                        icon: Icons.location_on_outlined,
                        title: 'Address',
                        value: _value(_garage?['address']),
                        editable: true,
                        onEdit: () {
                          _editField(
                            title: 'Address',
                            initialValue:
                                _value(_garage?['address']),
                            field: 'garageAddress',
                            maxLines: 3,
                          );
                        },
                      ),

                      const SizedBox(height: 10),

                      _ProfileCard(
                        icon: Icons.location_city_outlined,
                        title: 'City',
                        value: _value(_garage?['city']),
                        editable: true,
                        onEdit: () {
                          _editField(
                            title: 'City',
                            initialValue:
                                _value(_garage?['city']),
                            field: 'city',
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      const _SectionTitle(title: 'Account'),

                      const SizedBox(height: 10),

                      _buildStatusCard(theme),

                      const SizedBox(height: 10),

                      _buildSubscriptionSection(theme),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoggingOut
                              ? null
                              : _logout,
                          icon: _isLoggingOut
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.logout_rounded,
                                ),
                          label: Text(
                            _isLoggingOut
                                ? 'Logging out...'
                                : 'Logout',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // ============================================================
  // SUBSCRIPTION SECTION
  // ============================================================

  Widget _buildSubscriptionSection(ThemeData theme) {
    return Consumer<SubscriptionProvider>(
      builder: (context, provider, child) {
        final usage = provider.usage;

        String planName = 'Free';
        String planExpiry = 'Not set';
        Color? planColor;
        bool canUpgrade = true;

        if (provider.isLoading && usage == null) {
          planName = 'Loading...';
          planExpiry = 'Loading...';
          canUpgrade = false;
        } else if (usage != null) {
          if (usage.isTrial) {
            planName = 'Pro (Trial)';
            planExpiry = _formatDateFromDateTime(
              usage.trialEndsAt,
            );
            planColor = Colors.orange;
          } else if (usage.isFounderPlan) {
            planName = "Founder's Plan";
            planExpiry = _formatDateFromDateTime(
              usage.periodEnd,
            );
            planColor = Colors.amber;
          } else if (usage.plan == 'business') {
            planName = 'Business';
            planExpiry = _formatDateFromDateTime(
              usage.periodEnd,
            );
            canUpgrade = false;
          } else if (usage.plan == 'pro') {
            planName = 'Pro';
            planExpiry = _formatDateFromDateTime(
              usage.periodEnd,
            );
          } else {
            planName = 'Free';
            planExpiry = 'Free forever';
          }
        }

        return Column(
          children: [
            _ProfileCard(
              icon: Icons.card_membership_outlined,
              title: 'Subscription Plan',
              value: planName,
              valueColor: planColor,
            ),

            const SizedBox(height: 10),

            _ProfileCard(
              icon: Icons.calendar_today_outlined,
              title: 'Subscription Expiry',
              value: planExpiry,
            ),

            if (canUpgrade) ...[
              const SizedBox(height: 16),
              _buildUpgradeCard(theme, usage),
            ],
          ],
        );
      },
    );
  }

  // ============================================================
  // UPGRADE CARD
  // ============================================================

  Widget _buildUpgradeCard(
    ThemeData theme,
    dynamic usage,
  ) {
    final isTrial = usage?.isTrial == true;
    final isFree = usage?.plan == 'free' && !isTrial;

    String title;
    String subtitle;
    IconData icon;
    Color iconColor;

    if (isTrial) {
      title = 'Upgrade Before Trial Ends';
      subtitle =
          'Trial ends on ${_formatDateFromDateTime(usage.trialEndsAt)}. '
          'Upgrade to keep Pro features.';
      icon = Icons.timer_rounded;
      iconColor = Colors.orange;
    } else if (isFree) {
      title = 'Upgrade Your Plan';
      subtitle =
          'Get more WhatsApp messages, custom invoices, and advanced features.';
      icon = Icons.workspace_premium_rounded;
      iconColor = Colors.amber;
    } else {
      title = 'Upgrade to Business';
      subtitle =
          'Get 2000 WhatsApp messages, 10 staff users, and more.';
      icon = Icons.rocket_launch_rounded;
      iconColor = theme.colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.15),
            theme.colorScheme.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const SubscriptionScreen(),
                        ),
                      ).then((_) {
                        if (!mounted) return;
                        context
                            .read<SubscriptionProvider>()
                            .fetchUsage();
                      });
                    },
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                    ),
                    label: Text(
                      isTrial ? 'Choose Plan' : 'View Plans',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          theme.colorScheme.primary,
                      foregroundColor:
                          theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                    ),
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
  // PROFILE HEADER
  // ============================================================

  Widget _buildProfileHeader(ThemeData theme) {
    final profileImage =
        _garage?['profileImage']?.toString();

    final hasProfileImage =
        profileImage != null && profileImage.isNotEmpty;

    String? imageUrl;

    if (hasProfileImage) {
      imageUrl =
          '${ApiService.baseUrl.replaceAll('/api', '')}'
          '$profileImage';
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  image: hasProfileImage
                      ? DecorationImage(
                          image: NetworkImage(imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: !hasProfileImage
                    ? Icon(
                        Icons.garage_rounded,
                        size: 36,
                        color:
                            theme.colorScheme.onPrimary,
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: theme.colorScheme.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _isUploadingImage
                        ? null
                        : _changeGarageProfileImage,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _isUploadingImage
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              Icons.camera_alt_rounded,
                              size: 18,
                              color: theme
                                  .colorScheme.onPrimary,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _value(_user?['name']),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Garage Owner',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  _value(_garage?['name']),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS CARD
  // ============================================================

  Widget _buildStatusCard(ThemeData theme) {
    final status =
        _garage?['status']?.toString().toLowerCase();

    final isActive = status == 'active';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.green.withValues(alpha: 0.12)
                  : theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isActive
                  ? Icons.check_circle_outline_rounded
                  : Icons.info_outline_rounded,
              color: isActive
                  ? Colors.green
                  : theme.colorScheme.error,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Garage Status',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatStatus(_garage?['status']),
                  style: TextStyle(
                    color: isActive
                        ? Colors.green
                        : theme.colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SECTION TITLE
// ============================================================

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

// ============================================================
// PROFILE CARD
// ============================================================

class _ProfileCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool editable;
  final VoidCallback? onEdit;
  final Color? valueColor;

  const _ProfileCard({
    required this.icon,
    required this.title,
    required this.value,
    this.editable = false,
    this.onEdit,
    this.valueColor,
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
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
          if (editable)
            IconButton(
              onPressed: onEdit,
              tooltip: 'Edit',
              icon: Icon(
                Icons.edit_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// EDIT PROFILE FIELD SCREEN (with phone support)
// ============================================================

class EditProfileFieldScreen extends StatefulWidget {
  final String title;
  final String initialValue;
  final TextInputType keyboardType;
  final int maxLines;

  const EditProfileFieldScreen({
    super.key,
    required this.title,
    required this.initialValue,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  State<EditProfileFieldScreen> createState() =>
      _EditProfileFieldScreenState();
}

class _EditProfileFieldScreenState
    extends State<EditProfileFieldScreen> {
  late final TextEditingController _controller;

  bool get _isPhoneField =>
      widget.keyboardType == TextInputType.phone;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.initialValue,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = _controller.text.trim();

    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Value cannot be empty'),
        ),
      );
      return;
    }

    // ✅ Phone validation
    if (_isPhoneField) {
      final error = PhoneHelper.validateIndianMobile(value);

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
        return;
      }

      // 91 + 10 digit me convert karke bhejo
      final full = PhoneHelper.toWhatsAppNumber(value);
      Navigator.of(context).pop(full);
      return;
    }

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit ${widget.title}',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          // ✅ Phone field with +91
          if (_isPhoneField)
            TextField(
              controller: _controller,
              keyboardType: TextInputType.phone,
              maxLines: 1,
              maxLength: 10,
              autofocus: true,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: InputDecoration(
                hintText: '10-digit mobile number',
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
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
                prefixIconConstraints:
                    const BoxConstraints(
                  minWidth: 60,
                  minHeight: 40,
                ),
                counterText: '',
                border: const OutlineInputBorder(),
              ),
            )
          else
            TextField(
              controller: _controller,
              keyboardType: widget.keyboardType,
              maxLines: widget.maxLines,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter ${widget.title}',
                border: const OutlineInputBorder(),
              ),
            ),

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}