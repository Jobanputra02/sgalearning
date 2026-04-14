import 'package:shared_preferences/shared_preferences.dart';

class ExamStatusService {
  static const String _exam3StringKey = 'exam_pitch_3string_passed';
  static const String _exam6StringKey = 'exam_pitch_6string_passed';

  static Future<bool> isExamPassed(String examKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(examKey) ?? false;
  }

  static Future<void> markExamPassed(String examKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(examKey, true);
  }

  static Future<void> resetExam(String examKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(examKey);
  }

  static String get pitch3StringKey => _exam3StringKey;
  static String get pitch6StringKey => _exam6StringKey;
}