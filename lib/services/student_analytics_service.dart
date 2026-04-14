import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

// ─── Data models ──────────────────────────────────────────────────

class ExerciseScore {
  final String exerciseKey;
  final String label;
  final int bestCorrect;
  final int totalQuestions;
  final int attemptCount;
  final int bestAttemptNumber; // which attempt number was best
  final DateTime? lastAttempt;
  final List<AttemptRecord> attempts;

  const ExerciseScore({
    required this.exerciseKey,
    required this.label,
    required this.bestCorrect,
    required this.totalQuestions,
    required this.attemptCount,
    required this.bestAttemptNumber,
    required this.lastAttempt,
    required this.attempts,
  });

  double get percentage =>
      totalQuestions == 0 ? 0 : bestCorrect / totalQuestions;
}

class AttemptRecord {
  final String firestoreId;
  final String exerciseKey;
  final DateTime date;
  final int correct;
  final int wrong;
  final int skipped;
  final int totalQuestions;
  final List<QuestionRecord> questions;

  const AttemptRecord({
    required this.firestoreId,
    required this.exerciseKey,
    required this.date,
    required this.correct,
    required this.wrong,
    required this.skipped,
    required this.totalQuestions,
    required this.questions,
  });

  double get percentage =>
      totalQuestions == 0 ? 0 : correct / totalQuestions;
}

class QuestionRecord {
  final String correctAnswer;
  final String userAnswer;
  final bool isCorrect;
  final bool isSkipped;
  final int timeSeconds;
  final int replayCount;
  // Pitch specific
  final String? noteA;
  final String? noteB;
  final int? semitoneDistance;
  // Note specific
  final String? notePlayed;
  final int? noteString;

  const QuestionRecord({
    required this.correctAnswer,
    required this.userAnswer,
    required this.isCorrect,
    required this.isSkipped,
    required this.timeSeconds,
    required this.replayCount,
    this.noteA,
    this.noteB,
    this.semitoneDistance,
    this.notePlayed,
    this.noteString,
  });
}

class ConfusionGroup {
  final String correctNote;
  final List<ConfusionEntry> entries;

  const ConfusionGroup({
    required this.correctNote,
    required this.entries,
  });

  int get totalCount =>
      entries.fold(0, (s, e) => s + e.count);
}

class ConfusionEntry {
  final String answered;
  final int count;
  const ConfusionEntry(
      {required this.answered, required this.count});
}

// Speed vs accuracy quadrant
class SpeedAccuracyData {
  final double accuracy;   // 0.0 - 1.0
  final double avgTime;    // seconds
  final String quadrant;   // Mastery / Learning / Guessing / Needs Help
  final String description;

  const SpeedAccuracyData({
    required this.accuracy,
    required this.avgTime,
    required this.quadrant,
    required this.description,
  });
}

// Streak data
class StreakData {
  final int currentStreak;
  final List<PracticeDay> last28Days;

  const StreakData({
    required this.currentStreak,
    required this.last28Days,
  });
}

class PracticeDay {
  final DateTime date;
  final int minutesPracticed; // estimated from attempts
  final int attemptCount;

  const PracticeDay({
    required this.date,
    required this.minutesPracticed,
    required this.attemptCount,
  });

  // 0 = none, 1 = light (<10min), 2 = medium (10-30min), 3 = heavy (>30min)
  int get intensity {
    if (attemptCount == 0) return 0;
    if (minutesPracticed < 10) return 1;
    if (minutesPracticed < 30) return 2;
    return 3;
  }
}

enum StudentStatus { onTrack, monitor, needsAttention }

class StudentAnalytics {
  final UserModel student;
  final Map<String, int> noteAttemptsByNote;
  // Activity
  final DateTime? lastActive;
  final int daysInactive;
  final int sessionsLast7Days;
  final int totalAttempts;
  final StreakData streakData;

  // Progress
  final double pitchOverallPct;
  final double noteOverallPct;
  final int pitchUnlocked;
  final int noteUnlocked;

  // Exercise scores
  final List<ExerciseScore> pitchScores;
  final List<ExerciseScore> noteScores;

