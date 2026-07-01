import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppAuthService {
  AppAuthService._();

  static final AppAuthService instance = AppAuthService._();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }

    return credential;
  }

  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> reloadCurrentUser() async {
    await _auth.currentUser?.reload();
  }

  Future<bool> isCurrentUserVerified() async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }

    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<bool> currentUserHasProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.exists;
  }

  Future<String?> trustedRoleForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    final tokenResult = await user.getIdTokenResult(true);
    final roleFromClaim = tokenResult.claims?['role'];
    if (roleFromClaim is String && roleFromClaim.isNotEmpty) {
      return roleFromClaim;
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();
    final data = doc.data();
    final roleFromProfile = data?['role'];
    if (roleFromProfile is String && roleFromProfile.isNotEmpty) {
      return roleFromProfile;
    }

    return null;
  }
}
