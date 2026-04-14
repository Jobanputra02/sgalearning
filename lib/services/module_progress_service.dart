import 'best_score_service.dart';

class ModuleProgressService {
  // PI total: 18 exercises * 10 + 2 exams * 30 = 240
  static const int _pitchTotal = 240;

  // NI total: 6 exercises * 10 + 2 exams * 30 = 120
  static const int _noteTotal = 120;

  static const List<String> _pitchKeys = [
    'EP_PI_1E', 'EP_PI_1M', 'EP_PI_1H',
    'EP_PI_2E', 'EP_PI_2M', 'EP_PI_2H',
    'EP_PI_3E', 'EP_PI_3M', 'EP_PI_3H',
    'EP_PI_Exam123',
    'EP_PI_4E', 'EP_PI_4M', 'EP_PI_4H',
    'EP_PI_5E', 'EP_PI_5M', 'EP_PI_5H',
    'EP_PI_6E', 'EP_PI_6M', 'EP_PI_6H',
    'EP_PI_Exam123456',
  ];

  static const List<String> _noteKeys = [
    'EP_NI_1', 'EP_NI_12', 'EP_NI_123',
    'EP_NI_Exam123',
    'EP_NI_1234', 'EP_NI_12345', 'EP_NI_123456',
    'EP_NI_Exam123456',
  ];

  // Returns 0.0 to 1.0
  static Future<double> getPitchProgress(String uid) async {
    return _calcProgress(uid, _pitchKeys, _pitchTotal);
  }

  static Future<double> getNoteProgress(String uid) async {
    return _calcProgress(uid, _noteKeys, _noteTotal);
  }

  static Future<double> _calcProgress(
    String uid,
    List<String> keys,
    int grandTotal,
  ) async {
    final bestScores =
        await BestScoreService.getAllBestScores(uid);

    if (bestScores.isEmpty) return 0.0;

    int totalCorrect = 0;

    for (final key in keys) {
      final best = bestScores[key];
      if (best != null) {
        totalCorrect += best;
      }
      // Unattempted = 0, no contribution
    }

    return totalCorrect / grandTotal;
  }
}