  // All attempts chronologically (newest first)
  final List<AttemptRecord> allAttemptRecords;

  // Stuck detection
  final List<String> stuckExercises;

  // Pitch metrics
  final Map<int, double> pitchAccuracyBySemitone;
  final Map<int, double> pitchAvgTimeBySemitone;
  final Map<int, int> pitchAttemptsBySemitone;

  // Note metrics
  final Map<int, double> noteAccuracyByString;
  final Map<int, double> noteAvgTimeByString;
  final Map<String, double> noteAccuracyByNote;
  final Map<String, double> noteAvgTimeByNote;
  final Map<int, int> noteAttemptsByString;

  // Note confusion
  final List<ConfusionGroup> noteConfusionGroups;

  // Speed vs accuracy
  final SpeedAccuracyData? pitchSpeedAccuracy;
  final SpeedAccuracyData? noteSpeedAccuracy;

  // Status
  final StudentStatus status;
  final String verdictLine;

  const StudentAnalytics({
    required this.student,
    required this.noteAttemptsByNote,
    required this.lastActive,
    required this.daysInactive,
    required this.sessionsLast7Days,
    required this.totalAttempts,
    required this.streakData,
    required this.pitchOverallPct,
    required this.noteOverallPct,
    required this.pitchUnlocked,
    required this.noteUnlocked,
    required this.pitchScores,
    required this.noteScores,
    required this.allAttemptRecords,
    required this.stuckExercises,
    required this.pitchAccuracyBySemitone,
    required this.pitchAvgTimeBySemitone,
    required this.pitchAttemptsBySemitone,
    required this.noteAccuracyByString,
    required this.noteAvgTimeByString,
    required this.noteAccuracyByNote,
    required this.noteAvgTimeByNote,
    required this.noteAttemptsByString,
    required this.noteConfusionGroups,
    required this.pitchSpeedAccuracy,
    required this.noteSpeedAccuracy,
    required this.status,
    required this.verdictLine,
  });
}

// ─── Service ──────────────────────────────────────────────────────

class StudentAnalyticsService {
  static final _db = FirebaseFirestore.instance;

  static const _pitchLabels = {
    'EP_PI_1E': 'String 1 – Easy',
    'EP_PI_1M': 'String 1 – Medium',
    'EP_PI_1H': 'String 1 – Hard',
    'EP_PI_2E': 'String 2 – Easy',
    'EP_PI_2M': 'String 2 – Medium',
    'EP_PI_2H': 'String 2 – Hard',
    'EP_PI_3E': 'String 3 – Easy',
    'EP_PI_3M': 'String 3 – Medium',
    'EP_PI_3H': 'String 3 – Hard',
    'EP_PI_Exam123': 'Exam – Strings 1,2,3',
    'EP_PI_4E': 'String 4 – Easy',
    'EP_PI_4M': 'String 4 – Medium',
    'EP_PI_4H': 'String 4 – Hard',
    'EP_PI_5E': 'String 5 – Easy',
    'EP_PI_5M': 'String 5 – Medium',
    'EP_PI_5H': 'String 5 – Hard',
    'EP_PI_6E': 'String 6 – Easy',
    'EP_PI_6M': 'String 6 – Medium',
    'EP_PI_6H': 'String 6 – Hard',
    'EP_PI_Exam123456': 'Exam – All 6 Strings',
  };

  static const _noteLabels = {
    'EP_NI_1': 'String 1',
    'EP_NI_12': 'String 1+2',
    'EP_NI_123': 'String 1+2+3',
    'EP_NI_Exam123': 'Exam – Strings 1,2,3',
    'EP_NI_1234': 'String 1+2+3+4',
    'EP_NI_12345': 'String 1+2+3+4+5',
    'EP_NI_123456': 'String 1+2+3+4+5+6',
    'EP_NI_Exam123456': 'Exam – All 6 Strings',
  };

  static int _totalFor(String key) =>
      key.contains('Exam') ? 30 : 10;

