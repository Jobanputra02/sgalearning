import 'local_db_service.dart';
import 'firestore_progress_service.dart';

class BestScoreService {

  static Future<Map<String, int>> getAllBestScores(
      String uid) async {
    try {
      // After syncOnStartup, local SQLite mirrors Firestore
      // Read from local for speed — works offline too
      final local = await _getLocalBestScores(uid);

      // If local is empty, try Firestore directly
      // (handles first launch before sync completes)
      if (local.isEmpty) {
        return await FirestoreProgressService
            .getAllBestScores(uid);
      }

      return local;
    } catch (_) {
      return {};
    }
  }

  static Future<Map<String, int>> _getLocalBestScores(
      String uid) async {
    try {
      final all = await LocalDbService.getAllAttempts(uid);
      final Map<String, int> best = {};
      for (final row in all) {
        final key     = row['exerciseKey'] as String;
        final correct = row['correct'] as int;
        if (!best.containsKey(key) || correct > best[key]!) {
          best[key] = correct;
        }
      }
      return best;
    } catch (_) {
      return {};
    }
  }
}