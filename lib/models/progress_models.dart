class QuestionAttempt {
  // Common fields
  final String exerciseKey;   // e.g. EP_PI_1E
  final String exerciseType;  // "pitch" or "note"
  final bool isCorrect;
  final bool isSkipped;
  final int timeSeconds;
  final int replayCount;
  final String correctAnswer;
  final String userAnswer;

  // Pitch specific
  final String? noteA;
  final String? noteB;
  final int? noteAString;
  final int? noteAFret;
  final int? noteBString;
  final int? noteBFret;
  final int? semitoneDistance;

  // Note specific
  final String? notePlayed;
  final int? noteString;
  final int? noteFret;

  const QuestionAttempt({
    required this.exerciseKey,
    required this.exerciseType,
    required this.isCorrect,
    required this.isSkipped,
    required this.timeSeconds,
    required this.replayCount,
    required this.correctAnswer,
    required this.userAnswer,
    this.noteA,
    this.noteB,
    this.noteAString,
    this.noteAFret,
    this.noteBString,
    this.noteBFret,
    this.semitoneDistance,
    this.notePlayed,
    this.noteString,
    this.noteFret,
  });

  Map<String, dynamic> toMap() => {
    'exerciseKey':      exerciseKey,
    'exerciseType':     exerciseType,
    'isCorrect':        isCorrect ? 1 : 0,
    'isSkipped':        isSkipped ? 1 : 0,
    'timeSeconds':      timeSeconds,
    'replayCount':      replayCount,
    'correctAnswer':    correctAnswer,
    'userAnswer':       userAnswer,
    'noteA':            noteA,
    'noteB':            noteB,
    'noteAString':      noteAString,
    'noteAFret':        noteAFret,
    'noteBString':      noteBString,
    'noteBFret':        noteBFret,
    'semitoneDistance': semitoneDistance,
    'notePlayed':       notePlayed,
    'noteString':       noteString,
    'noteFret':         noteFret,
  };

  Map<String, dynamic> toFirestore() => {
    'exerciseKey':      exerciseKey,
    'exerciseType':     exerciseType,
    'isCorrect':        isCorrect,
    'isSkipped':        isSkipped,
    'timeSeconds':      timeSeconds,
    'replayCount':      replayCount,
    'correctAnswer':    correctAnswer,
    'userAnswer':       userAnswer,
    if (noteA != null)            'noteA':            noteA,
    if (noteB != null)            'noteB':            noteB,
    if (noteAString != null)      'noteAString':      noteAString,
    if (noteAFret != null)        'noteAFret':        noteAFret,
    if (noteBString != null)      'noteBString':      noteBString,
    if (noteBFret != null)        'noteBFret':        noteBFret,
    if (semitoneDistance != null) 'semitoneDistance': semitoneDistance,
    if (notePlayed != null)       'notePlayed':       notePlayed,
    if (noteString != null)       'noteString':       noteString,
    if (noteFret != null)         'noteFret':         noteFret,
  };
}

class ExerciseAttempt {
  final String? localId;        // SQLite row id
  final String exerciseKey;
  final String exerciseType;
  final DateTime attemptDate;
  final int totalQuestions;
  final int correct;
  final int wrong;
  final int skipped;
  final bool synced;
  final List<QuestionAttempt> questions;

  const ExerciseAttempt({
    this.localId,
    required this.exerciseKey,
    required this.exerciseType,
    required this.attemptDate,
    required this.totalQuestions,
    required this.correct,
    required this.wrong,
    required this.skipped,
    required this.synced,
    required this.questions,
  });

  Map<String, dynamic> toFirestore() => {
    'exerciseKey':    exerciseKey,
    'exerciseType':   exerciseType,
    'attemptDate':    attemptDate.toIso8601String(),
    'totalQuestions': totalQuestions,
    'correct':        correct,
    'wrong':          wrong,
    'skipped':        skipped,
    'questions':      questions.map((q) => q.toFirestore()).toList(),
  };
}