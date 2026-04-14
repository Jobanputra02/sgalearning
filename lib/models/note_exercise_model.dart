enum NoteExerciseType { exercise, exam }

class NoteOption {
  final String name;  // e.g. "E4"
  final int midi;

  const NoteOption({required this.name, required this.midi});

  @override
  bool operator ==(Object other) =>
      other is NoteOption && other.midi == midi;

  @override
  int get hashCode => midi.hashCode;
}

class NoteQuestion {
  final int string;
  final int fret;
  final String correctNote; // e.g. "E4"
  final int midi;

  const NoteQuestion({
    required this.string,
    required this.fret,
    required this.correctNote,
    required this.midi,
  });

  String get audioAsset => 'assets/audio/S$string - F$fret.mp3';
}

class NoteExerciseConfig {
  final String label;
  final String title;
  final List<int> strings;        // which strings to pull audio from
  final List<NoteOption> options; // answer options shown to user
  final NoteExerciseType type;
  final List<NoteOption> newNotes;
  final String accessKey;

  const NoteExerciseConfig({
    required this.label,
    required this.title,
    required this.strings,
    required this.options,
    this.type = NoteExerciseType.exercise,
    this.newNotes = const [], // empty = fully random (exams)
    required this.accessKey, // ← add this

  });

  bool get isExam => type == NoteExerciseType.exam;
  int get totalQuestions => isExam ? 30 : 10;
}

class NoteQuestionResult {
  final NoteQuestion question;
  final String userAnswer;
  final bool isCorrect;
  final bool isSkipped;
  final int timeSeconds;
  final int replayCount;

  const NoteQuestionResult({
    required this.question,
    required this.userAnswer,
    required this.isCorrect,
    required this.isSkipped,
    required this.timeSeconds,
    required this.replayCount,
  });
}