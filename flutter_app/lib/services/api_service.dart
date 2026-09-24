import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/social_models.dart';
import '../models/reminder_model.dart';

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
        'http://10.255.27.145:8088/api/auth', // Current Wi-Fi LAN IP (this PC)
        'http://10.191.241.233:8088/api/auth', // Wi-Fi LAN IP (this PC)
        'http://192.168.56.1:8088/api/auth', // Ethernet/VirtualBox host
        'http://10.0.2.2:8088/api/auth',   // Android Emulator host alias
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

  /// Send Email OTP to user's email address (with statutory license pre-check for Healthcare Workers)
  static Future<ApiResult<String>> sendEmailOtp({
    required String email,
    String? phone,
    String? role,
    String? registrationNumber,
    String? stateCouncil,
    String? name,
  }) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final url = Uri.parse('$activeUrl/send-otp');
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'email': email.trim(),
              'phone': phone?.trim(),
              'role': role,
              'registrationNumber': registrationNumber?.trim(),
              'stateCouncil': stateCouncil?.trim(),
              'name': name?.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final message = body['message'] ?? 'Unable to send OTP';
      final String? otpCode = body['data']?.toString();

      if (response.statusCode == 200 && (body['success'] == true)) {
        return ApiResult(success: true, message: message, data: otpCode);
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

  /// Backward compatible sendPhoneOtp
  static Future<ApiResult<String>> sendPhoneOtp({
    required String phone,
    String? email,
    String? role,
    String? registrationNumber,
    String? stateCouncil,
    String? name,
  }) => sendEmailOtp(
        email: email ?? phone,
        phone: phone,
        role: role,
        registrationNumber: registrationNumber,
        stateCouncil: stateCouncil,
        name: name,
      );

  /// Backward compatible sendOtp
  static Future<ApiResult<String>> sendOtp(String email) => sendEmailOtp(email: email);

  /// Talk to the AI companion (Spring Boot forwards to the FastAPI chat backend)
  static Future<String?> aiChat({
    required String userText,
    required String language,
    String patientName = '',
  }) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final rootApiUrl = activeUrl.replaceAll('/api/auth', '');
      final url = Uri.parse('$rootApiUrl/api/ai/chat');
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'messages': [
                {'role': 'user', 'content': userText},
              ],
              'language': language == 'bn' ? 'bn' : 'en',
              'patient_name': patientName,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final reply = body['reply'];
      return reply is String && reply.trim().isNotEmpty ? reply : null;
    } catch (_) {
      return null;
    }
  }

  /// Verify 6-digit Email OTP token entered by user
  static Future<ApiResult<void>> verifyEmailOtp({required String email, required String otp}) async {
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

  /// Backward compatible verifyPhoneOtp
  static Future<ApiResult<void>> verifyPhoneOtp({required String phone, required String otp}) =>
      verifyEmailOtp(email: phone, otp: otp);

  /// Backward compatible verifyOtp
  static Future<ApiResult<void>> verifyOtp(String email, String otp) => verifyEmailOtp(email: email, otp: otp);

  /// Extended register with demographic, location, date of birth, and healthcare credentials
  static Future<ApiResult<UserSession>> register({
    required String email,
    required String password,
    required String name,
    String? phone,
    required String role,
    String? dateOfBirth,
    int? age,
    String? gender,
    String? state,
    String? district,
    String? pincode,
    String? profession,
    String? specialization,
    String? hospitalName,
    String? stateCouncil,
    String? registrationNumber,
    String? nuid,
    String? idProofUrl,
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
              'phone': phone?.trim() ?? '',
              'role': role.toUpperCase(),
              'dateOfBirth': dateOfBirth,
              'age': age,
              'gender': gender,
              'state': state,
              'district': district,
              'pincode': pincode,
              'profession': profession,
              'specialization': specialization,
              'hospitalName': hospitalName,
              'stateCouncil': stateCouncil,
              'registrationNumber': registrationNumber,
              'nuid': nuid,
              'idProofUrl': idProofUrl,
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

  /// Authenticate user credentials via Phone Number OR Email
  static Future<ApiResult<UserSession>> login({
    required String email, // can be phone number or email
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
              'identifier': email.trim(),
              'email': email.trim(),
              'phone': email.trim(),
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

  /// Fetch verified healthcare workers filtered by region
  static Future<List<HealthcareWorkerModel>> getNearbyHealthcareWorkers({String? state, String? district}) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final rootApiUrl = activeUrl.replaceAll('/auth', '');
      final uri = Uri.parse('$rootApiUrl/healthcare/nearby').replace(queryParameters: {
        if (state != null && state.isNotEmpty) 'state': state,
        if (district != null && district.isNotEmpty) 'district': district,
      });

      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body['success'] == true && body['data'] is List) {
          return (body['data'] as List).map((x) => HealthcareWorkerModel.fromJson(x)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Request assignment between patient and healthcare worker
  static Future<ApiResult<void>> requestHealthcareAssignment({
    required String patientId,
    required String workerId,
    required String requestedBy,
    String? notes,
  }) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final rootApiUrl = activeUrl.replaceAll('/auth', '');
      final url = Uri.parse('$rootApiUrl/healthcare/request-assignment');

      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'patientId': patientId,
              'workerId': workerId,
              'requestedBy': requestedBy,
              'notes': notes ?? '',
            }),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return ApiResult(
        success: body['success'] == true,
        message: body['message'] ?? 'Request submitted',
      );
    } catch (e) {
      return ApiResult(success: false, message: 'Failed to request care assignment: $e');
    }
  }

  /// Doctor/Nurse accepts or rejects patient assignment request
  static Future<ApiResult<void>> respondHealthcareAssignment({
    required int assignmentId,
    required String action, // "ACCEPT" or "REJECT"
  }) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final rootApiUrl = activeUrl.replaceAll('/auth', '');
      final url = Uri.parse('$rootApiUrl/healthcare/respond-assignment');

      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'assignmentId': assignmentId,
              'action': action,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return ApiResult(
        success: body['success'] == true,
        message: body['message'] ?? 'Status updated',
      );
    } catch (e) {
      return ApiResult(success: false, message: 'Failed to respond: $e');
    }
  }

  /// Doctor/Nurse gets assigned patients list
  static Future<List<AssignedPatientModel>> getAssignedPatients(String workerId) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final rootApiUrl = activeUrl.replaceAll('/auth', '');
      final url = Uri.parse('$rootApiUrl/healthcare/assigned-patients?workerId=$workerId');

      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body['success'] == true && body['data'] is List) {
          return (body['data'] as List).map((x) => AssignedPatientModel.fromJson(x)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Admin gets list of pending healthcare workers
  static Future<List<AdminPendingWorkerModel>> getPendingWorkers() async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final rootApiUrl = activeUrl.replaceAll('/auth', '');
      final url = Uri.parse('$rootApiUrl/admin/pending-workers');

      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body['success'] == true && body['data'] is List) {
          return (body['data'] as List).map((x) => AdminPendingWorkerModel.fromJson(x)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Admin approves or rejects worker registration
  static Future<ApiResult<void>> verifyWorker({
    required String userId,
    required String status, // "APPROVED" or "REJECTED"
    String? reason,
  }) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final rootApiUrl = activeUrl.replaceAll('/auth', '');
      final url = Uri.parse('$rootApiUrl/admin/verify-worker');

      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'userId': userId,
              'status': status,
              'reason': reason ?? '',
            }),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return ApiResult(
        success: body['success'] == true,
        message: body['message'] ?? 'Verification updated',
      );
    } catch (e) {
      return ApiResult(success: false, message: 'Failed to update verification: $e');
    }
  }

  /// Admin stats
  static Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final rootApiUrl = activeUrl.replaceAll('/auth', '');
      final url = Uri.parse('$rootApiUrl/admin/stats');

      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body['success'] == true && body['data'] is Map<String, dynamic>) {
          return body['data'];
        }
      }
      return {};
    } catch (e) {
      return {};
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

  // ------------------------------------------------------------------
  // Social Interaction (friend requests, caregiver approval, chat)
  // ------------------------------------------------------------------

  /// Root API host (e.g. http://10.0.2.2:8088/api) without /auth suffix
  static String get _rootApiUrl => baseUrl.replaceAll('/auth', '');

  /// Host origin (e.g. http://10.0.2.2:8088) used to resolve media URLs
  static String get mediaBaseUrl {
    final current = _rootApiUrl;
    final idx = current.indexOf('/api');
    return idx > 0 ? current.substring(0, idx) : current;
  }

  /// Fetch all non-rejected connections for a patient
  static Future<List<SocialConnection>> getSocialConnections(String patientId) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final rootApiUrl = activeUrl.replaceAll('/auth', '');
      final url = Uri.parse('$rootApiUrl/social/patient/$patientId/connections');
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
        return list.map((item) => SocialConnection.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Fetch patients that can still receive a connection request
  static Future<List<DiscoverablePatient>> getDiscoverablePatients(String patientId) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final rootApiUrl = activeUrl.replaceAll('/auth', '');
      final url = Uri.parse('$rootApiUrl/social/patient/$patientId/discover');
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
        return list.map((item) => DiscoverablePatient.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Patient A sends a social connection request to Patient B
  static Future<ApiResult<SocialConnection>> sendConnectionRequest({
    required String requesterPatientId,
    required String receiverPatientId,
    String? requestMessage,
  }) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final rootApiUrl = activeUrl.replaceAll('/auth', '');
      final url = Uri.parse('$rootApiUrl/social/request?requesterPatientId=$requesterPatientId');
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'receiverPatientId': receiverPatientId.trim(),
              'requestMessage': requestMessage ?? '',
            }),
          )
          .timeout(const Duration(seconds: 15));
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final message = body['message'] ?? 'Unable to send request';
      if (response.statusCode == 200 && (body['success'] == true)) {
        final data = body['data'] != null ? SocialConnection.fromJson(body['data']) : null;
        return ApiResult(success: true, message: message, data: data);
      }
      return ApiResult(success: false, message: message);
    } catch (e) {
      return ApiResult(success: false, message: 'Failed to send request: $e');
    }
  }

  /// Receiver patient accepts or rejects an incoming request
  static Future<ApiResult<SocialConnection>> respondToConnection({
    required int connectionId,
    required String patientId,
    required bool accept,
  }) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final rootApiUrl = activeUrl.replaceAll('/auth', '');
      final url = Uri.parse(
          '$rootApiUrl/social/$connectionId/respond?patientId=$patientId&accept=$accept');
      final response = await http.post(url, headers: _headers).timeout(const Duration(seconds: 15));
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final message = body['message'] ?? 'Unable to process request';
      if (response.statusCode == 200 && (body['success'] == true)) {
        final data = body['data'] != null ? SocialConnection.fromJson(body['data']) : null;
        return ApiResult(success: true, message: message, data: data);
      }
      return ApiResult(success: false, message: message);
    } catch (e) {
      return ApiResult(success: false, message: 'Failed to respond: $e');
    }
  }

  /// Fetch connections awaiting caregiver approval for the caregiver's patients
  static Future<List<SocialConnection>> getPendingCaretakerApprovals(String caretakerId) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final rootApiUrl = activeUrl.replaceAll('/auth', '');
      final url = Uri.parse('$rootApiUrl/social/caretaker/$caretakerId/pending-approvals');
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
        return list.map((item) => SocialConnection.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Fetch connected conversations for a caregiver's linked patients
  static Future<List<SocialConnection>> getConnectedForCaretaker(String caretakerId) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final rootApiUrl = activeUrl.replaceAll('/auth', '');
      final url = Uri.parse('$rootApiUrl/social/caretaker/$caretakerId/connections');
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
        return list.map((item) => SocialConnection.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Caregiver approves or rejects a social connection request
  static Future<ApiResult<SocialConnection>> caretakerDecision({
    required int connectionId,
    required String caretakerId,
    required bool approve,
  }) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final rootApiUrl = activeUrl.replaceAll('/auth', '');
      final url = Uri.parse(
          '$rootApiUrl/social/$connectionId/caretaker-decision?caretakerId=$caretakerId&approve=$approve');
      final response = await http.post(url, headers: _headers).timeout(const Duration(seconds: 15));
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final message = body['message'] ?? 'Unable to process request';
      if (response.statusCode == 200 && (body['success'] == true)) {
        final data = body['data'] != null ? SocialConnection.fromJson(body['data']) : null;
        return ApiResult(success: true, message: message, data: data);
      }
      return ApiResult(success: false, message: message);
    } catch (e) {
      return ApiResult(success: false, message: 'Failed to approve: $e');
    }
  }

  /// Send a social chat message (TEXT / VOICE / PHOTO)
  static Future<ApiResult<SocialMessage>> sendSocialMessage({
    required String senderId,
    required int connectionId,
    required String type,
    String? content,
    String? mediaUrl,
    int? durationMs,
  }) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final rootApiUrl = activeUrl.replaceAll('/auth', '');
      final url = Uri.parse('$rootApiUrl/social/message?senderId=$senderId');
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'connectionId': connectionId,
              'type': type,
              'content': content ?? '',
              'mediaUrl': mediaUrl ?? '',
              'durationMs': durationMs ?? 0,
            }),
          )
          .timeout(const Duration(seconds: 15));
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final message = body['message'] ?? 'Unable to send message';
      if (response.statusCode == 200 && (body['success'] == true)) {
        final data = body['data'] != null ? SocialMessage.fromJson(body['data']) : null;
        return ApiResult(success: true, message: message, data: data);
      }
      return ApiResult(success: false, message: message);
    } catch (e) {
      return ApiResult(success: false, message: 'Failed to send message: $e');
    }
  }

  /// Fetch the message history for a connection (participants only)
  static Future<List<SocialMessage>> getSocialMessages(int connectionId, String userId) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final rootApiUrl = activeUrl.replaceAll('/auth', '');
      final url = Uri.parse('$rootApiUrl/social/$connectionId/messages?userId=$userId');
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
        return list.map((item) => SocialMessage.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Upload image / voice file and return the media URL
  static Future<ApiResult<String>> uploadSocialMedia(String filePath) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final rootApiUrl = activeUrl.replaceAll('/auth', '');
      final url = Uri.parse('$rootApiUrl/social/upload');
      final file = File(filePath);
      final request = http.MultipartRequest('POST', url)
        ..files.add(await http.MultipartFile.fromPath('file', file.path));
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final message = body['message'] ?? 'Upload failed';
      if (response.statusCode == 200 && (body['success'] == true)) {
        final mediaUrl = body['data'] is String ? body['data'] : '';
        return ApiResult(success: true, message: message, data: mediaUrl);
      }
      return ApiResult(success: false, message: message);
    } catch (e) {
      return ApiResult(success: false, message: 'Failed to upload media: $e');
    }
  }

  /// Delete a social chat message (participants only)
  static Future<ApiResult<void>> deleteSocialMessage({
    required int messageId,
    required int connectionId,
    required String userId,
  }) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final rootApiUrl = activeUrl.replaceAll('/auth', '');
      final url = Uri.parse(
          '$rootApiUrl/social/message/$messageId?connectionId=$connectionId&userId=$userId');
      final response = await http
          .delete(url, headers: _headers)
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final message = body['message'] ?? 'Unable to delete message';
      if (response.statusCode == 200 && (body['success'] == true)) {
        return ApiResult(success: true, message: message);
      }
      return ApiResult(success: false, message: message);
    } catch (e) {
      return ApiResult(success: false, message: 'Failed to delete message: $e');
    }
  }

  /// Fetch all active configured reminders for a patient
  static Future<ApiResult<List<PatientReminder>>> getPatientReminders(String patientId) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final rootApiUrl = activeUrl.replaceAll('/auth', '');
      final url = Uri.parse('$rootApiUrl/reminders/patient/$patientId');
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 10));

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final message = body['message'] ?? 'Fetched reminders';

      if (response.statusCode == 200 && (body['success'] == true)) {
        final List list = body['data'] ?? [];
        final reminders = list.map((item) => PatientReminder.fromJson(item)).toList();
        return ApiResult(success: true, message: message, data: reminders);
      }
      return ApiResult(success: false, message: message, data: []);
    } catch (e) {
      return ApiResult(success: false, message: 'Failed to fetch reminders: $e', data: []);
    }
  }

  /// Create a new reminder / alarm
  static Future<ApiResult<PatientReminder>> createReminder({
    required String patientId,
    String? createdBy,
    required String title,
    required String category,
    required String reminderTime,
    String daysOfWeek = 'DAILY',
    String? voiceMessage,
    String voiceLanguage = 'en',
  }) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final rootApiUrl = activeUrl.replaceAll('/auth', '');
      final url = Uri.parse('$rootApiUrl/reminders');
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'patientId': patientId,
              'createdBy': createdBy,
              'title': title,
              'category': category,
              'reminderTime': reminderTime,
              'daysOfWeek': daysOfWeek,
              'voiceMessage': voiceMessage,
              'voiceLanguage': voiceLanguage,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final message = body['message'] ?? 'Reminder saved';

      if (response.statusCode == 200 && (body['success'] == true) && body['data'] != null) {
        final reminder = PatientReminder.fromJson(body['data']);
        return ApiResult(success: true, message: message, data: reminder);
      }
      return ApiResult(success: false, message: message);
    } catch (e) {
      return ApiResult(success: false, message: 'Failed to create reminder: $e');
    }
  }

  /// Update reminder status (e.g. TAKEN, SNOOZED, MISSED) or toggle active
  static Future<ApiResult<PatientReminder>> updateReminderStatus({
    required String reminderId,
    String? status,
    bool? active,
  }) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final rootApiUrl = activeUrl.replaceAll('/auth', '');
      var query = <String>[];
      if (status != null) query.add('status=$status');
      if (active != null) query.add('active=$active');
      final qStr = query.isNotEmpty ? '?${query.join('&')}' : '';
      final url = Uri.parse('$rootApiUrl/reminders/$reminderId/status$qStr');

      final response = await http.put(url, headers: _headers).timeout(const Duration(seconds: 10));
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final message = body['message'] ?? 'Status updated';

      if (response.statusCode == 200 && (body['success'] == true) && body['data'] != null) {
        final reminder = PatientReminder.fromJson(body['data']);
        return ApiResult(success: true, message: message, data: reminder);
      }
      return ApiResult(success: false, message: message);
    } catch (e) {
      return ApiResult(success: false, message: 'Failed to update reminder: $e');
    }
  }

  /// Delete a reminder
  static Future<ApiResult<void>> deleteReminder(String reminderId) async {
    try {
      final activeUrl = await getWorkingBaseUrl();
      final rootApiUrl = activeUrl.replaceAll('/auth', '');
      final url = Uri.parse('$rootApiUrl/reminders/$reminderId');

      final response = await http.delete(url, headers: _headers).timeout(const Duration(seconds: 10));
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final message = body['message'] ?? 'Reminder deleted';

      if (response.statusCode == 200 && (body['success'] == true)) {
        return ApiResult(success: true, message: message);
      }
      return ApiResult(success: false, message: message);
    } catch (e) {
      return ApiResult(success: false, message: 'Failed to delete reminder: $e');
    }
  }
}
