import 'dart:math';
import '../models/pitch_exercise_model.dart';
import 'note_map.dart';

class PitchQuestionGenerator {
  static final Random _random = Random();

  static List<PitchQuestion> generateQuestions(
      ExerciseConfig config, int count) {
    final notes = NoteMap.getStringNotes(config.stringNumber);
    return _generate(notes, config.semitoneRange, count);
  }

  static List<PitchQuestion> generateExamQuestions(
      ExerciseConfig config) {
    assert(config.isExam && config.examStrings != null);
    final notes = NoteMap.getMultiStringNotes(config.examStrings!);
    final total = config.totalQuestions;

    final hardCount   = (total * 0.6).round();
    final mediumCount = (total * 0.3).round();
    final easyCount   = total - hardCount - mediumCount;

    final hard   = _generate(notes, [1, 2, 3, 4],        hardCount);
    final medium = _generate(notes, [5, 6, 7, 8],        mediumCount);
    final easy   = _generate(notes, [9, 10, 11, 12, 13], easyCount);

    final all = [...hard, ...medium, ...easy];
    all.shuffle(_random);
    return all;
  }

  static List<PitchQuestion> _generate(
    List<NoteModel> notePool,
    List<int> semitoneRange,
    int count,
  ) {
    final questions = <PitchQuestion>[];
    int attempts = 0;

    while (questions.length < count && attempts < 5000) {
      attempts++;
      final noteA = notePool[_random.nextInt(notePool.length)];
      final firstIsHigher = _random.nextBool();
      final distance =
          semitoneRange[_random.nextInt(semitoneRange.length)];
      final targetMidi =
          firstIsHigher ? noteA.midi - distance : noteA.midi + distance;

      final candidates =
          notePool.where((n) => n.midi == targetMidi).toList();
      if (candidates.isEmpty) continue;

      final noteB = candidates[_random.nextInt(candidates.length)];
      questions.add(PitchQuestion(
        noteA: noteA,
        noteB: noteB,
        correctAnswer: firstIsHigher ? 'First' : 'Second',
      ));
    }
    return questions;
  }
}