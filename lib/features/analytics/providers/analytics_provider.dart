import 'package:flutter/foundation.dart';

import '../../../core/services/api_service.dart';
import '../models/analytics_model.dart';

class AnalyticsProvider extends ChangeNotifier {
  AnalyticsData? _data;
  bool _isLoading = false;
  String? _error;

  String _range = 'month';
  DateTime? _customStart;
  DateTime? _customEnd;

  AnalyticsData? get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get range => _range;
  DateTime? get customStart => _customStart;
  DateTime? get customEnd => _customEnd;

  // ============================================================
  // FETCH DASHBOARD
  // ============================================================

  Future<void> fetchDashboard({
    String? range,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    _error = null;

    if (range != null) _range = range;
    if (startDate != null) _customStart = startDate;
    if (endDate != null) _customEnd = endDate;

    notifyListeners();

    try {
      String endpoint =
          '/analytics/dashboard?range=$_range';

      if (_range == 'custom' &&
          _customStart != null &&
          _customEnd != null) {
        final start =
            '${_customStart!.year}-${_customStart!.month.toString().padLeft(2, '0')}-${_customStart!.day.toString().padLeft(2, '0')}';
        final end =
            '${_customEnd!.year}-${_customEnd!.month.toString().padLeft(2, '0')}-${_customEnd!.day.toString().padLeft(2, '0')}';

        endpoint += '&startDate=$start&endDate=$end';
      }

      final response = await ApiService.get(endpoint);

      if (response['success'] == true) {
        _data = AnalyticsData.fromJson(response);
      } else {
        _error = response['message']?.toString() ??
            'Unable to load analytics';
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // CHANGE RANGE
  // ============================================================

  Future<void> changeRange(String newRange) async {
    if (_range == newRange && newRange != 'custom') return;

    _range = newRange;
    notifyListeners();

    await fetchDashboard(range: newRange);
  }

  // ============================================================
  // CLEAR
  // ============================================================

  void clear() {
    _data = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}