  static Future<StudentAnalytics> compute(
      UserModel student) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(student.uid)
          .collection('progress')
          .orderBy('attemptDate', descending: false)
          .get();

      final docs = snapshot.docs;

      if (docs.isEmpty) {
        return _emptyAnalytics(student);
      }

      // ── Parse all docs ─────────────────────────
      final allRecords = <AttemptRecord>[];
      for (final doc in docs) {
        final d = doc.data();
        final dateStr =
            d['attemptDate'] as String? ?? '';
        final date = DateTime.tryParse(dateStr);
        if (date == null) continue;

        final qRaw =
            d['questions'] as List<dynamic>? ?? [];
        final questions = qRaw
            .map((q) =>
                _parseQuestion(q as Map<String, dynamic>))
            .toList();

        allRecords.add(AttemptRecord(
          firestoreId:    doc.id,
          exerciseKey:    d['exerciseKey'] as String? ?? '',
          date:           date,
          correct:        d['correct'] as int? ?? 0,
          wrong:          d['wrong'] as int? ?? 0,
          skipped:        d['skipped'] as int? ?? 0,
          totalQuestions: d['totalQuestions'] as int? ?? 10,
          questions:      questions,
        ));
      }

      // Sort newest first for display
      final allSorted = [...allRecords]
        ..sort((a, b) => b.date.compareTo(a.date));

      // ── Activity ───────────────────────────────
      final allDates =
          allRecords.map((r) => r.date).toList();
      final lastActive = allDates.isEmpty
          ? null
          : allDates
              .reduce((a, b) => a.isAfter(b) ? a : b);

      final daysInactive = lastActive == null
          ? 999
          : DateTime.now()
              .difference(lastActive)
              .inDays;

      final sevenAgo = DateTime.now()
          .subtract(const Duration(days: 7));
      final sessionsLast7 = allDates
          .where((d) => d.isAfter(sevenAgo))
          .length;

      // ── Streak ─────────────────────────────────
      final streakData = _computeStreak(allRecords);

      // ── Per-exercise grouping ──────────────────
      final Map<String, List<AttemptRecord>>
          byExercise = {};
      for (int i = 0; i < docs.length; i++) {
        final d = docs[i].data();
        final key =
            d['exerciseKey'] as String? ?? '';
        if (key.isEmpty) continue;
        byExercise.putIfAbsent(key, () => []);
        byExercise[key]!.add(allRecords[i]);
      }

      // ── Build exercise scores ──────────────────
      List<ExerciseScore> buildScores(
          Map<String, String> labels) {
        return labels.entries.map((e) {
          final attempts = byExercise[e.key] ?? [];
          if (attempts.isEmpty) {
            return ExerciseScore(
              exerciseKey:      e.key,
              label:            e.value,
              bestCorrect:      0,
              totalQuestions:   _totalFor(e.key),
              attemptCount:     0,
              bestAttemptNumber: 0,
              lastAttempt:      null,
              attempts:         [],
            );
          }
          int bestCorrect = 0;
          int bestAttemptNum = 1;
          DateTime? lastDate;
          for (int i = 0; i < attempts.length; i++) {
            final a = attempts[i];
            if (a.correct > bestCorrect) {
              bestCorrect    = a.correct;
              bestAttemptNum = i + 1;
            }
            if (lastDate == null ||
                a.date.isAfter(lastDate)) {
              lastDate = a.date;
            }
          }
          return ExerciseScore(
            exerciseKey:      e.key,
            label:            e.value,
            bestCorrect:      bestCorrect,
            totalQuestions:   _totalFor(e.key),
            attemptCount:     attempts.length,
            bestAttemptNumber: bestAttemptNum,
            lastAttempt:      lastDate,
            attempts: attempts
              ..sort((a, b) =>
                  b.date.compareTo(a.date)),
          );
        }).toList();
      }

      final pitchScores = buildScores(_pitchLabels);
      final noteScores  = buildScores(_noteLabels);

      // ── Unlock counts ──────────────────────────
      final userDoc = await _db
          .collection('users')
          .doc(student.uid)
          .get();
      final userData =
          userDoc.data() ?? {};

