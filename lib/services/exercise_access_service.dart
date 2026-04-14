import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/exercise_access_model.dart';
import 'local_db_service.dart';

class ExerciseAccessService {
  static final _db = FirebaseFirestore.instance;

  static const List<String> _pitchSequence = [
    'EP_PI_1E', 'EP_PI_1M', 'EP_PI_1H',
    'EP_PI_2E', 'EP_PI_2M', 'EP_PI_2H',
    'EP_PI_3E', 'EP_PI_3M', 'EP_PI_3H',
    'EP_PI_Exam123',
    'EP_PI_4E', 'EP_PI_4M', 'EP_PI_4H',
    'EP_PI_5E', 'EP_PI_5M', 'EP_PI_5H',
    'EP_PI_6E', 'EP_PI_6M', 'EP_PI_6H',
    'EP_PI_Exam123456',
  ];

  static const List<String> _noteSequence = [
    'EP_NI_1', 'EP_NI_12', 'EP_NI_123',
    'EP_NI_Exam123',
    'EP_NI_1234', 'EP_NI_12345', 'EP_NI_123456',
    'EP_NI_Exam123456',
  ];

  // ─── Fetch access ─────────────────────────────────────────────
  static Future<ExerciseAccess> getAccess(
      String uid, String role) async {
    if (role == 'faculty' || role == 'admin') {
      return ExerciseAccess.fullAccess();
    }

    try {
      final doc =
          await _db.collection('users').doc(uid).get();
      if (!doc.exists) return ExerciseAccess.defaultStudent();

      final data = doc.data() as Map<String, dynamic>;

      if (!data.containsKey('EP_PI_1E')) {
        final defaults = ExerciseAccess.defaultStudent();
        await _db.collection('users').doc(uid).set(
          defaults.toMap(),
          SetOptions(merge: true),
        );
        return defaults;
      }

      // Merge any locally queued unlocks on top of Firestore data
      final localUnlocks =
          await LocalDbService.getUnsyncedUnlocks(uid);
      for (final row in localUnlocks) {
        final key = row['exerciseKey'] as String;
        data[key] = true;
      }

      return ExerciseAccess.fromMap(data);
    } catch (_) {
      // Offline — build access from defaults + local unlock queue
      return await _getOfflineAccess(uid);
    }
  }

  // Build access from local unlock queue when offline
  static Future<ExerciseAccess> _getOfflineAccess(
      String uid) async {
    try {
      final defaults = ExerciseAccess.defaultStudent();
      final map = Map<String, dynamic>.from(defaults.toMap());

      final localUnlocks =
          await LocalDbService.getUnsyncedUnlocks(uid);
      for (final row in localUnlocks) {
        final key = row['exerciseKey'] as String;
        map[key] = true;
      }

      return ExerciseAccess.fromMap(map);
    } catch (_) {
      return ExerciseAccess.defaultStudent();
    }
  }

  // ─── Auto-unlock — works offline ─────────────────────────────
  static Future<bool> checkAndAutoUnlock({
    required String uid,
    required String exerciseKey,
    required int correct,
    required int total,
  }) async {
    try {
      final ratio = correct / total;
      debugPrint('checkAndAutoUnlock: $exerciseKey $correct/$total = $ratio');

      final passed = ratio >= 0.8;
      if (!passed) {
        debugPrint('Not passed — no unlock');
        return false;
      }

      String? nextKey;

      final pitchIndex = _pitchSequence.indexOf(exerciseKey);
      if (pitchIndex != -1 &&
          pitchIndex < _pitchSequence.length - 1) {
        nextKey = _pitchSequence[pitchIndex + 1];
      }

      final noteIndex = _noteSequence.indexOf(exerciseKey);
      if (noteIndex != -1 &&
          noteIndex < _noteSequence.length - 1) {
        nextKey = _noteSequence[noteIndex + 1];
      }

      debugPrint('Next key to unlock: $nextKey');

      if (nextKey == null) return false;

      await LocalDbService.saveUnlock(
        uid:         uid,
        exerciseKey: nextKey,
      );
      debugPrint('Saved unlock locally: $nextKey');

      await _syncUnlockToFirestore(uid, nextKey);

      return true;
    } catch (e) {
      debugPrint('checkAndAutoUnlock error: $e');
      return false;
    }
  }

  // Try to write unlock to Firestore
  static Future<void> _syncUnlockToFirestore(
      String uid, String exerciseKey) async {
    try {
      await _db.collection('users').doc(uid).update({
        exerciseKey: true,
      });
      // Find and mark local unlock as synced
      final unlocks =
          await LocalDbService.getUnsyncedUnlocks(uid);
      for (final row in unlocks) {
        if (row['exerciseKey'] == exerciseKey) {
          await LocalDbService.markUnlockSynced(
              row['id'] as int);
        }
      }
    } catch (_) {
      // Offline — stays in local queue, synced later
    }
  }

  // ─── Sync pending unlocks to Firestore ───────────────────────
  static Future<void> syncPendingUnlocks(String uid) async {
    try {
      final unlocks =
          await LocalDbService.getUnsyncedUnlocks(uid);
      for (final row in unlocks) {
        final key      = row['exerciseKey'] as String;
        final localId  = row['id'] as int;
        try {
          await _db.collection('users').doc(uid).update({
            key: true,
          });
          await LocalDbService.markUnlockSynced(localId);
        } catch (_) {
          // Skip — retry next sync
        }
      }
    } catch (_) {
      // Silent
    }
  }

  // ─── Manual access control (faculty/admin) ───────────────────
  static Future<void> setAccess(
      String studentUid, String key, bool value) async {
    await _db
        .collection('users')
        .doc(studentUid)
        .update({key: value});
  }

  static Future<void> setMultipleAccess(
      String studentUid, Map<String, bool> updates) async {
    await _db
        .collection('users')
        .doc(studentUid)
        .update(updates.cast<String, dynamic>());
  }

  static Future<void> writeDefaultAccess(String uid) async {
    final defaults = ExerciseAccess.defaultStudent();
    await _db.collection('users').doc(uid).set(
      defaults.toMap(),
      SetOptions(merge: true),
    );
  }
}