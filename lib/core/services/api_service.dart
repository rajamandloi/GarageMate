import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  // ============================================================
  // BASE URL
  // ============================================================

  static const String baseUrl =
      'http://10.229.89.250:5000/api';

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

  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static const String _accessTokenKey =
      'garagemate_access_token';

  static const String _refreshTokenKey =
      'garagemate_refresh_token';

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
      final savedAccessToken =
          await _storage.read(
        key: _accessTokenKey,
      );

      final savedRefreshToken =
          await _storage.read(
        key: _refreshTokenKey,
      );

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
    final cleanAccessToken =
        accessToken.trim();

    final cleanRefreshToken =
        refreshToken.trim();

    if (cleanAccessToken.isEmpty) {
      throw Exception(
        'Access token is empty.',
      );
    }

    if (cleanRefreshToken.isEmpty) {
      throw Exception(
        'Refresh token is empty.',
      );
    }

    // Update memory
    token = cleanAccessToken;
    ApiService.refreshToken =
        cleanRefreshToken;

    // Save securely
    await _storage.write(
      key: _accessTokenKey,
      value: cleanAccessToken,
    );

    await _storage.write(
      key: _refreshTokenKey,
      value: cleanRefreshToken,
    );
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
        if (token != null &&
            token!.isNotEmpty)
          'Authorization':
              'Bearer $token',
      };

  // ============================================================
  // GET
  // ============================================================

  static Future<Map<String, dynamic>> get(
    String endpoint,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
    ).timeout(_requestTimeout);

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
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: jsonEncode(body),
    ).timeout(_requestTimeout);

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
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: jsonEncode(body),
    ).timeout(_requestTimeout);

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
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: jsonEncode(body),
    ).timeout(_requestTimeout);

    return _handleResponseWithRefresh(
      response,
      () => patch(endpoint, body),
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  static Future<Map<String, dynamic>> delete(
    String endpoint,
  ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
    ).timeout(_requestTimeout);

    return _handleResponseWithRefresh(
      response,
      () => delete(endpoint),
    );
  }

  // ============================================================
  // HANDLE RESPONSE + AUTOMATIC REFRESH
  // ============================================================

  static Future<Map<String, dynamic>>
      _handleResponseWithRefresh(
    http.Response response,
    Future<Map<String, dynamic>> Function()
        retryRequest,
  ) async {
    // ----------------------------------------------------------
    // SUCCESS
    // ----------------------------------------------------------

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return _decodeResponse(response);
    }

    // ----------------------------------------------------------
    // ACCESS TOKEN EXPIRED
    // ----------------------------------------------------------

    if (response.statusCode == 401 &&
        token != null &&
        refreshToken != null) {
      final refreshed =
          await _refreshAccessToken();

      if (refreshed) {
        // Retry original request with
        // newly generated access token.
        return await retryRequest();
      }

      // Refresh failed.
      await logoutLocal();

      throw Exception(
        'Your session has expired. Please login again.',
      );
    }

    // ----------------------------------------------------------
    // OTHER ERROR
    // ----------------------------------------------------------

    throw _extractError(response);
  }

  // ============================================================
  // REFRESH ACCESS TOKEN
  // ============================================================

  static Future<bool>
      _refreshAccessToken() async {
    // If another API request is already refreshing,
    // wait for that same operation.
    if (_refreshingToken != null) {
      return await _refreshingToken!;
    }

    _refreshingToken =
        _performTokenRefresh();

    try {
      return await _refreshingToken!;
    } finally {
      _refreshingToken = null;
    }
  }

  // ============================================================
  // PERFORM TOKEN REFRESH
  // ============================================================

  static Future<bool>
      _performTokenRefresh() async {
    try {
      if (refreshToken == null ||
          refreshToken!.isEmpty) {
        return false;
      }

      final response = await http.post(
        Uri.parse(
          '$baseUrl/auth/refresh',
        ),
        headers: {
          'Content-Type':
              'application/json',
        },
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      ).timeout(_requestTimeout);

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        return false;
      }

      final data =
          _decodeResponse(response);

      if (data['success'] != true) {
        return false;
      }

      final newAccessToken =
          data['accessToken'];

      final newRefreshToken =
          data['refreshToken'];

      if (newAccessToken == null ||
          newRefreshToken == null) {
        return false;
      }

      await updateAccessToken(
        accessToken:
            newAccessToken.toString(),
        refreshToken:
            newRefreshToken.toString(),
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
    final currentRefreshToken =
        refreshToken;

    // Clear local session first.
    // Even if server logout fails, the user
    // will still be logged out locally.
    await logoutLocal();

    // Revoke refresh token on backend.
    if (currentRefreshToken == null ||
        currentRefreshToken.isEmpty) {
      return;
    }

    try {
      await http.post(
        Uri.parse(
          '$baseUrl/auth/logout',
        ),
        headers: {
          'Content-Type':
              'application/json',
        },
        body: jsonEncode({
          'refreshToken':
              currentRefreshToken,
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

    await _storage.delete(
      key: _accessTokenKey,
    );

    await _storage.delete(
      key: _refreshTokenKey,
    );
  }

  // ============================================================
  // SAVE FCM TOKEN
  // ============================================================

  static Future<Map<String, dynamic>>
      saveFcmToken(
    String fcmToken,
  ) async {
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

  static Future<Map<String, dynamic>>
      uploadGarageProfileImage(
    String filePath,
  ) async {
    final request =
        http.MultipartRequest(
      'POST',
      Uri.parse(
        '$baseUrl/garage/profile/image',
      ),
    );

    if (token != null &&
        token!.isNotEmpty) {
      request.headers['Authorization'] =
          'Bearer $token';
    }

    final extension =
        filePath
            .split('.')
            .last
            .toLowerCase();

    MediaType contentType;

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        contentType =
            MediaType(
          'image',
          'jpeg',
        );
        break;

      case 'png':
        contentType =
            MediaType(
          'image',
          'png',
        );
        break;

      case 'webp':
        contentType =
            MediaType(
          'image',
          'webp',
        );
        break;

      default:
        throw Exception(
          'Only JPG, PNG and WEBP images are allowed',
        );
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'profileImage',
        filePath,
        contentType:
            contentType,
      ),
    );

    final streamedResponse =
        await request.send();

    final response =
        await http.Response.fromStream(
      streamedResponse,
    );

    // Multipart requests also need
    // automatic refresh support.
    if (response.statusCode == 401 &&
        token != null &&
        refreshToken != null) {
      final refreshed =
          await _refreshAccessToken();

      if (refreshed) {
        return await uploadGarageProfileImage(
          filePath,
        );
      }

      await logoutLocal();

      throw Exception(
        'Your session has expired. Please login again.',
      );
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return _decodeResponse(response);
    }

    throw _extractError(response);
  }

  static void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('GarageMate: $message');
    }
  }

  // ============================================================
  // RESPONSE DECODER
  // ============================================================

  static Map<String, dynamic>
      _decodeResponse(
    http.Response response,
  ) {
    try {
      final decoded =
          jsonDecode(response.body);

      if (decoded is Map) {
        return Map<String, dynamic>.from(
          decoded,
        );
      }

      return {};
    } catch (_) {
      throw Exception(
        'Server returned an invalid response.',
      );
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  static Exception _extractError(
    http.Response response,
  ) {
    try {
      final decoded =
          jsonDecode(response.body);

      if (decoded is Map &&
          decoded['message'] != null) {
        return Exception(
          decoded['message'].toString(),
        );
      }
    } catch (_) {}

    return Exception(
      'Something went wrong. Please try again.',
    );
  }
}