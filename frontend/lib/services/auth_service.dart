import 'dart:async';

import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'storage_service.dart';

/// Authentication Service - coordinates app auth and backend API
class AuthService {
  final ApiClient _apiClient = apiClient;
  final StorageService _storage = storageService;
  static const String _sessionTokenKey = 'session_auth_token';

  /// Send OTP for phone or email
  Future<Map<String, dynamic>> sendOtp({
    required String credential,
    required String type, // 'phone' or 'email'
    String purpose = 'login',
  }) async {
    try {
      return await _apiClient.sendOtp(
        credential: credential,
        type: type,
        purpose: purpose,
      );
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
      debugPrint("Error verifying OTP: ${e.toString().split('\n')[0]}");
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<Map<String, dynamic>> signUp({
    String? identifier,
    String? email,
    String? phone,
    required String password,
    required String name,
    String role = 'patient', // 'patient' or 'caregiver'
    String? verifiedCredentialType,
  }) async {
    try {
      // Register with backend
      final response = await _apiClient.signup(
        identifier: identifier,
        email: email,
        phone: phone,
        password: password,
        name: name,
        role: role,
        verifiedCredentialType: verifiedCredentialType,
      );

      final sessionToken = response['customToken'] as String?;
      if (sessionToken != null && sessionToken.isNotEmpty) {
        await _storage.saveString(_sessionTokenKey, sessionToken);
      }

      // Store user data locally
      if (response['user'] is Map<String, dynamic>) {
        await _storage.saveCurrentUser(
          response['user'] as Map<String, dynamic>,
        );
      }

      return response;
    } catch (e) {
      debugPrint("Error signing up: ${e.toString().split('\n')[0]}");
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

      final sessionToken = response['customToken'] as String?;
      if (sessionToken != null && sessionToken.isNotEmpty) {
        await _storage.saveString(_sessionTokenKey, sessionToken);
      }

      // Store user data locally
      if (response['user'] is Map<String, dynamic>) {
        await _storage.saveCurrentUser(
          response['user'] as Map<String, dynamic>,
        );
      }

      return response;
    } catch (e) {
      debugPrint("Error logging in: ${e.toString().split('\n')[0]}");
      rethrow;
    }
  }

  /// Validate login credentials before sending OTP
  Future<Map<String, dynamic>> checkLoginCredentials({
    required String credential,
    required String password,
  }) async {
    try {
      return await _apiClient.checkLoginCredentials(
        credential: credential,
        password: password,
      );
    } catch (e) {
      debugPrint(
        "Error validating login credentials: ${e.toString().split('\n')[0]}",
      );
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
      debugPrint(
        "Error sending forgot-password OTP: ${e.toString().split('\n')[0]}",
      );
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
      debugPrint("Error resetting password: ${e.toString().split('\n')[0]}");
      rethrow;
    }
  }

  /// Send OTP for step-up verification (authenticated)
  Future<Map<String, dynamic>> sendStepUpOtp({
    required String purpose,
    String channel = 'phone',
  }) async {
    try {
      return await _apiClient.sendStepUpOtp(purpose: purpose, channel: channel);
    } catch (e) {
      debugPrint("Error sending step-up OTP: ${e.toString().split('\n')[0]}");
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

      try {
        final profileResponse = await _apiClient.getUserProfile();
        final user = profileResponse['profile'] ?? profileResponse['user'];
        if (user is Map<String, dynamic>) {
          await _storage.saveCurrentUser(user);
        }
      } catch (_) {
        final currentUser = _storage.getCurrentUser();
        if (currentUser != null) {
          currentUser['emailVerified'] = true;
          await _storage.saveCurrentUser(currentUser);
        }
      }

      return response;
    } catch (e) {
      debugPrint("Error confirming email verification: $e");
      rethrow;
    }
  }

  /// Request phone verification OTP for the currently stored profile phone
  Future<Map<String, dynamic>> verifyPhone() async {
    try {
      return await _apiClient.verifyPhone();
    } catch (e) {
      debugPrint("Error requesting phone verification: $e");
      rethrow;
    }
  }

  /// Confirm phone verification OTP
  Future<Map<String, dynamic>> confirmPhoneVerification({
    required String otp,
  }) async {
    try {
      final response = await _apiClient.confirmPhoneVerification(otp: otp);

      try {
        final profileResponse = await _apiClient.getUserProfile();
        final user = profileResponse['profile'] ?? profileResponse['user'];
        if (user is Map<String, dynamic>) {
          await _storage.saveCurrentUser(user);
        }
      } catch (_) {
        final currentUser = _storage.getCurrentUser();
        if (currentUser != null) {
          currentUser['phoneVerified'] = true;
          await _storage.saveCurrentUser(currentUser);
        }
      }

      return response;
    } catch (e) {
      debugPrint("Error confirming phone verification: $e");
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
      unawaited(_apiClient.logout());
      await _storage.clearCurrentUser();
      await _storage.clearFCMToken();
      await _storage.remove(_sessionTokenKey);
    } catch (e) {
      debugPrint("Error logging out: $e");
      rethrow;
    }
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    final token = _storage.getString(_sessionTokenKey);
    return getCurrentUser() != null && token != null && token.isNotEmpty;
  }
}

/// Singleton instance of Auth Service
final authService = AuthService();
