class NoteModel {
  final int string;
  final int fret;
  final String name;
  final int midi;

  const NoteModel({
    required this.string,
    required this.fret,
    required this.name,
    required this.midi,
  });

  String get audioAsset => 'assets/audio/S$string - F$fret.mp3';
}

class PitchQuestion {
  final NoteModel noteA;
  final NoteModel noteB;
  final String correctAnswer;

  const PitchQuestion({
    required this.noteA,
    required this.noteB,
    required this.correctAnswer,
  });
}

enum Difficulty { easy, medium, hard }
enum ExerciseType { exercise, exam }

class ExerciseConfig {
  final int stringNumber;
  final Difficulty difficulty;
  final String label;
  final ExerciseType type;
  final List<int>? examStrings;
  final String accessKey;

  const ExerciseConfig({
    required this.stringNumber,
    required this.difficulty,
    required this.label,
    this.type = ExerciseType.exercise,
    this.examStrings,
    required this.accessKey,
  });

  bool get isExam => type == ExerciseType.exam;

  String get stringName {
    const names = ['E', 'B', 'G', 'D', 'A', 'E'];
    if (stringNumber < 1 || stringNumber > 6) return '';
    return names[stringNumber - 1];
  }

  List<int> get semitoneRange {
    switch (difficulty) {
      case Difficulty.easy:   return [9, 10, 11, 12, 13];
      case Difficulty.medium: return [5, 6, 7, 8];
      case Difficulty.hard:   return [1, 2, 3, 4];
    }
  }

  String get difficultyLabel {
    switch (difficulty) {
      case Difficulty.easy:   return 'Easy';
      case Difficulty.medium: return 'Medium';
      case Difficulty.hard:   return 'Hard';
    }
  }

  int get totalQuestions => isExam ? 30 : 10;
}

class QuestionResult {
  final PitchQuestion question;
  final String userAnswer;
  final bool isCorrect;
  final bool isSkipped;
  final int timeSeconds;
  final int replayCount;

  const QuestionResult({
    required this.question,
    required this.userAnswer,
    required this.isCorrect,
    required this.isSkipped,
    required this.timeSeconds,
    required this.replayCount,
  });
}