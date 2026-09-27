import 'package:flutter/foundation.dart';

import '../../../core/services/api_service.dart';
import '../models/subscription_usage.dart';

class SubscriptionProvider extends ChangeNotifier {
  // ============================================================
  // STATE
  // ============================================================

  SubscriptionUsage? _usage;

  bool _isLoading = false;
  String? _error;

  // ============================================================
  // GETTERS
  // ============================================================

  SubscriptionUsage? get usage => _usage;

  bool get isLoading => _isLoading;

  String? get error => _error;

  bool get hasReachedLimit =>
      _usage?.hasReachedLimit ?? false;

  bool get isNearLimit =>
      _usage?.isNearLimit ?? false;

  bool get canStartTrial =>
      _usage?.canStartTrial ?? false;

  // ============================================================
  // FETCH USAGE
  // ============================================================

  Future<void> fetchUsage() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await ApiService.getSubscriptionUsage();

      if (response['success'] == true &&
          response['usage'] != null) {
        _usage = SubscriptionUsage.fromJson(
          Map<String, dynamic>.from(
            response['usage'],
          ),
        );
      } else {
        _error = response['message']?.toString() ??
            'Unable to load usage';
      }
    } catch (e) {
      _error = e.toString().replaceAll(
        'Exception: ',
        '',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // START FREE TRIAL
  // ============================================================

  Future<bool> startTrial() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await ApiService.startFreeTrial();

      if (response['success'] == true) {
        // Refresh usage after trial starts
        await fetchUsage();
        return true;
      }

      _error = response['message']?.toString() ??
          'Unable to start trial';
      return false;
    } catch (e) {
      _error = e.toString().replaceAll(
        'Exception: ',
        '',
      );
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // REQUEST MANUAL UPGRADE
  // ============================================================

  Future<bool> requestUpgrade({
    required String plan,
    String paymentReference = '',
    String notes = '',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await ApiService.requestSubscriptionUpgrade(
        requestedPlan: plan,
        paymentReference: paymentReference,
        notes: notes,
      );

      if (response['success'] == true) {
        return true;
      }

      _error = response['message']?.toString() ??
          'Unable to submit request';
      return false;
    } catch (e) {
      _error = e.toString().replaceAll(
        'Exception: ',
        '',
      );
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ============================================================
  // RESET (on logout)
  // ============================================================

  void reset() {
    _usage = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}