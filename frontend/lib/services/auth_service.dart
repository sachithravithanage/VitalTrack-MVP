import 'dart:async';

import 'package:flutter/foundation.dart';
import 'firebase_service.dart';
import 'api_client.dart';
import 'storage_service.dart';

/// Authentication Service - coordinates Firebase Auth and backend API
class AuthService {
  final ApiClient _apiClient = apiClient;
  final FirebaseAuthService _firebaseAuth = firebaseAuthService;
  final StorageService _storage = storageService;
  bool _fcmRefreshListenerAttached = false;
  static const String _customAuthTokenKey = 'custom_auth_token';

  /// Send OTP for phone or email
  Future<Map<String, dynamic>> sendOtp({
    required String credential,
    required String type, // 'phone' or 'email'
  }) async {
    try {
      return await _apiClient.sendOtp(credential: credential, type: type);
    } catch (e) {
      debugPrint("Error sending OTP: $e");
      rethrow;
    }
  }

  /// Verify OTP
  Future<Map<String, dynamic>> verifyOtp({
    required String credential,
    required String otp,
  }) async {
    try {
      final response = await _apiClient.verifyOtp(
        credential: credential,
        otp: otp,
      );

      // Store user data locally
      if (response['user'] != null) {
        await _storage.saveCurrentUser(
          response['user'] as Map<String, dynamic>,
        );
      }

      return response;
    } catch (e) {
      debugPrint("Error verifying OTP: $e");
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<Map<String, dynamic>> signUp({
    String? email,
    required String phone,
    required String password,
    required String name,
    String role = 'patient', // 'patient' or 'caregiver'
  }) async {
    try {
      // Register with backend
      final response = await _apiClient.signup(
        email: email,
        phone: phone,
        password: password,
        name: name,
        role: role,
      );

      final customToken = response['customToken'] as String?;
      if (customToken != null && customToken.isNotEmpty) {
        await _firebaseAuth.signInWithCustomToken(customToken);
        await _storage.saveString(_customAuthTokenKey, customToken);
      }

      // Store user data locally
      if (response['user'] is Map<String, dynamic>) {
        await _storage.saveCurrentUser(
          response['user'] as Map<String, dynamic>,
        );
      }

      // Register FCM token without blocking auth completion
      unawaited(_registerFCMToken());

      return response;
    } catch (e) {
      debugPrint("Error signing up: $e");
      rethrow;
    }
  }

  /// Login with email and password
  Future<Map<String, dynamic>> login({
    required String credential, // email or phone
    required String password,
  }) async {
    try {
      // Call backend to validate credentials and obtain custom token.
      final response = await _apiClient.login(
        credential: credential,
        password: password,
      );

      final customToken = response['customToken'] as String?;
      if (customToken != null && customToken.isNotEmpty) {
        await _firebaseAuth.signInWithCustomToken(customToken);
        await _storage.saveString(_customAuthTokenKey, customToken);
      }

      // Store user data locally
      if (response['user'] is Map<String, dynamic>) {
        await _storage.saveCurrentUser(
          response['user'] as Map<String, dynamic>,
        );
      }

      // Register FCM token without blocking auth completion
      unawaited(_registerFCMToken());

      return response;
    } catch (e) {
      debugPrint("Error logging in: $e");
      rethrow;
    }
  }

  /// Send forgot-password OTP
  Future<Map<String, dynamic>> sendForgotPasswordOtp({
    required String credential,
    required String type,
  }) async {
    try {
      return await _apiClient.sendForgotPasswordOtp(
        credential: credential,
        type: type,
      );
    } catch (e) {
      debugPrint("Error sending forgot-password OTP: $e");
      rethrow;
    }
  }

  /// Reset password using OTP
  Future<Map<String, dynamic>> resetPassword({
    required String credential,
    required String otp,
    required String newPassword,
  }) async {
    try {
      return await _apiClient.resetPassword(
        credential: credential,
        otp: otp,
        newPassword: newPassword,
      );
    } catch (e) {
      debugPrint("Error resetting password: $e");
      rethrow;
    }
  }

  /// Send OTP for step-up verification (authenticated)
  Future<void> sendStepUpOtp({
    required String purpose,
    String channel = 'phone',
  }) async {
    try {
      await _apiClient.sendStepUpOtp(purpose: purpose, channel: channel);
    } catch (e) {
      debugPrint("Error sending step-up OTP: $e");
      rethrow;
    }
  }

  /// Verify step-up OTP and return one-time action token
  Future<String> verifyStepUpOtp({
    required String purpose,
    required String otp,
    String channel = 'phone',
  }) async {
    try {
      final response = await _apiClient.verifyStepUpOtp(
        purpose: purpose,
        otp: otp,
        channel: channel,
      );
      return response['stepUpToken'] as String? ?? '';
    } catch (e) {
      debugPrint("Error verifying step-up OTP: $e");
      rethrow;
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _apiClient.getUserProfile();

      // Update local storage
      final user = response['profile'] ?? response['user'];
      if (user is Map<String, dynamic>) {
        await _storage.saveCurrentUser(user);
      }

      return response;
    } catch (e) {
      debugPrint("Error getting user profile: $e");
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
      final response = await _apiClient.updateProfile(
        name: name,
        phone: phone,
        email: email,
      );

      // Update local storage
      final user = response['profile'] ?? response['user'];
      if (user is Map<String, dynamic>) {
        await _storage.saveCurrentUser(user);
      }

      return response;
    } catch (e) {
      debugPrint("Error updating profile: $e");
      rethrow;
    }
  }

  /// Enable caregiver role for current user
  Future<Map<String, dynamic>> enableCaregiverRole() async {
    try {
      final response = await _apiClient.enableCaregiverRole();
      final user = response['profile'] ?? response['user'];
      if (user is Map<String, dynamic>) {
        await _storage.saveCurrentUser(user);
      }
      return response;
    } catch (e) {
      debugPrint("Error enabling caregiver role: $e");
      rethrow;
    }
  }

  /// Switch active role for current user
  Future<Map<String, dynamic>> switchActiveRole({required String role}) async {
    try {
      final response = await _apiClient.switchActiveRole(role: role);
      final user = response['profile'] ?? response['user'];
      if (user is Map<String, dynamic>) {
        await _storage.saveCurrentUser(user);
      }
      return response;
    } catch (e) {
      debugPrint("Error switching active role: $e");
      rethrow;
    }
  }

  /// Request email verification OTP for the currently stored profile email
  Future<Map<String, dynamic>> verifyEmail() async {
    try {
      return await _apiClient.verifyEmail();
    } catch (e) {
      debugPrint("Error requesting email verification: $e");
      rethrow;
    }
  }

  /// Confirm email verification OTP
  Future<Map<String, dynamic>> confirmEmailVerification({
    required String otp,
  }) async {
    try {
      final response = await _apiClient.confirmEmailVerification(otp: otp);

      final currentUser = _storage.getCurrentUser();
      if (currentUser != null) {
        currentUser['emailVerified'] = true;
        await _storage.saveCurrentUser(currentUser);
      }

      return response;
    } catch (e) {
      debugPrint("Error confirming email verification: $e");
      rethrow;
    }
  }

  /// Get current user from local storage
  Map<String, dynamic>? getCurrentUser() {
    return _storage.getCurrentUser();
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _storage.getCurrentUser()?['id'] as String?;
  }

  /// Get current user role
  String? getCurrentUserRole() {
    final user = _storage.getCurrentUser();
    return (user?['activeRole'] ?? user?['role']) as String?;
  }

  /// Log out
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      await _storage.clearCurrentUser();
      await _storage.clearFCMToken();
      await _storage.remove(_customAuthTokenKey);
    } catch (e) {
      debugPrint("Error logging out: $e");
      rethrow;
    }
  }

  /// Register FCM token with backend
  Future<void> _registerFCMToken() async {
    try {
      final fcmToken = await _firebaseAuth.getFCMToken().timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );
      if (fcmToken != null) {
        await _apiClient.registerFCMToken(token: fcmToken, platform: 'flutter');
        await _storage.saveFCMToken(fcmToken);

        // Listen to token refresh
        if (!_fcmRefreshListenerAttached) {
          _firebaseAuth.listenToFCMTokenChanges((newToken) {
            _onFCMTokenRefresh(newToken);
          });
          _fcmRefreshListenerAttached = true;
        }
      }
    } catch (e) {
      debugPrint("Error registering FCM token: $e");
    }
  }

  /// Handle FCM token refresh
  Future<void> _onFCMTokenRefresh(String newToken) async {
    try {
      await _apiClient.registerFCMToken(token: newToken, platform: 'flutter');
      await _storage.saveFCMToken(newToken);
    } catch (e) {
      debugPrint("Error updating FCM token: $e");
    }
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return getCurrentUser() != null && _firebaseAuth.isAuthenticated();
  }
}

/// Singleton instance of Auth Service
final authService = AuthService();
