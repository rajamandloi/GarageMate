import 'package:flutter/foundation.dart';

import '../../../core/services/api_service.dart';
import '../models/invoice_settings_model.dart';

class InvoiceSettingsProvider extends ChangeNotifier {
  InvoiceSettings _settings = InvoiceSettings();
  String _garageName = 'Garage';

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUploadingLogo = false;
  String? _error;

  InvoiceSettings get settings => _settings;
  String get garageName => _garageName;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isUploadingLogo => _isUploadingLogo;
  String? get error => _error;

  // ============================================================
  // FETCH
  // ============================================================

  Future<void> fetchSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getInvoiceSettings();

      if (response['success'] == true) {
        _garageName =
            response['garageName']?.toString() ?? 'Garage';

        final data = response['settings'];
        if (data is Map) {
          _settings = InvoiceSettings.fromJson(
            Map<String, dynamic>.from(data),
          );
        }
      } else {
        _error = response['message']?.toString() ??
            'Unable to load invoice settings';
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // UPDATE SETTINGS
  // ============================================================

  Future<bool> updateSettings({
    String? primaryColor,
    String? secondaryColor,
    String? footerMessage,
    String? termsAndConditions,
    String? upiId,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.updateInvoiceSettings(
        primaryColor: primaryColor,
        secondaryColor: secondaryColor,
        footerMessage: footerMessage,
        termsAndConditions: termsAndConditions,
        upiId: upiId,
      );

      if (response['success'] == true) {
        final data = response['settings'];
        if (data is Map) {
          _settings = InvoiceSettings.fromJson(
            Map<String, dynamic>.from(data),
          );
        }
        return true;
      }

      _error = response['message']?.toString() ??
          'Unable to save settings';
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ============================================================
  // UPLOAD LOGO
  // ============================================================

  Future<bool> uploadLogo(String filePath) async {
    _isUploadingLogo = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.uploadInvoiceLogo(filePath);

      if (response['success'] == true) {
        final logo = response['logo']?.toString() ?? '';
        _settings = _settings.copyWith(logo: logo);
        return true;
      }

      _error = response['message']?.toString() ??
          'Unable to upload logo';
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isUploadingLogo = false;
      notifyListeners();
    }
  }

  // ============================================================
  // RESET
  // ============================================================

  void reset() {
    _settings = InvoiceSettings();
    _garageName = 'Garage';
    _error = null;
    notifyListeners();
  }
}