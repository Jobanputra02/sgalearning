import 'package:shared_preferences/shared_preferences.dart';

class NoteExamStatusService {
  static const String _note3StringKey = 'exam_note_3string_passed';
  static const String _note6StringKey = 'exam_note_6string_passed';

  static Future<bool> isExamPassed(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  static Future<void> markExamPassed(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
  }

  static Future<void> resetExam(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static String get note3StringKey => _note3StringKey;
  static String get note6StringKey => _note6StringKey;
}