      final pitchUnlocked = _pitchLabels.keys
          .where((k) => userData[k] == true)
          .length;
      final noteUnlocked = _noteLabels.keys
          .where((k) => userData[k] == true)
          .length;

      // ── Overall percentages ────────────────────
      int pitchSum = 0;
      int noteSum  = 0;
      for (final s in pitchScores) {
        pitchSum += s.bestCorrect;
      }
      for (final s in noteScores) {
        noteSum += s.bestCorrect;
      }
      final pitchPct = pitchSum / 240;
      final notePct  = noteSum / 120;

      // ── Stuck detection ────────────────────────
      final stuckKeys = <String>[];
      for (final key in [
        ..._pitchLabels.keys,
        ..._noteLabels.keys,
      ]) {
        final attempts = byExercise[key] ?? [];
        final total    = _totalFor(key);
        if (attempts.length >= 3) {
          final best = attempts
              .map((a) => a.correct)
              .reduce((a, b) => a > b ? a : b);
          if (best / total < 0.8) {
            stuckKeys.add(key);
          }
        }
      }

      // ── Pitch by semitone ──────────────────────
      final Map<int, List<bool>> semAcc    = {};
      final Map<int, List<int>>  semTimes  = {};
      for (final doc in docs) {
        final d   = doc.data();
        if (d['exerciseType'] != 'pitch') continue;
        final qRaw =
            d['questions'] as List<dynamic>? ?? [];
        for (final q in qRaw) {
          final qm  = q as Map<String, dynamic>;
          final dist =
              qm['semitoneDistance'] as int?;
          final isCorrect =
              qm['isCorrect'] as bool? ?? false;
          final isSkipped =
              qm['isSkipped'] as bool? ?? false;
          final time =
              qm['timeSeconds'] as int? ?? 0;
          if (dist == null || isSkipped) continue;
          semAcc.putIfAbsent(dist, () => []);
          semTimes.putIfAbsent(dist, () => []);
          semAcc[dist]!.add(isCorrect);
          semTimes[dist]!.add(time);
        }
      }

      final pitchBySemitone = <int, double>{};
      final pitchTimeBySemitone = <int, double>{};
      final pitchAttemptsBySemitone = <int, int>{};
      for (final e in semAcc.entries) {
        final correct =
            e.value.where((b) => b).length;
        pitchBySemitone[e.key] =
            correct / e.value.length;
        pitchAttemptsBySemitone[e.key] =
            e.value.length;
      }
      for (final e in semTimes.entries) {
        pitchTimeBySemitone[e.key] = e.value.isEmpty
            ? 0
            : e.value.reduce((a, b) => a + b) /
                e.value.length;
      }

      // ── Note by string & by note ───────────────
      final Map<int, List<bool>>    strAcc   = {};
      final Map<int, List<int>>     strTimes = {};
      final Map<String, List<bool>> noteAcc  = {};
      final Map<String, List<int>>  noteTimes = {};
      final Map<int, int>           strAttempts = {};

      for (final doc in docs) {
        final d = doc.data();
        if (d['exerciseType'] != 'note') continue;
        final qRaw =
            d['questions'] as List<dynamic>? ?? [];
        for (final q in qRaw) {
          final qm       = q as Map<String, dynamic>;
          final strNum   = qm['noteString'] as int?;
          final noteName =
              qm['correctAnswer'] as String? ?? '';
          final isCorrect =
              qm['isCorrect'] as bool? ?? false;
          final isSkipped =
              qm['isSkipped'] as bool? ?? false;
          final time =
              qm['timeSeconds'] as int? ?? 0;
          if (strNum == null || isSkipped) continue;

          strAcc.putIfAbsent(strNum, () => []);
          strTimes.putIfAbsent(strNum, () => []);
          strAcc[strNum]!.add(isCorrect);
          strTimes[strNum]!.add(time);
          strAttempts[strNum] =
              (strAttempts[strNum] ?? 0) + 1;

          if (noteName.isNotEmpty) {
            noteAcc.putIfAbsent(noteName, () => []);
            noteTimes.putIfAbsent(noteName, () => []);
            noteAcc[noteName]!.add(isCorrect);
            noteTimes[noteName]!.add(time);
          }
          
        }
      }

