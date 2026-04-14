import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class StudentManagementService {
  static final _db = FirebaseFirestore.instance;

  static Future<List<UserModel>> getPendingStudents({
    String? branchFilter,
    }) async {
      try {
        var query = _db
            .collection('users')
            .where('role', isEqualTo: 'student')
            .where('isApproved', isEqualTo: false)
            .where('isActive', isEqualTo: true);

        final snapshot = await query.get();
        var results = snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList();

        if (branchFilter != null) {
          results = results
              .where((s) => s.branch == branchFilter)
              .toList();
        }

        return results;
      } catch (_) {
        return [];
      }
    }

    static Future<List<UserModel>> getApprovedStudents({
      String? branchFilter,
    }) async {
      try {
        final snapshot = await _db
            .collection('users')
            .where('role', isEqualTo: 'student')
            .where('isApproved', isEqualTo: true)
            .get();

        var results = snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList();

        if (branchFilter != null) {
          results = results
              .where((s) => s.branch == branchFilter)
              .toList();
        }

        return results;
      } catch (_) {
        return [];
      }
    }

  static Future<void> approveStudent(String uid) async {
    await _db.collection('users').doc(uid).update({
      'isApproved': true,
      'isActive':   true,
    });
  }

  static Future<void> deactivateStudent(String uid) async {
    await _db.collection('users').doc(uid).update({
      'isActive': false,
    });
  }

  static Future<void> activateStudent(String uid) async {
    await _db.collection('users').doc(uid).update({
      'isActive': true,
    });
  }

  static Future<void> rejectStudent(String uid) async {
    await _db.collection('users').doc(uid).update({
      'isActive':   false,
      'isApproved': false,
    });
  }
}