
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  UserService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Stream all user profiles.
  /// Access is still controlled by Firestore Security Rules.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchUsers() {
    return _db
        .collection('users')
        .orderBy('name')
        .snapshots();
  }

  /// Stream profiles for a specific role.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchUsersByRole(
    String role,
  ) {
    return _db
        .collection('users')
        .where('role', isEqualTo: role)
        .snapshots();
  }

  /// Get a single user's profile.
  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(
    String uid,
  ) {
    return _db.collection('users').doc(uid).get();
  }
}
