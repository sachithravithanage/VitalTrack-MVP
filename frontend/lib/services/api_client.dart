import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'firebase_service.dart';

/// API Client for connecting to VitalTrack backend
class ApiClient {
  late Dio _dio;

  // Backend URL configuration
  // For Android emulator, use 10.0.2.2 instead of localhost
  static String _getBaseUrl() {
    if (kDebugMode && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000'; // Android emulator special IP
    }
    return 'http://localhost:5000'; // iOS simulator, web, or real device on same network
  }

  static const String apiVersion = 'v1';

  Map<String, dynamic> _unwrapResponse(dynamic raw) {
    final map = Map<String, dynamic>.from(raw as Map);
    final normalized = <String, dynamic>{};

    if (map.containsKey('success')) {
      normalized['success'] = map['success'];
    }
    if (map.containsKey('message')) {
      normalized['message'] = map['message'];
    }
    if (map.containsKey('otp')) {
      normalized['otp'] = map['otp'];
    }

    final data = map['data'];
    if (data is Map) {
      normalized.addAll(Map<String, dynamic>.from(data));
      return normalized;
    }

    normalized.addAll(map);
    return normalized;
  }

  ApiClient() {
    final String baseUrl = _getBaseUrl();
    _dio = Dio(
      BaseOptions(
        baseUrl: '$baseUrl/api/$apiVersion',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        contentType: Headers.jsonContentType,
      ),
    );

    // Add auth interceptor
    _dio.interceptors.add(_AuthInterceptor());
  }

  // ============ Authentication ============

  /// Send OTP to phone or email
  Future<Map<String, dynamic>> sendOtp({
    required String credential,
    required String type, // 'phone' or 'email'
  }) async {
    try {
      final response = await _dio.post(
        '/auth/send-otp',
        data: {'credential': credential, 'type': type},
      );
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Verify OTP
  Future<Map<String, dynamic>> verifyOtp({
    required String credential,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/verify-otp',
        data: {'credential': credential, 'otp': otp},
      );
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Sign up
  Future<Map<String, dynamic>> signup({
    String? email,
    required String phone,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/signup',
        data: {
          'email': email,
          'phone': phone,
          'password': password,
          'name': name,
          'role': role,
        },
      );
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Login
  Future<Map<String, dynamic>> login({
    required String credential,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'credential': credential, 'password': password},
      );
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // ============ Users ============

  /// Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _dio.get('/users/profile');
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? email,
  }) async {
    try {
      final response = await _dio.put(
        '/users/profile',
        data: {'name': ?name, 'phone': ?phone, 'email': ?email},
      );
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Verify email (send OTP)
  Future<Map<String, dynamic>> verifyEmail() async {
    try {
      final response = await _dio.post('/users/verify-email');
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Confirm email verification
  Future<Map<String, dynamic>> confirmEmailVerification({
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        '/users/confirm-email-verification',
        data: {'otp': otp},
      );
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // ============ Medical Records ============

  /// Create medical record
  Future<Map<String, dynamic>> createRecord({
    required String disease,
    required String temperature,
    String? fluidIntake,
    String? urineOutput,
    String? urineColor,
    Map<String, bool>? symptoms,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        '/records',
        data: {
          'disease': disease,
          'temperature': temperature,
          'fluidIntake': ?fluidIntake,
          'urineOutput': ?urineOutput,
          'urineColor': ?urineColor,
          'symptoms': ?symptoms,
          'notes': ?notes,
        },
      );
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// List records
  Future<Map<String, dynamic>> listRecords({
    String? disease,
    String? timelineFilter,
    String? patientId,
  }) async {
    try {
      final response = await _dio.get(
        '/records',
        queryParameters: {
          'disease': ?disease,
          'timelineFilter': ?timelineFilter,
          'patientId': ?patientId,
        },
      );
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get record statistics
  Future<Map<String, dynamic>> getRecordStats({
    required String patientId,
    String? timelineFilter,
  }) async {
    try {
      final response = await _dio.get(
        '/records/stats/$patientId',
        queryParameters: {'timelineFilter': ?timelineFilter},
      );
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Export records as PDF
  Future<Map<String, dynamic>> exportRecordsPdf({
    String? timelineFilter,
  }) async {
    try {
      final response = await _dio.get(
        '/records/export/pdf',
        queryParameters: {'timelineFilter': ?timelineFilter},
      );
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // ============ Relationships ============

  /// Generate link code
  Future<Map<String, dynamic>> generateLinkCode() async {
    try {
      final response = await _dio.post('/relationships/link-code');
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Add patient using link code
  Future<Map<String, dynamic>> addPatient({
    required String code,
    String? disease,
  }) async {
    try {
      final response = await _dio.post(
        '/relationships/add-patient',
        data: {'code': code, 'disease': ?disease},
      );
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get list of patients (caregiver)
  Future<Map<String, dynamic>> getPatients() async {
    try {
      final response = await _dio.get('/relationships/patients');
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get list of caregivers (patient)
  Future<Map<String, dynamic>> getCaregivers() async {
    try {
      final response = await _dio.get('/relationships/caregivers');
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // ============ Notifications ============

  /// Register FCM token
  Future<Map<String, dynamic>> registerFCMToken({
    required String token,
    required String platform,
  }) async {
    try {
      final response = await _dio.post(
        '/notifications/register-token',
        data: {'token': token, 'platform': platform},
      );
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get notification history
  Future<Map<String, dynamic>> getNotificationHistory({int limit = 50}) async {
    try {
      final response = await _dio.get(
        '/notifications/history',
        queryParameters: {'limit': limit},
      );
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // ============ Hotspot ============

  /// Submit hotspot data
  Future<Map<String, dynamic>> submitHotspot({
    required String subject,
    required String hometown,
    required String workplace,
    String? places,
    String? disease,
    Map<String, double>? coordinates,
  }) async {
    try {
      final response = await _dio.post(
        '/hotspot/submit',
        data: {
          'subject': subject,
          'hometown': hometown,
          'workplace': workplace,
          'places': ?places,
          'disease': ?disease,
          'coordinates': ?coordinates,
        },
      );
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get patient hotspots
  Future<Map<String, dynamic>> getPatientHotspots({
    required String patientId,
  }) async {
    try {
      final response = await _dio.get('/hotspot/patient/$patientId');
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get heatmap data
  Future<Map<String, dynamic>> getHeatmapData({String? disease}) async {
    try {
      final response = await _dio.get(
        '/hotspot/heatmap/data',
        queryParameters: {'disease': ?disease},
      );
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }
}

/// Interceptor to add authentication token to requests
class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add Firebase ID token to authorization header
    final token = await firebaseAuthService.getIdToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle auth errors
    if (err.response?.statusCode == 401) {
      // Token expired or invalid - user should re-login
      await firebaseAuthService.signOut();
    }
    return handler.next(err);
  }
}

/// Singleton instance of API Client
final apiClient = ApiClient();
