import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class ApiResult<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResult({
    required this.success,
    required this.message,
    this.data,
  });
}

class ApiService {
  static String? _cachedBaseUrl;

  static List<String> get _candidateUrls {
    if (kIsWeb) return const ['http://localhost:8088/api/auth'];
    if (Platform.isAndroid) {
      return const [
        'http://127.0.0.1:8088/api/auth', // USB adb reverse / localhost
        'http://10.0.2.2:8088/api/auth',   // Android Emulator host alias
        'http://172.20.10.14:8088/api/auth', // Wi-Fi LAN IP
        'http://172.16.72.28:8088/api/auth', // Ethernet LAN IP
      ];
    }
    return const ['http://localhost:8088/api/auth'];
  }

  static String get baseUrl => _cachedBaseUrl ?? _candidateUrls.first;

  /// Automatically detect the working backend URL
  static Future<String> getWorkingBaseUrl() async {
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;
    for (final url in _candidateUrls) {
      try {
        final res = await http
            .get(Uri.parse('$url/health'))
            .timeout(const Duration(milliseconds: 1500));
        if (res.statusCode == 200) {
          _cachedBaseUrl = url;
          return url;
        }
      } catch (_) {
        // Try next candidate
      }
    }
    _cachedBaseUrl = _candidateUrls.first;
    return _cachedBaseUrl!;
  }

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  /// Send OTP to user's email via Spring Boot JavaMail SMTP
  static Future<ApiResult<void>> sendOtp(String email) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final url = Uri.parse('$activeUrl/send-otp');
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({'email': email.trim()}),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final message = body['message'] ?? 'Unable to send OTP';