      final noteByString  = <int, double>{};
      final noteTimeByStr = <int, double>{};
      for (final e in strAcc.entries) {
        final c = e.value.where((b) => b).length;
        noteByString[e.key] = c / e.value.length;
      }
      for (final e in strTimes.entries) {
        noteTimeByStr[e.key] = e.value.isEmpty
            ? 0
            : e.value.reduce((a, b) => a + b) /
                e.value.length;
      }

      final noteByNote     = <String, double>{};
      final noteTimeByNote = <String, double>{};
      for (final e in noteAcc.entries) {
        final c = e.value.where((b) => b).length;
        noteByNote[e.key] = c / e.value.length;
      }
      for (final e in noteTimes.entries) {
        noteTimeByNote[e.key] = e.value.isEmpty
            ? 0
            : e.value.reduce((a, b) => a + b) /
                e.value.length;
      }final noteAttemptsByNote = <String, int>{};
            for (final e in noteAcc.entries) {
              noteAttemptsByNote[e.key] = e.value.length;
            }

      // ── Note confusion groups ──────────────────
      final Map<String, Map<String, int>> confusion = {};
      for (final doc in docs) {
        final d = doc.data();
        if (d['exerciseType'] != 'note') continue;
        final qRaw =
            d['questions'] as List<dynamic>? ?? [];
        for (final q in qRaw) {
          final qm      = q as Map<String, dynamic>;
          final correct =
              qm['correctAnswer'] as String? ?? '';
          final answered =
              qm['userAnswer'] as String? ?? '';
          final isCorrect =
              qm['isCorrect'] as bool? ?? false;
          final isSkipped =
              qm['isSkipped'] as bool? ?? false;
          if (isCorrect || isSkipped) continue;
          if (correct.isEmpty || answered.isEmpty) {
            continue;
          }
          confusion.putIfAbsent(correct, () => {});
          confusion[correct]![answered] =
              (confusion[correct]![answered] ?? 0) + 1;
        }
      }

