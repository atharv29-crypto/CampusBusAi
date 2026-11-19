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

  /// Streams buses that are currently active for Student registration.
  Stream<QuerySnapshot<Map<String, dynamic>>> activeBusesStream() {
    return _db
        .collection('buses')
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? selectedBusId,
    String requestedStudentBusId = '',
    String relationship = 'Parent/Guardian',
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

    String? requestedStudentUid;
    if (role == 'parent') {
      final normalizedStudentBusId = requestedStudentBusId.trim().toUpperCase();
      if (normalizedStudentBusId.isEmpty) {
        throw const AuthFlowException('Please enter the Student Bus ID.');
      }
      final lookup = await _db
          .collection('student_bus_id_lookup')
          .doc(normalizedStudentBusId)
          .get();
      if (!lookup.exists) {
        throw const AuthFlowException(
          'Student Bus ID not found. Please check the code shown below the student name.',
        );
      }
      requestedStudentUid = lookup.data()?['studentUid'] as String?;
      if (requestedStudentUid == null || requestedStudentUid.isEmpty) {
        throw const AuthFlowException('Student Bus ID is invalid.');
      }
    }

    DocumentReference<Map<String, dynamic>>? selectedBusRef;
    if (role == 'student') {
      if (selectedBusId == null || selectedBusId.trim().isEmpty) {
        throw const AuthFlowException('Please select your bus number.');
      }
      selectedBusRef = _db.collection('buses').doc(selectedBusId);
      final bus = await selectedBusRef.get();
      if (!bus.exists || bus.data()?['isActive'] != true) {
        throw const AuthFlowException(
          'Selected bus is no longer active. Please select another bus.',
        );
      }
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
      String generatedStudentId = '';
      String generatedStudentBusId = '';
      int? assignedSequence;
      String? assignedPrefix;
      if (role == 'student') {
        final busRef = selectedBusRef!;
        final busData = (await busRef.get()).data() ?? <String, dynamic>{};
        assignedPrefix = (busData['studentIdPrefix'] ?? '')
            .toString()
            .trim()
            .toUpperCase();
        if (assignedPrefix.isEmpty) {
          // Backward-compatible fallback for older bus records. Admin-created
          // buses receive a permanent prefix when they are added.
          final allBuses = await _db
              .collection('buses')
              .orderBy('createdAt')
              .get();
          final index = allBuses.docs.indexWhere((doc) => doc.id == busRef.id);
          assignedPrefix = String.fromCharCode(
            65 + (index < 0 ? 0 : index) % 26,
          );
          await busRef.update({'studentIdPrefix': assignedPrefix});
        }
        await _db.runTransaction((transaction) async {
          final freshBus = await transaction.get(busRef);
          final data = freshBus.data() ?? <String, dynamic>{};
          final next = (data['nextStudentSequence'] as num?)?.toInt() ?? 1;
          assignedSequence = next;
          assignedPrefix = (data['studentIdPrefix'] ?? assignedPrefix)
              .toString();
          transaction.update(busRef, {'nextStudentSequence': next + 1});
        });
        generatedStudentBusId =
            '$assignedPrefix${assignedSequence!.toString().padLeft(4, '0')}';
        generatedStudentId = 'STU${user.uid.substring(0, 8).toUpperCase()}';
      }
      final profile = <String, dynamic>{
        'uid': user.uid,
        'name': normalizedName,
        'email': normalizedEmail,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        if (role == 'student') 'studentId': generatedStudentId,
        if (role == 'student') 'studentBusId': generatedStudentBusId,
        if (role == 'student') 'busId': selectedBusRef!.id,
        if (role == 'student')
          'busNumber': (await selectedBusRef!.get()).data()?['busNumber'] ?? '',
        if (role == 'parent')
          'requestedStudentBusId': requestedStudentBusId.trim().toUpperCase(),
        if (role == 'parent') 'parentLinkStatus': 'pending',
        if (role == 'parent') 'relationship': relationship,
      };
      final batch = _db.batch();
      batch.set(_db.collection('users').doc(user.uid), profile);
      if (role == 'student') {
        batch.set(_db.collection('student_id_lookup').doc(generatedStudentId), {
          'studentUid': user.uid,
          'studentId': generatedStudentId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        batch.set(
          _db.collection('student_bus_id_lookup').doc(generatedStudentBusId),
          {
            'studentUid': user.uid,
            'studentBusId': generatedStudentBusId,
            'createdAt': FieldValue.serverTimestamp(),
          },
        );
      } else {
        final studentUid = requestedStudentUid!;
        final requestRef = _db.collection('parent_link_requests').doc();
        batch.set(requestRef, {
          'parentUid': user.uid,
          'parentName': normalizedName,
          'studentUid': studentUid,
          'studentBusId': requestedStudentBusId.trim().toUpperCase(),
          'relationship': relationship,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      await user.reload();
      await _auth.signOut();
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
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      await _auth.signOut();
      throw const AuthFlowException('Account not found. Please try again.');
    }

    try {
      final profileSnap = await _db.collection('users').doc(user.uid).get();
      if (!profileSnap.exists) {
        throw const AuthFlowException(
          'Your account profile is not ready. Please contact Admin.',
        );
      }

      final profile = profileSnap.data() ?? <String, dynamic>{};
      final role = (profile['role'] ?? '').toString().toLowerCase();

      if (profile['isActive'] == false) {
        throw const AuthFlowException(
          'Your account is inactive. Please contact Admin.',
        );
      }

      if (role == 'parent') {
        final requests = await _db
            .collection('parent_link_requests')
            .where('parentUid', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (requests.docs.isEmpty) {
          throw const AuthFlowException(
            'Parent linking request was not found. Please contact the Student.',
          );
        }

        final status = (requests.docs.first.data()['status'] ?? '')
            .toString()
            .toLowerCase();

        if (status == 'pending') {
          throw const AuthFlowException(
            'Your request is waiting for Student approval. You can login after the Student accepts it.',
          );
        }
        if (status == 'rejected') {
          throw const AuthFlowException(
            'Your request was rejected by the Student. Please contact the Student.',
          );
        }
        if (status != 'approved') {
          throw const AuthFlowException(
            'Your Parent account is not approved yet.',
          );
        }
      }

      return credential;
    } catch (_) {
      await _auth.signOut();
      rethrow;
    }
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
