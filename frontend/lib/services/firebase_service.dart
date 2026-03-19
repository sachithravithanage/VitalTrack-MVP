import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

/// Initialize Firebase for the application
Future<void> initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Connect to Firebase emulators in debug mode
  if (kDebugMode) {
    try {
      // Connect to Auth emulator (runs on localhost:9099 by default)
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      debugPrint('✓ Connected to Firebase Auth Emulator');
    } catch (e) {
      // Emulator might not be running, continue anyway
      debugPrint('⚠ Auth Emulator not available: $e');
    }
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
  Future<String?> getIdToken() async {
    return await _auth.currentUser?.getIdToken();
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
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
      return null;
    }
  }

  /// Listen to FCM token changes
  void listenToFCMTokenChanges(Function(String) onTokenChanged) {
    _messaging.onTokenRefresh.listen(onTokenChanged);
  }

  /// Listen to incoming messages (foreground)
  void listenToMessages(Function(RemoteMessage) onMessage) {
    FirebaseMessaging.onMessage.listen(onMessage);
  }

  /// Handle notification tap
  void handleNotificationTap(Function(RemoteMessage) onNotificationTapped) {
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
