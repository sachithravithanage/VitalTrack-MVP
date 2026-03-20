import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'firebase_service.dart';
import 'storage_service.dart';

const String _customAuthTokenKey = 'custom_auth_token';

/// API Client for connecting to VitalTrack backend
class ApiClient {
  late Dio _dio;

  // Backend URL configuration
  // Priority:
  // 1) --dart-define=API_BASE_URL (recommended)
  // 2) Web: same host as current page, configurable port via API_PORT
  // 3) Android emulator debug: 10.0.2.2
  // 4) Fallback localhost
  static String _getBaseUrl() {
    const String fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.trim().isNotEmpty) {
      return fromDefine.trim();
    }

    if (kIsWeb) {
      const String apiPortRaw = String.fromEnvironment(
        'API_PORT',
        defaultValue: '5000',
      );
      final int apiPort = int.tryParse(apiPortRaw) ?? 5000;

      final Uri page = Uri.base;
      final String scheme = page.scheme == 'https' ? 'https' : 'http';
      final String host = page.host.isEmpty ? 'localhost' : page.host;
      return '$scheme://$host:$apiPort';
    }

    if (kDebugMode && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000'; // Android emulator special IP
    }

    return 'http://localhost:5000';
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
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        contentType: Headers.jsonContentType,
      ),
    );

    // Add auth interceptor
    _dio.interceptors.add(_AuthInterceptor(_dio));
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
    String role = 'patient',
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

  /// Send forgot-password OTP
  Future<Map<String, dynamic>> sendForgotPasswordOtp({
    required String credential,
    required String type,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password/send-otp',
        data: {'credential': credential, 'type': type},
      );
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Reset password with OTP
  Future<Map<String, dynamic>> resetPassword({
    required String credential,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password/reset',
        data: {
          'credential': credential,
          'otp': otp,
          'newPassword': newPassword,
        },
      );
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Send OTP for step-up verification (authenticated)
  Future<Map<String, dynamic>> sendStepUpOtp({
    required String purpose,
    String channel = 'phone',
  }) async {
    try {
      final response = await _dio.post(
        '/auth/step-up/send-otp',
        data: {'purpose': purpose, 'channel': channel},
      );
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Verify OTP for step-up and obtain one-time token
  Future<Map<String, dynamic>> verifyStepUpOtp({
    required String purpose,
    required String otp,
    String channel = 'phone',
  }) async {
    try {
      final response = await _dio.post(
        '/auth/step-up/verify',
        data: {'purpose': purpose, 'otp': otp, 'channel': channel},
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
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (phone != null) data['phone'] = phone;
      if (email != null) data['email'] = email;
      final response = await _dio.put('/users/profile', data: data);
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Enable caregiver role for current user
  Future<Map<String, dynamic>> enableCaregiverRole() async {
    try {
      final response = await _dio.post('/users/roles/caregiver');
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Switch active role for current user
  Future<Map<String, dynamic>> switchActiveRole({required String role}) async {
    try {
      final response = await _dio.put(
        '/users/active-role',
        data: {'role': role},
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

  /// Get the OTP that was sent for email verification
  /// This is only available in development mode
  /// Call this after verifyEmail() to get the OTP for testing
  Future<Map<String, dynamic>> getLastEmailVerificationOtp() async {
    // In development mode, the OTP is returned when verifyEmail is called
    // This is a helper method for testing - in production, OTPs are sent via email
    // For now, return empty - the OTP should be logged in backend console
    return {'otp': 'Check backend console for OTP'};
  }
  // ============ Medical Records ============

  /// Create medical record
  Future<Map<String, dynamic>> createRecord({
    String? patientId,
    required String disease,
    String? temperature,
    String? fluidIntake,
    String? urineOutput,
    String? urineColor,
    Map<String, String>? values,
    Map<String, bool>? symptoms,
    String? notes,
  }) async {
    try {
      final Map<String, dynamic> data = <String, dynamic>{
        'patientId': patientId,
        'disease': disease,
      };
      if (temperature != null) data['temperature'] = temperature;
      if (fluidIntake != null) data['fluidIntake'] = fluidIntake;
      if (urineOutput != null) data['urineOutput'] = urineOutput;
      if (urineColor != null) data['urineColor'] = urineColor;
      if (values != null) data['values'] = values;
      if (symptoms != null) data['symptoms'] = symptoms;
      if (notes != null) data['notes'] = notes;
      final response = await _dio.post('/records', data: data);
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
      final Map<String, dynamic> query = <String, dynamic>{};
      if (disease != null) query['disease'] = disease;
      if (timelineFilter != null) query['timelineFilter'] = timelineFilter;
      if (patientId != null) query['patientId'] = patientId;
      final response = await _dio.get('/records', queryParameters: query);
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
      final Map<String, dynamic> query = <String, dynamic>{};
      if (timelineFilter != null) query['timelineFilter'] = timelineFilter;
      final response = await _dio.get(
        '/records/stats/$patientId',
        queryParameters: query,
      );
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Export records as PDF
  Future<Map<String, dynamic>> exportRecordsPdf({
    String? timelineFilter,
    String? patientId,
    String? stepUpToken,
  }) async {
    try {
      final Map<String, dynamic> query = <String, dynamic>{};
      if (timelineFilter != null) query['timelineFilter'] = timelineFilter;
      if (patientId != null) query['patientId'] = patientId;
      final response = await _dio.get(
        '/records/export/pdf',
        queryParameters: query,
        options: stepUpToken == null
            ? null
            : Options(headers: {'x-step-up-token': stepUpToken}),
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

  /// Generate link code with step-up token
  Future<Map<String, dynamic>> generateLinkCodeSecured({
    required String stepUpToken,
  }) async {
    try {
      final response = await _dio.post(
        '/relationships/link-code',
        options: Options(headers: {'x-step-up-token': stepUpToken}),
      );
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Add patient using link code
  Future<Map<String, dynamic>> addPatient({
    required String code,
    String? disease,
    String? stepUpToken,
  }) async {
    try {
      final data = {'code': code};
      if (disease != null) data['disease'] = disease;
      final response = await _dio.post(
        '/relationships/add-patient',
        data: data,
        options: stepUpToken == null
            ? null
            : Options(headers: {'x-step-up-token': stepUpToken}),
      );
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Create and link a new managed patient
  Future<Map<String, dynamic>> createPatient({
    required String name,
    required String disease,
    String? stepUpToken,
  }) async {
    try {
      final response = await _dio.post(
        '/relationships/create-patient',
        data: {'name': name, 'disease': disease},
        options: stepUpToken == null
            ? null
            : Options(headers: {'x-step-up-token': stepUpToken}),
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

  /// Mark a notification as read
  Future<Map<String, dynamic>> markNotificationAsRead({
    required String notificationId,
  }) async {
    try {
      final response = await _dio.put('/notifications/$notificationId/read');
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // ============ Hotspot ============

  /// Submit hotspot data
  Future<Map<String, dynamic>> submitHotspot({
    required String subject,
    String? subjectPatientId,
    required String hometown,
    required String workplace,
    String? places,
    String? disease,
    Map<String, double>? coordinates,
  }) async {
    try {
      final data = <String, dynamic>{
        'subject': subject,
        'hometown': hometown,
        'workplace': workplace,
      };
      if (subjectPatientId != null) data['subjectPatientId'] = subjectPatientId;
      if (places != null) data['places'] = places;
      if (disease != null) data['disease'] = disease;
      if (coordinates != null) data['coordinates'] = coordinates;
      final response = await _dio.post('/hotspot/submit', data: data);
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
      final params = <String, dynamic>{};
      if (disease != null) params['disease'] = disease;
      final response = await _dio.get(
        '/hotspot/heatmap/data',
        queryParameters: params,
      );
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get district-level regional hotspot summary
  Future<Map<String, dynamic>> getRegionalHeatmapData({String? disease}) async {
    try {
      final params = <String, dynamic>{};
      if (disease != null) params['disease'] = disease;
      final response = await _dio.get(
        '/hotspot/heatmap/regions',
        queryParameters: params,
      );
      return _unwrapResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }
}

/// Interceptor to add authentication token to requests
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio);

  final Dio _dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final currentUser = storageService.getCurrentUser();
    final currentUserId =
        (currentUser?['id'] ??
                currentUser?['uid'] ??
                firebaseAuthService.currentUserId)
            ?.toString();

    if (currentUserId != null && currentUserId.isNotEmpty) {
      options.headers['x-user-id'] = currentUserId;
    }

    // Add Firebase ID token to authorization header
    String? token = await firebaseAuthService.getIdToken();

    if (token == null || token.isEmpty) {
      final fallbackCustomToken = storageService.getString(_customAuthTokenKey);
      if (fallbackCustomToken != null && fallbackCustomToken.isNotEmpty) {
        try {
          await firebaseAuthService.signInWithCustomToken(fallbackCustomToken);
          token = await firebaseAuthService.getIdToken(forceRefresh: true);
        } catch (_) {
          // Continue without authorization header; request may return 401.
        }
      }
    }

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    } else {
      options.headers.remove('Authorization');
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 &&
        err.requestOptions.extra['retriedAfterRefresh'] != true) {
      final refreshedToken = await firebaseAuthService.getIdToken(
        forceRefresh: true,
      );

      if (refreshedToken != null && refreshedToken.isNotEmpty) {
        final requestOptions = err.requestOptions;
        requestOptions.headers['Authorization'] = 'Bearer $refreshedToken';
        requestOptions.extra['retriedAfterRefresh'] = true;

        try {
          final response = await _dio.fetch<dynamic>(requestOptions);
          return handler.resolve(response);
        } catch (_) {
          // If retry fails, propagate original error.
        }
      }
    }

    return handler.next(err);
  }
}

/// Singleton instance of API Client
final apiClient = ApiClient();
