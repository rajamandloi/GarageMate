import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../customers/models/customer.dart';
import '../../vehicles/models/vehicle.dart';
import '../../services/models/service_record.dart';

import '../models/search_result.dart';
import '../services/smart_search_service.dart';

class SearchProvider extends ChangeNotifier {
  String _query = '';
  List<SearchResultGroup> _groups = [];
  bool _isSearching = false;

  // Recent searches
  List<String> _recentSearches = [];

  static const String _recentKey = 'recent_searches';
  static const int _maxRecent = 5;

  // ============================================================
  // GETTERS
  // ============================================================

  String get query => _query;
  List<SearchResultGroup> get groups => _groups;
  bool get isSearching => _isSearching;
  bool get hasResults => _groups.isNotEmpty;

  int get totalResults {
    return _groups.fold(0, (sum, g) => sum + g.count);
  }

  List<String> get recentSearches =>
      List.unmodifiable(_recentSearches);

  // ============================================================
  // INIT
  // ============================================================

  Future<void> init() async {
    await _loadRecentSearches();
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void search({
    required String query,
    required List<Customer> customers,
    required List<Vehicle> vehicles,
    required List<ServiceRecord> services,
  }) {
    _query = query;

    if (query.trim().isEmpty) {
      _groups = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    // Perform search
    _groups = SmartSearchService.searchAll(
      customers: customers,
      vehicles: vehicles,
      services: services,
      query: query,
    );

    _isSearching = false;
    notifyListeners();
  }

  // ============================================================
  // CLEAR
  // ============================================================

  void clear() {
    _query = '';
    _groups = [];
    _isSearching = false;
    notifyListeners();
  }

  // ============================================================
  // SAVE RECENT SEARCH
  // ============================================================

  Future<void> saveRecentSearch(String query) async {
    final trimmed = query.trim();

    if (trimmed.isEmpty) return;

    // Remove if already exists (to move to top)
    _recentSearches.removeWhere(
      (s) => s.toLowerCase() == trimmed.toLowerCase(),
    );

    // Add to top
    _recentSearches.insert(0, trimmed);

    // Limit
    if (_recentSearches.length > _maxRecent) {
      _recentSearches = _recentSearches.sublist(0, _maxRecent);
    }

    notifyListeners();

    // Persist
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentKey, _recentSearches);
  }

  // ============================================================
  // REMOVE RECENT SEARCH
  // ============================================================

  Future<void> removeRecentSearch(String query) async {
    _recentSearches.remove(query);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentKey, _recentSearches);
  }

  // ============================================================
  // CLEAR ALL RECENT
  // ============================================================

  Future<void> clearRecentSearches() async {
    _recentSearches = [];
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentKey);
  }

  // ============================================================
  // LOAD RECENT SEARCHES
  // ============================================================

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _recentSearches = prefs.getStringList(_recentKey) ?? [];
      notifyListeners();
    } catch (_) {
      _recentSearches = [];
    }
  }
}