      final groups = confusion.entries.map((e) {
        final entries = e.value.entries
            .map((x) => ConfusionEntry(
                answered: x.key, count: x.value))
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));
        return ConfusionGroup(
            correctNote: e.key, entries: entries);
      }).toList()
        ..sort((a, b) =>
            b.totalCount.compareTo(a.totalCount));

      // ── Speed vs accuracy ──────────────────────
      final pitchSA =
          _computeSpeedAccuracy('pitch', docs);
      final noteSA =
          _computeSpeedAccuracy('note', docs);

      // ── Status ─────────────────────────────────
      final status = _computeStatus(
        daysInactive: daysInactive,
        stuckCount:   stuckKeys.length,
        pitchPct:     pitchPct,
        notePct:      notePct,
        sessionsLast7: sessionsLast7,
      );

      final verdict = _verdictLine(
        status:       status,
        daysInactive: daysInactive,
        stuckKeys:    stuckKeys,
        pitchPct:     pitchPct,
        notePct:      notePct,
      );

      return StudentAnalytics(
        noteAttemptsByNote:       noteAttemptsByNote,
        student:                  student,
        lastActive:               lastActive,
        daysInactive:             daysInactive,
        sessionsLast7Days:        sessionsLast7,
        totalAttempts:            docs.length,
        streakData:               streakData,
        pitchOverallPct:          pitchPct,
        noteOverallPct:           notePct,
        pitchUnlocked:            pitchUnlocked,
        noteUnlocked:             noteUnlocked,
        pitchScores:              pitchScores,
        noteScores:               noteScores,
        allAttemptRecords:        allSorted,
        stuckExercises:           stuckKeys,
        pitchAccuracyBySemitone:  pitchBySemitone,
        pitchAvgTimeBySemitone:   pitchTimeBySemitone,
        pitchAttemptsBySemitone:  pitchAttemptsBySemitone,
        noteAccuracyByString:     noteByString,
        noteAvgTimeByString:      noteTimeByStr,
        noteAccuracyByNote:       noteByNote,
        noteAvgTimeByNote:        noteTimeByNote,
        noteAttemptsByString:     strAttempts,
        noteConfusionGroups:      groups.take(10).toList(),
        pitchSpeedAccuracy:       pitchSA,
        noteSpeedAccuracy:        noteSA,
        status:                   status,
        verdictLine:              verdict,
      );
    } catch (_) {
      return _emptyAnalytics(student);
    }
  }

  static QuestionRecord _parseQuestion(
      Map<String, dynamic> qm) {
    return QuestionRecord(
      correctAnswer:    qm['correctAnswer'] as String? ?? '',
      userAnswer:       qm['userAnswer'] as String? ?? '',
      isCorrect:        qm['isCorrect'] as bool? ?? false,
      isSkipped:        qm['isSkipped'] as bool? ?? false,
      timeSeconds:      qm['timeSeconds'] as int? ?? 0,
      replayCount:      qm['replayCount'] as int? ?? 0,
      noteA:            qm['noteA'] as String?,
      noteB:            qm['noteB'] as String?,
      semitoneDistance: qm['semitoneDistance'] as int?,
      notePlayed:       qm['notePlayed'] as String?,
      noteString:       qm['noteString'] as int?,
    );
  }

  static SpeedAccuracyData? _computeSpeedAccuracy(
    String type,
    List<QueryDocumentSnapshot<Map<String, dynamic>>>
        docs,
  ) {
    final times    = <int>[];
    final corrects = <bool>[];

    for (final doc in docs) {
      final d = doc.data();
      if (d['exerciseType'] != type) continue;
      final qRaw =
          d['questions'] as List<dynamic>? ?? [];
      for (final q in qRaw) {
        final qm       = q as Map<String, dynamic>;
        final isSkipped =
            qm['isSkipped'] as bool? ?? false;
        if (isSkipped) continue;
        final time =
            qm['timeSeconds'] as int? ?? 0;
        final isCorrect =
            qm['isCorrect'] as bool? ?? false;
        times.add(time);
        corrects.add(isCorrect);
      }
    }

    if (times.isEmpty) return null;

    final accuracy = corrects.where((b) => b).length /
        corrects.length;
    final avgTime = times.reduce((a, b) => a + b) /
        times.length;

    // Median time as threshold
    final sorted = [...times]..sort();
    final medianTime =
        sorted[sorted.length ~/ 2].toDouble();

    final fast     = avgTime <= medianTime;
    final accurate = accuracy >= 0.7;

    String quadrant;
    String description;

    if (fast && accurate) {
      quadrant    = 'Mastery';
      description =
          'Fast & correct — material is mastered';
    } else if (!fast && accurate) {
      quadrant    = 'Learning';
      description =
          'Slow but correct — cognitive effort, still learning';
    } else if (fast && !accurate) {
      quadrant    = 'Guessing';
      description =
          'Fast but wrong — likely guessing, needs focus';
    } else {
      quadrant    = 'Needs Help';
      description =
          'Slow & wrong — struggling, teacher intervention needed';
    }

    return SpeedAccuracyData(
      accuracy:    accuracy,
      avgTime:     avgTime,
      quadrant:    quadrant,
      description: description,
    );
  }

  static StreakData _computeStreak(
      List<AttemptRecord> records) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Group attempts by day
    final Map<DateTime, List<AttemptRecord>> byDay = {};
    for (final r in records) {
      final day = DateTime(
          r.date.year, r.date.month, r.date.day);
      byDay.putIfAbsent(day, () => []);
      byDay[day]!.add(r);
    }

    // Last 28 days
    final last28 = <PracticeDay>[];
    for (int i = 27; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final attempts = byDay[day] ?? [];
      // Estimate minutes: avg 3 min per attempt
      final mins = attempts.length * 3;
      last28.add(PracticeDay(
        date:             day,
        minutesPracticed: mins,
        attemptCount:     attempts.length,
      ));
    }

    // Current streak
    int streak = 0;
    for (int i = 27; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      if ((byDay[day] ?? []).isEmpty) {
        if (i < 27) break;
      } else {
        if (i == 27 ||
            streak > 0 ||
            day == today) {
          streak++;
        }
      }
    }

    // Recalculate streak properly
    streak = 0;
    for (int i = 0; i <= 27; i++) {
      final day = today.subtract(Duration(days: i));
      if ((byDay[day] ?? []).isNotEmpty) {
        streak++;
      } else {
        break;
      }
    }

    return StreakData(
        currentStreak: streak, last28Days: last28);
  }

  static StudentStatus _computeStatus({
    required int daysInactive,
    required int stuckCount,
    required double pitchPct,
    required double notePct,
    required int sessionsLast7,
  }) {
    if (daysInactive > 14 || stuckCount > 0) {
      return StudentStatus.needsAttention;
    }
    if (pitchPct < 0.6 ||
        notePct < 0.6 ||
        sessionsLast7 < 2) {
      return StudentStatus.monitor;
    }
    return StudentStatus.onTrack;
  }

  static String _verdictLine({
    required StudentStatus status,
    required int daysInactive,
    required List<String> stuckKeys,
    required double pitchPct,
    required double notePct,
  }) {
    if (daysInactive > 14) {
      return 'Inactive $daysInactive days — needs follow-up';
    }
    if (stuckKeys.isNotEmpty) {
      final all = {..._pitchLabels, ..._noteLabels};
      final label = all[stuckKeys.first] ??
          stuckKeys.first;
      return 'Stuck on $label';
    }
    return 'Active · Pitch ${(pitchPct * 100).round()}% · Note ${(notePct * 100).round()}%';
  }

  static StudentAnalytics _emptyAnalytics(
      UserModel student) {
    return StudentAnalytics(
      student:                  student,
      noteAttemptsByNote: {},
      lastActive:               null,
      daysInactive:             999,
      sessionsLast7Days:        0,
      totalAttempts:            0,
      streakData:               const StreakData(
          currentStreak: 0, last28Days: []),
      pitchOverallPct:          0,
      noteOverallPct:           0,
      pitchUnlocked:            0,
      noteUnlocked:             0,
      pitchScores:              _pitchLabels.entries
          .map((e) => ExerciseScore(
                exerciseKey:      e.key,
                label:            e.value,
                bestCorrect:      0,
                totalQuestions:   _totalFor(e.key),
                attemptCount:     0,
                bestAttemptNumber: 0,
                lastAttempt:      null,
                attempts:         [],
              ))
          .toList(),
      noteScores:               _noteLabels.entries
          .map((e) => ExerciseScore(
                exerciseKey:      e.key,
                label:            e.value,
                bestCorrect:      0,
                totalQuestions:   _totalFor(e.key),
                attemptCount:     0,
                bestAttemptNumber: 0,
                lastAttempt:      null,
                attempts:         [],
              ))
          .toList(),
      allAttemptRecords:        [],
      stuckExercises:           [],
      pitchAccuracyBySemitone:  {},
      pitchAvgTimeBySemitone:   {},
      pitchAttemptsBySemitone:  {},
      noteAccuracyByString:     {},
      noteAvgTimeByString:      {},
      noteAccuracyByNote:       {},
      noteAvgTimeByNote:        {},
      noteAttemptsByString:     {},
      noteConfusionGroups:      [],
      pitchSpeedAccuracy:       null,
      noteSpeedAccuracy:        null,
      status:                   StudentStatus.needsAttention,
      verdictLine:              'No activity yet',
    );
  }

  // Delete an attempt from Firestore
  static Future<void> deleteAttempt({
  required String studentUid,
  required String firestoreId,
}) async {
  // firestoreId must not be empty
  if (firestoreId.isEmpty) {
    throw Exception('Invalid Firestore ID');
  }
  await _db
      .collection('users')
      .doc(studentUid)
      .collection('progress')
      .doc(firestoreId)
      .delete();
}
}