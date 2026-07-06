import 'package:firebase_core/firebase_core.dart';

/// Firebase configuration for the app
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Using vitaltrack-vcode project credentials
    // These connect to Firebase emulators in debug mode
    return const FirebaseOptions(
      apiKey: 'AIzaSyDummyKeyForLocalEmulator',
      appId: '1:123456789:web:abcdef1234567890',
      messagingSenderId: '123456789',
      projectId: 'vitaltrack-vcode',
      storageBucket: 'vitaltrack-vcode.appspot.com',
      iosBundleId: 'com.example.vitaltrack',
    );
  }
}
