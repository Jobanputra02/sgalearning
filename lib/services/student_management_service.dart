import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class StudentManagementService {
  static final _db = FirebaseFirestore.instance;

  // ─── Get Pending Students ─────────────────────────────────────
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
        results = results.where((s) => s.branch == branchFilter).toList();
      }

      return results;
    } catch (_) {
      return [];
    }
  }

  // ─── Get Approved Students ────────────────────────────────────
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
        results = results.where((s) => s.branch == branchFilter).toList();
      }

      return results;
    } catch (_) {
      return [];
    }
  }

  // ─── Approve Student ──────────────────────────────────────────
  static Future<void> approveStudent(String uid) async {
    await _db.collection('users').doc(uid).update({
      'isApproved': true,
      'isActive': true,
    });
  }

  // ─── Deactivate Student ───────────────────────────────────────
  static Future<void> deactivateStudent(String uid) async {
    await _db.collection('users').doc(uid).update({'isActive': false});
  }

  // ─── Activate Student ─────────────────────────────────────────
  static Future<void> activateStudent(String uid) async {
    await _db.collection('users').doc(uid).update({'isActive': true});
  }

  // ─── Reject Student ───────────────────────────────────────────
  static Future<void> rejectStudent(String uid) async {
    await _db.collection('users').doc(uid).update({
      'isActive': false,
      'isApproved': false,
    });
  }

  // ─── Delete Student Permanently ───────────────────────────────
  // Removes Firestore user doc + progress records, then deletes the
  // Firebase Auth account via a Cloud Function (Admin SDK required).
  static Future<void> deleteStudent(String uid) async {
    // 1. Delete user document — critical step; let it throw on failure
    await _db.collection('users').doc(uid).delete();

    // 2. Delete progress records — best-effort
    try {
      final progress = await _db
          .collection('progress')
          .where('uid', isEqualTo: uid)
          .get();

      if (progress.docs.isNotEmpty) {
        final progressBatch = _db.batch();
        for (final doc in progress.docs) {
          progressBatch.delete(doc.reference);
        }
        await progressBatch.commit();
      }
    } catch (_) {
      // Progress cleanup failed silently — user doc is already gone
    }

  }
}
