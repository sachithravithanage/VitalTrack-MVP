import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

const bool _enableLocalFcm = bool.fromEnvironment(
  'ENABLE_LOCAL_FCM',
  defaultValue: false,
);

bool get _isLocalFcmDisabled => kDebugMode && !_enableLocalFcm;

/// Initialize Firebase for the application
Future<void> initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Connect to Firebase emulators in debug mode
  if (kDebugMode) {
    try {
      final String emulatorHost =
          (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          ? '10.0.2.2'
          : 'localhost';

      // Connect to Auth emulator (runs on port 9099 by default)
      await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);

      // Connect to Firestore emulator (runs on port 8080 by default)
      FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);

      debugPrint('✓ Connected to Firebase Auth Emulator');
    } catch (e) {
      // Emulator might not be running, continue anyway
      debugPrint('⚠ Auth Emulator not available: $e');
    }
  }

  if (_isLocalFcmDisabled) {
    debugPrint('ℹ FCM disabled for local debug (ENABLE_LOCAL_FCM=false)');
    return;
  }

  // Request notification permissions
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  // Handle background messages
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

/// Background message handler for Firebase Cloud Messaging
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

/// Firebase Authentication Service
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Get current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Get current user's ID token
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final current = _auth.currentUser;
    if (current != null) {
      return await current.getIdToken(forceRefresh);
    }

    try {
      final restoredUser = await _auth
          .authStateChanges()
          .firstWhere((user) => user != null)
          .timeout(const Duration(seconds: 2));
      return await restoredUser?.getIdToken(forceRefresh);
    } catch (_) {
      return null;
    }
  }

  /// Sign up with email and password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with Firebase custom token
  Future<UserCredential> signInWithCustomToken(String token) async {
    try {
      return await _auth.signInWithCustomToken(token);
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get FCM Token for push notifications
  Future<String?> getFCMToken() async {
    if (_isLocalFcmDisabled) {
      return null;
    }

    try {
      return await _messaging.getToken();
    } catch (e) {
      final message = e.toString();
      if (kDebugMode && message.contains('API key not valid')) {
        debugPrint('ℹ Skipping FCM token in local debug (invalid API key).');
        return null;
      }
      debugPrint("Error getting FCM token: $e");
      return null;
    }
  }

  /// Listen to FCM token changes
  void listenToFCMTokenChanges(Function(String) onTokenChanged) {
    if (_isLocalFcmDisabled) {
      return;
    }
    _messaging.onTokenRefresh.listen(onTokenChanged);
  }

  /// Listen to incoming messages (foreground)
  void listenToMessages(Function(RemoteMessage) onMessage) {
    if (_isLocalFcmDisabled) {
      return;
    }
    FirebaseMessaging.onMessage.listen(onMessage);
  }

  /// Handle notification tap
  void handleNotificationTap(Function(RemoteMessage) onNotificationTapped) {
    if (_isLocalFcmDisabled) {
      return;
    }
    FirebaseMessaging.onMessageOpenedApp.listen(onNotificationTapped);
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  /// Stream of authentication changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}

/// Singleton instance of Firebase Auth Service
final firebaseAuthService = FirebaseAuthService();
