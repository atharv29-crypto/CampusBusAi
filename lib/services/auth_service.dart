import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final normalizedName = name.trim();
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedName.isEmpty) {
      throw const AuthFlowException('Please enter your full name.');
    }
    if (role != 'student' && role != 'parent') {
      throw const AuthFlowException(
        'Public registration is available only for Student and Parent.',
      );
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    final user = credential.user;

    if (user == null) {
      throw const AuthFlowException(
        'Account was created, but Firebase returned no user. Please login.',
      );
    }

    try {
      await user.updateDisplayName(normalizedName);
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': normalizedName,
        'email': normalizedEmail,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
      await user.reload();
      return credential;
    } on FirebaseException catch (e) {
      // Authentication may have created the account before Firestore failed.
      // Do not delete the account silently; explain how to recover.
      if (e.code == 'permission-denied') {
        throw const AuthFlowException(
          'Account created, but Firestore denied profile creation. '
          'Deploy the provided firestore.rules, then login again or create '
          'the missing users document for this UID.',
        );
      }
      rethrow;
    }
  }

  /// Creates a Firebase Authentication account and submits a driver request.
  /// This does NOT grant the driver role or dashboard access. An admin must
  /// verify and approve the request through a trusted admin workflow.
  Future<void> submitDriverRegistration({
    required String name,
    required String email,
    required String password,
    required String mobile,
    required String employeeId,
    required String busNumber,
  }) async {
    final normalizedName = name.trim();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedMobile = mobile.trim();
    final normalizedEmployeeId = employeeId.trim();
    final normalizedBusNumber = busNumber.trim().toUpperCase();

    if (normalizedName.isEmpty ||
        normalizedMobile.isEmpty ||
        normalizedEmployeeId.isEmpty ||
        normalizedBusNumber.isEmpty) {
      throw const AuthFlowException('Please complete all driver details.');
    }

    UserCredential? credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthFlowException(
          'Firebase did not return the new account.',
        );
      }

      await user.updateDisplayName(normalizedName);
      await _db.collection('driver_requests').doc(user.uid).set({
        'uid': user.uid,
        'name': normalizedName,
        'email': normalizedEmail,
        'mobile': normalizedMobile,
        'employeeId': normalizedEmployeeId,
        'busNumber': normalizedBusNumber,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const AuthFlowException(
          'Firebase account created, but Firestore denied the request. Deploy the updated firestore.rules and contact the project admin before trying again.',
        );
      }
      rethrow;
    } finally {
      // The new driver stays signed out so AuthGate cannot send an unapproved
      // request to the role dashboard.
      if (credential?.user != null) {
        await _auth.signOut();
      }
    }
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  Future<String?> getUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data();
    final role = data?['role'];
    if (role is! String) return null;
    return role;
  }

  Future<void> logout() => _auth.signOut();
}

class AuthFlowException implements Exception {
  const AuthFlowException(this.message);
  final String message;

  @override
  String toString() => message;
}