      if (response.statusCode == 200 && (body['success'] == true)) {
        return ApiResult(success: true, message: message);
      } else {
        return ApiResult(success: false, message: message);
      }
    } catch (e) {
      return ApiResult(
        success: false,
        message: 'Network error or server unreachable. Please check backend connection.',
      );
    }
  }

  /// Verify OTP token entered by user
  static Future<ApiResult<void>> verifyOtp(String email, String otp) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final url = Uri.parse('$activeUrl/verify-otp');
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'email': email.trim(),
              'otp': otp.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final message = body['message'] ?? 'OTP verification failed';

      if (response.statusCode == 200 && (body['success'] == true)) {
        return ApiResult(success: true, message: message);
      } else {
        return ApiResult(success: false, message: message);
      }
    } catch (e) {
      return ApiResult(
        success: false,
        message: 'Network error during OTP verification: $e',
      );
    }
  }

  /// Register new Patient or Caretaker account into Oracle DB
  static Future<ApiResult<UserSession>> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final url = Uri.parse('$activeUrl/register');
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'email': email.trim(),
              'password': password,
              'name': name.trim(),
              'phone': phone.trim(),
              'role': role.toUpperCase(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final message = body['message'] ?? 'Registration failed';

      if (response.statusCode == 200 && (body['success'] == true)) {
        final session = UserSession.fromJson(body);
        return ApiResult(
          success: true,
          message: message,
          data: session,
        );
      } else {
        return ApiResult(success: false, message: message);
      }
    } catch (e) {
      return ApiResult(
        success: false,
        message: 'Connection failed during registration: $e',
      );
    }
  }

  /// Authenticate user credentials and return role-based profile session
  static Future<ApiResult<UserSession>> login({
    required String email,
    required String password,
  }) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final url = Uri.parse('$activeUrl/login');
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'email': email.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final message = body['message'] ?? 'Login failed';

      if (response.statusCode == 200 && (body['success'] == true)) {
        final session = UserSession.fromJson(body);
        return ApiResult(
          success: true,
          message: message,
          data: session,
        );
      } else {
        return ApiResult(success: false, message: message);
      }
    } catch (e) {
      return ApiResult(
        success: false,
        message: 'Connection failed during login: $e',
      );
    }
  }

  /// Link a patient to a caretaker via scanned QR token or ID
  static Future<ApiResult<LinkedPatient>> linkPatient({
    required String caretakerId,
    required String patientQrToken,
    String relation = "Primary Caregiver",
    bool isPrimary = false,
  }) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      // activeUrl is like http://.../api/auth -> replace with http://.../api
      final rootApiUrl = activeUrl.replaceAll('/auth', '');
      final url = Uri.parse('$rootApiUrl/caretaker/link-patient');

      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'caretakerId': caretakerId,
              'patientQrToken': patientQrToken.trim(),
              'relation': relation,
              'isPrimary': isPrimary,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final message = body['message'] ?? 'Unable to link patient';

      if (response.statusCode == 200 && (body['success'] == true)) {
        final patientData = body['data'] != null ? LinkedPatient.fromJson(body['data']) : null;
        return ApiResult(
          success: true,
          message: message,
          data: patientData,
        );
      } else {
        return ApiResult(success: false, message: message);
      }
    } catch (e) {
      return ApiResult(
        success: false,
        message: 'Failed to link patient: $e',
      );
    }
  }

  /// Fetch all patients linked to a caretaker
  static Future<List<LinkedPatient>> getCaretakerPatients(String caretakerId) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final rootApiUrl = activeUrl.replaceAll('/auth', '');
      final url = Uri.parse('$rootApiUrl/caretaker/$caretakerId/patients');

      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
        return list.map((item) => LinkedPatient.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Fetch all caretakers linked to a patient
  static Future<List<LinkedCaretaker>> getPatientCaretakers(String patientIdOrEmail) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final rootApiUrl = activeUrl.replaceAll('/auth', '');
      final url = Uri.parse('$rootApiUrl/patient/$patientIdOrEmail/caretakers');

      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
        return list.map((item) => LinkedCaretaker.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Trigger Emergency SOS broadcast to secondary caregivers and DB
  static Future<ApiResult<ActiveEmergencyAlert>> triggerSos({
    required String patientEmail,
    String? patientName,
    String? patientPhone,
    String? notes,
  }) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final rootApiUrl = activeUrl.replaceAll('/auth', '');
      final url = Uri.parse('$rootApiUrl/emergency/sos');

      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'patientEmail': patientEmail.trim(),
              'patientName': patientName ?? '',
              'patientPhone': patientPhone ?? '',
              'notes': notes ?? 'Emergency button pressed by patient',
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final message = body['message'] ?? 'Emergency SOS dispatched';

      if (response.statusCode == 200 && (body['success'] == true)) {
        final alertData = body['data'] != null ? ActiveEmergencyAlert.fromJson(body['data']) : null;
        return ApiResult(
          success: true,
          message: message,
          data: alertData,
        );
      } else {
        return ApiResult(success: false, message: message);
      }
    } catch (e) {
      return ApiResult(
        success: false,
        message: 'Failed to dispatch SOS alert: $e',
      );
    }
  }

  /// Get active emergency alerts for caretaker
  static Future<List<ActiveEmergencyAlert>> getActiveEmergencyAlerts(String caretakerIdOrEmail) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final rootApiUrl = activeUrl.replaceAll('/auth', '');
      final url = Uri.parse('$rootApiUrl/emergency/active/$caretakerIdOrEmail');

      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body['success'] == true && body['data'] is List) {
          final List<dynamic> list = body['data'];
          return list.map((item) => ActiveEmergencyAlert.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Mark emergency alert as resolved
  static Future<bool> resolveEmergencyAlert(int alertId) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final rootApiUrl = activeUrl.replaceAll('/auth', '');
      final url = Uri.parse('$rootApiUrl/emergency/resolve/$alertId');

      final response = await http.post(url, headers: _headers).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        return body['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Update user's FCM device token
  static Future<bool> updateFcmToken({required String email, required String fcmToken}) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final rootApiUrl = activeUrl.replaceAll('/auth', '');
      final url = Uri.parse('$rootApiUrl/user/fcm-token');

      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'email': email.trim(),
              'fcmToken': fcmToken.trim(),
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        return body['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

