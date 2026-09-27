import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  // ============================================================
  // BASE URL
  // ============================================================

  static const String baseUrl = 'http://10.230.60.25:5000/api';

  static const Duration _requestTimeout = Duration(seconds: 20);

  /// Development may use HTTP on a trusted local network. Release builds
  /// must use HTTPS so credentials, tokens and customer data are encrypted.
  static void assertProductionTransportIsSecure() {
    if (kReleaseMode && !baseUrl.toLowerCase().startsWith('https://')) {
      throw StateError('GarageMate production API must use HTTPS.');
    }
  }

  // ============================================================
  // SECURE STORAGE
  // ============================================================

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _accessTokenKey = 'garagemate_access_token';
  static const String _refreshTokenKey = 'garagemate_refresh_token';

  // ============================================================
  // IN-MEMORY TOKENS
  // ============================================================

  static String? token;
  static String? refreshToken;

  // Prevent multiple API requests from refreshing the token
  // at the same time.
  static Future<bool>? _refreshingToken;

  // ============================================================
  // INITIALIZE AUTH SESSION
  // ============================================================

  /// Restores the saved session from secure device storage.
  ///
  /// Called by SplashScreen when the application starts.
  static Future<void> initialize() async {
    assertProductionTransportIsSecure();
    try {
      final savedAccessToken = await _storage.read(key: _accessTokenKey);
      final savedRefreshToken = await _storage.read(key: _refreshTokenKey);

      token = savedAccessToken;
      refreshToken = savedRefreshToken;
    } catch (error) {
      token = null;
      refreshToken = null;

      _debugLog('Auth session restore failed.');
    }
  }

  // ============================================================
  // SAVE SESSION
  // ============================================================

  /// Saves both access token and refresh token securely.
  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
  }) async {
    final cleanAccessToken = accessToken.trim();
    final cleanRefreshToken = refreshToken.trim();

    if (cleanAccessToken.isEmpty) {
      throw Exception('Access token is empty.');
    }

    if (cleanRefreshToken.isEmpty) {
      throw Exception('Refresh token is empty.');
    }

    // Update memory
    token = cleanAccessToken;
    ApiService.refreshToken = cleanRefreshToken;

    // Save securely
    await _storage.write(key: _accessTokenKey, value: cleanAccessToken);
    await _storage.write(key: _refreshTokenKey, value: cleanRefreshToken);
  }

  // ============================================================
  // SAVE REFRESHED SESSION
  // ============================================================

  static Future<void> updateAccessToken({
    required String accessToken,
    required String refreshToken,
  }) async {
    await saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  // ============================================================
  // LOGIN STATUS
  // ============================================================

  static bool get isLoggedIn {
    return token != null &&
        token!.isNotEmpty &&
        refreshToken != null &&
        refreshToken!.isNotEmpty;
  }

  // ============================================================
  // HEADERS
  // ============================================================

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  // ============================================================
  // GET
  // ============================================================

  static Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl$endpoint'),
          headers: _headers,
        )
        .timeout(_requestTimeout);

    return _handleResponseWithRefresh(
      response,
      () => get(endpoint),
    );
  }

  // ============================================================
  // POST
  // ============================================================

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl$endpoint'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(_requestTimeout);

    return _handleResponseWithRefresh(
      response,
      () => post(endpoint, body),
    );
  }

  // ============================================================
  // PUT
  // ============================================================

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl$endpoint'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(_requestTimeout);

    return _handleResponseWithRefresh(
      response,
      () => put(endpoint, body),
    );
  }

  // ============================================================
  // PATCH
  // ============================================================

  static Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl$endpoint'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(_requestTimeout);

    return _handleResponseWithRefresh(
      response,
      () => patch(endpoint, body),
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl$endpoint'),
          headers: _headers,
        )
        .timeout(_requestTimeout);

    return _handleResponseWithRefresh(
      response,
      () => delete(endpoint),
    );
  }

  // ============================================================
  // HANDLE RESPONSE + AUTOMATIC REFRESH
  // ============================================================

  static Future<Map<String, dynamic>> _handleResponseWithRefresh(
    http.Response response,
    Future<Map<String, dynamic>> Function() retryRequest,
  ) async {
    // ----------------------------------------------------------
    // SUCCESS
    // ----------------------------------------------------------

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeResponse(response);
    }

    // ----------------------------------------------------------
    // ACCESS TOKEN EXPIRED
    // ----------------------------------------------------------

    if (response.statusCode == 401 &&
        token != null &&
        refreshToken != null) {
      final refreshed = await _refreshAccessToken();

      if (refreshed) {
        // Retry original request with
        // newly generated access token.
        return await retryRequest();
      }

      // Refresh failed.
      await logoutLocal();

      throw Exception('Your session has expired. Please login again.');
    }

    // ----------------------------------------------------------
    // OTHER ERROR
    // ----------------------------------------------------------

    throw _extractError(response);
  }

  // ============================================================
  // REFRESH ACCESS TOKEN
  // ============================================================

  static Future<bool> _refreshAccessToken() async {
    // If another API request is already refreshing,
    // wait for that same operation.
    if (_refreshingToken != null) {
      return await _refreshingToken!;
    }

    _refreshingToken = _performTokenRefresh();

    try {
      return await _refreshingToken!;
    } finally {
      _refreshingToken = null;
    }
  }

  // ============================================================
  // PERFORM TOKEN REFRESH
  // ============================================================

  static Future<bool> _performTokenRefresh() async {
    try {
      if (refreshToken == null || refreshToken!.isEmpty) {
        return false;
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/refresh'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'refreshToken': refreshToken,
            }),
          )
          .timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }

      final data = _decodeResponse(response);

      if (data['success'] != true) {
        return false;
      }

      final newAccessToken = data['accessToken'];
      final newRefreshToken = data['refreshToken'];

      if (newAccessToken == null || newRefreshToken == null) {
        return false;
      }

      await updateAccessToken(
        accessToken: newAccessToken.toString(),
        refreshToken: newRefreshToken.toString(),
      );

      return true;
    } catch (error) {
      _debugLog('Token refresh failed.');
      return false;
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  static Future<void> logout() async {
    final currentRefreshToken = refreshToken;

    // Clear local session first.
    // Even if server logout fails, the user
    // will still be logged out locally.
    await logoutLocal();

    // Revoke refresh token on backend.
    if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
      return;
    }

    try {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'refreshToken': currentRefreshToken,
        }),
      );
    } catch (error) {
      _debugLog('Server logout failed.');
    }
  }

  // ============================================================
  // LOCAL LOGOUT
  // ============================================================

  static Future<void> logoutLocal() async {
    token = null;
    refreshToken = null;

    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  // ============================================================
  // SAVE FCM TOKEN
  // ============================================================

  static Future<Map<String, dynamic>> saveFcmToken(String fcmToken) async {
    return await post(
      '/auth/fcm-token',
      {
        'fcmToken': fcmToken,
      },
    );
  }

  // ============================================================
  // UPLOAD GARAGE PROFILE IMAGE
  // ============================================================

  static Future<Map<String, dynamic>> uploadGarageProfileImage(
    String filePath,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/garage/profile/image'),
    );

    if (token != null && token!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final extension = filePath.split('.').last.toLowerCase();

    MediaType contentType;

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        contentType = MediaType('image', 'jpeg');
        break;

      case 'png':
        contentType = MediaType('image', 'png');
        break;

      case 'webp':
        contentType = MediaType('image', 'webp');
        break;

      default:
        throw Exception('Only JPG, PNG and WEBP images are allowed');
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'profileImage',
        filePath,
        contentType: contentType,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    // Multipart requests also need
    // automatic refresh support.
    if (response.statusCode == 401 &&
        token != null &&
        refreshToken != null) {
      final refreshed = await _refreshAccessToken();

      if (refreshed) {
        return await uploadGarageProfileImage(filePath);
      }

      await logoutLocal();

      throw Exception('Your session has expired. Please login again.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeResponse(response);
    }

    throw _extractError(response);
  }

  // ============================================================
  // INVOICE SETTINGS - GET
  // ============================================================

  static Future<Map<String, dynamic>> getInvoiceSettings() async {
    return await get('/garage/invoice-settings');
  }

  // ============================================================
  // INVOICE SETTINGS - UPDATE
  // ============================================================

  static Future<Map<String, dynamic>> updateInvoiceSettings({
    String? primaryColor,
    String? secondaryColor,
    String? footerMessage,
    String? termsAndConditions,
    String? upiId,
  }) async {
    return await put('/garage/invoice-settings', {
      if (primaryColor != null) 'primaryColor': primaryColor,
      if (secondaryColor != null) 'secondaryColor': secondaryColor,
      if (footerMessage != null) 'footerMessage': footerMessage,
      if (termsAndConditions != null)
        'termsAndConditions': termsAndConditions,
      if (upiId != null) 'upiId': upiId,
    });
  }

  // ============================================================
  // INVOICE LOGO - UPLOAD
  // ============================================================

  static Future<Map<String, dynamic>> uploadInvoiceLogo(
    String filePath,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/garage/invoice-logo'),
    );

    if (token != null && token!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final extension = filePath.split('.').last.toLowerCase();

    MediaType contentType;

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        contentType = MediaType('image', 'jpeg');
        break;

      case 'png':
        contentType = MediaType('image', 'png');
        break;

      case 'webp':
        contentType = MediaType('image', 'webp');
        break;

      default:
        throw Exception('Only JPG, PNG and WEBP images are allowed');
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'logo',
        filePath,
        contentType: contentType,
      ),
    );

    final streamedResponse = await request.send();
    final response =
        await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 401 &&
        token != null &&
        refreshToken != null) {
      final refreshed = await _refreshAccessToken();

      if (refreshed) {
        return await uploadInvoiceLogo(filePath);
      }

      await logoutLocal();
      throw Exception('Your session has expired. Please login again.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeResponse(response);
    }

    throw _extractError(response);
  }

    // ============================================================
  // STAFF - LIST
  // ============================================================

  static Future<Map<String, dynamic>> getStaffList() async {
    return await get('/staff');
  }

  // ============================================================
  // STAFF - ADD
  // ============================================================

  static Future<Map<String, dynamic>> addStaff({
    required String name,
    required String phone,
    required String staffRole,
    String? password,
  }) async {
    return await post('/staff', {
      'name': name,
      'phone': phone,
      'staffRole': staffRole,
      if (password != null && password.isNotEmpty)
        'password': password,
    });
  }

  // ============================================================
  // STAFF - UPDATE ROLE
  // ============================================================

  static Future<Map<String, dynamic>> updateStaffRole({
    required String staffId,
    required String staffRole,
  }) async {
    return await put('/staff/$staffId/role', {
      'staffRole': staffRole,
    });
  }

  // ============================================================
  // STAFF - TOGGLE ACTIVE
  // ============================================================

  static Future<Map<String, dynamic>> toggleStaffActive(
    String staffId,
  ) async {
    return await patch('/staff/$staffId/toggle', {});
  }

  // ============================================================
  // STAFF - RESET PASSWORD
  // ============================================================

  static Future<Map<String, dynamic>> resetStaffPassword({
    required String staffId,
    required String newPassword,
  }) async {
    return await put('/staff/$staffId/password', {
      'newPassword': newPassword,
    });
  }

  // ============================================================
  // STAFF - DELETE
  // ============================================================

  static Future<Map<String, dynamic>> deleteStaff(
    String staffId,
  ) async {
    return await delete('/staff/$staffId');
  }

  // ============================================================
  // STAFF - ACTIVITY LOG
  // ============================================================

  static Future<Map<String, dynamic>> getActivityLog({
    int limit = 50,
    String? userId,
  }) async {
    String endpoint = '/staff/activity?limit=$limit';
    if (userId != null) endpoint += '&userId=$userId';

    return await get(endpoint);
  }
  
  // ============================================================
  // WHATSAPP - FETCH CUSTOMERS
  // ============================================================

  static Future<List<Map<String, dynamic>>> fetchCustomers() async {
    final response = await get('/customers');

    final List list = response['customers'] ?? response['data'] ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // ============================================================
  // WHATSAPP - SEND TEMPLATE MESSAGE (no PDF)
  // ============================================================

  static Future<Map<String, dynamic>> sendWhatsAppTemplate({
    required String templateName,
    required String recipientPhone,
    required List<String> bodyParameters,
    String languageCode = 'en',
    String type = 'general',
    String? customerId,
    String? vehicleId,
    String? reminderId,
  }) async {
    return await post('/whatsapp/send', {
      'to': recipientPhone,
      'templateName': templateName,
      'languageCode': languageCode,
      'type': type,
      'bodyParameters': bodyParameters,
      if (customerId != null) 'customerId': customerId,
      if (vehicleId != null) 'vehicleId': vehicleId,
      if (reminderId != null) 'reminderId': reminderId,
    });
  }

  // ============================================================
  // WHATSAPP - SEND TEMPLATE + PDF
  // ============================================================

  static Future<Map<String, dynamic>> sendWhatsAppTemplateWithPdf({
    required String templateName,
    required String recipientPhone,
    required List<String> bodyParameters,
    required String pdfUrl,
    String pdfFileName = 'invoice.pdf',
    String languageCode = 'en',
    String type = 'general',
    String? customerId,
    String? vehicleId,
    String? reminderId,
  }) async {
    return await post('/whatsapp/send-with-pdf', {
      'to': recipientPhone,
      'templateName': templateName,
      'languageCode': languageCode,
      'type': type,
      'bodyParameters': bodyParameters,
      'pdfUrl': pdfUrl,
      'pdfFileName': pdfFileName,
      if (customerId != null) 'customerId': customerId,
      if (vehicleId != null) 'vehicleId': vehicleId,
      if (reminderId != null) 'reminderId': reminderId,
    });
  }

  // ============================================================
  // WHATSAPP - SEND INVOICE (specific invoice)
  // ============================================================

  static Future<Map<String, dynamic>> sendInvoiceOnWhatsApp({
    required String invoiceId,
  }) async {
    return await post('/invoices/$invoiceId/send-whatsapp', {});
  }

  // ============================================================
  // WHATSAPP - FETCH INVOICES
  // ============================================================

  static Future<List<Map<String, dynamic>>> fetchInvoices({
    String? customerId,
  }) async {
    final endpoint = customerId != null
        ? '/invoices/customer/$customerId'
        : '/invoices';

    final response = await get(endpoint);

    final List list = response['invoices'] ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // ============================================================
  // AUTOMATION - GET SETTINGS
  // ============================================================

  static Future<Map<String, dynamic>> getAutomationSettings() async {
    return await get('/automation/settings');
  }

  // ============================================================
  // AUTOMATION - UPDATE SETTINGS
  // ============================================================

  static Future<Map<String, dynamic>> updateAutomationSettings({
    bool? automationEnabled,
    bool? serviceRemindersEnabled,
    bool? specialOffersEnabled,
    bool? paymentRemindersEnabled,
    String? serviceTemplate,
    String? offerTemplate,
    String? paymentTemplate,
  }) async {
    return await put('/automation/settings', {
      if (automationEnabled != null)
        'automationEnabled': automationEnabled,
      if (serviceRemindersEnabled != null)
        'serviceRemindersEnabled': serviceRemindersEnabled,
      if (specialOffersEnabled != null)
        'specialOffersEnabled': specialOffersEnabled,
      if (paymentRemindersEnabled != null)
        'paymentRemindersEnabled': paymentRemindersEnabled,
      if (serviceTemplate != null)
        'serviceTemplate': serviceTemplate,
      if (offerTemplate != null) 'offerTemplate': offerTemplate,
      if (paymentTemplate != null)
        'paymentTemplate': paymentTemplate,
    });
  }

  // ============================================================
  // AUTOMATION - SEND NOW
  // category: "service" | "payment" | "offer" | "all"
  // ============================================================

  static Future<Map<String, dynamic>> sendAutomationNow({
    String category = "all",
  }) async {
    return await post('/automation/send-now', {
      'category': category,
    });
  }

    // ============================================================
  // SUBSCRIPTION - GET CURRENT USAGE
  // ============================================================

  static Future<Map<String, dynamic>> getSubscriptionUsage() async {
    return await get('/subscription/current');
  }

  // ============================================================
  // SUBSCRIPTION - GET ALL PLANS
  // ============================================================

  static Future<Map<String, dynamic>> getSubscriptionPlans() async {
    return await get('/subscription/plans');
  }

  // ============================================================
  // SUBSCRIPTION - START FREE TRIAL
  // ============================================================

  static Future<Map<String, dynamic>> startFreeTrial() async {
    return await post('/subscription/start-trial', {});
  }

  // ============================================================
  // SUBSCRIPTION - REQUEST MANUAL UPGRADE
  // ============================================================

  static Future<Map<String, dynamic>> requestSubscriptionUpgrade({
    required String requestedPlan,
    String paymentReference = '',
    String notes = '',
  }) async {
    return await post('/subscription/request-upgrade', {
      'requestedPlan': requestedPlan,
      'paymentReference': paymentReference,
      'notes': notes,
    });
  }
  
  // ============================================================
  // DEBUG LOG
  // ============================================================

  static void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('GarageMate: $message');
    }
  }

  // ============================================================
  // RESPONSE DECODER
  // ============================================================

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      return {};
    } catch (_) {
      throw Exception('Server returned an invalid response.');
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  static Exception _extractError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map && decoded['message'] != null) {
        return Exception(decoded['message'].toString());
      }
    } catch (_) {}

    return Exception('Something went wrong. Please try again.');
  }
}