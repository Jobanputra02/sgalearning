import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreProgressService {
  static final _db = FirebaseFirestore.instance;

  // Fetch best scores for all exercises from Firestore
  static Future<Map<String, int>> getAllBestScores(
      String uid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('progress')
          .get();

      final Map<String, int> best = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final key     = data['exerciseKey'] as String? ?? '';
        final correct = data['correct'] as int? ?? 0;

        if (key.isEmpty) continue;

        if (!best.containsKey(key) || correct > best[key]!) {
          best[key] = correct;
        }
      }

      return best;
    } catch (_) {
      return {};
    }
  }

  // Fetch best score for a single exercise
  static Future<int?> getBestScore(
      String uid, String exerciseKey) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('progress')
          .where('exerciseKey', isEqualTo: exerciseKey)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return snapshot.docs
          .map((d) => d.data()['correct'] as int? ?? 0)
          .reduce((a, b) => a > b ? a : b);
    } catch (_) {
      return null;
    }
  }
}