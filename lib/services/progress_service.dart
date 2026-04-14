import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import '../models/progress_models.dart';
import 'local_db_service.dart';
import 'exercise_access_service.dart';

class ProgressService {
  static final _db = FirebaseFirestore.instance;
  static bool _syncing = false;

  // ─── Save attempt ─────────────────────────────────────────────
  static Future<void> saveAttempt({
    required String uid,
    required ExerciseAttempt attempt,
  }) async {
    try {
      // Save to SQLite first
      final localId = await LocalDbService.saveAttempt(
        uid: uid,
        attempt: attempt,
      );

      // Try immediate Firestore sync if online
      final online = await _isOnline();
      if (online) {
        // Mark pending BEFORE writing to Firestore
        // This prevents syncPending from also picking it up
        await LocalDbService.markPending(localId);
        try {
          await _writeToFirestore(uid, attempt);
          await LocalDbService.markSynced(localId);
        } catch (_) {
          // Firestore failed — reset pending so syncPending can retry
          await LocalDbService.resetPending(localId);
        }
      }
      // If offline — stays unsynced in SQLite, syncs when online
    } catch (_) {
      // Silent
    }
  }

  // ─── Sync all pending local attempts ─────────────────────────
  static Future<void> syncPending(String uid) async {
    if (_syncing) return;
    final online = await _isOnline();
    if (!online) return;

    _syncing = true;
    try {
      // Only picks up records where synced=0 AND pending=0
      final unsynced = await LocalDbService.getUnsynced(uid);

      for (final row in unsynced) {
        final localId = row['id'] as int;
        try {
          // Lock this record before syncing
          await LocalDbService.markPending(localId);

          final questions =
              (jsonDecode(row['questionsJson'] as String) as List)
                  .map((q) =>
                      _questionFromMap(q as Map<String, dynamic>))
                  .toList();

          final attempt = ExerciseAttempt(
            exerciseKey:    row['exerciseKey'] as String,
            exerciseType:   row['exerciseType'] as String,
            attemptDate:
                DateTime.parse(row['attemptDate'] as String),
            totalQuestions: row['totalQuestions'] as int,
            correct:        row['correct'] as int,
            wrong:          row['wrong'] as int,
            skipped:        row['skipped'] as int,
            synced:         false,
            questions:      questions,
          );

          await _writeToFirestore(uid, attempt);
          await LocalDbService.markSynced(localId);
        } catch (_) {
          // Reset pending so it can retry next time
          await LocalDbService.resetPending(localId);
        }
      }
    } finally {
      _syncing = false;
    }
  }

  static Future<void> _writeToFirestore(
      String uid, ExerciseAttempt attempt) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('progress')
        .add(attempt.toFirestore());
  }

  static Future<bool> _isOnline() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (_) {
      return false;
    }
  }

  static QuestionAttempt _questionFromMap(
      Map<String, dynamic> map) {
    return QuestionAttempt(
      exerciseKey:      map['exerciseKey'] as String,
      exerciseType:     map['exerciseType'] as String,
      isCorrect:        (map['isCorrect'] as int) == 1,
      isSkipped:        (map['isSkipped'] as int) == 1,
      timeSeconds:      map['timeSeconds'] as int,
      replayCount:      map['replayCount'] as int,
      correctAnswer:    map['correctAnswer'] as String,
      userAnswer:       map['userAnswer'] as String,
      noteA:            map['noteA'] as String?,
      noteB:            map['noteB'] as String?,
      noteAString:      map['noteAString'] as int?,
      noteAFret:        map['noteAFret'] as int?,
      noteBString:      map['noteBString'] as int?,
      noteBFret:        map['noteBFret'] as int?,
      semitoneDistance: map['semitoneDistance'] as int?,
      notePlayed:       map['notePlayed'] as String?,
      noteString:       map['noteString'] as int?,
      noteFret:         map['noteFret'] as int?,
    );
  }

  // ─── Full sync on app start ───────────────────────────────────
static Future<void> syncOnStartup(String uid) async {
  final online = await _isOnline();
  if (!online) return;

  // Push any unsynced local records to Firestore
  await syncPending(uid);
  // Push unsynced unlocks
  await ExerciseAccessService.syncPendingUnlocks(uid);

  // Pull Firestore records that aren't in local SQLite
  await _pullFromFirestore(uid);
}

// ─── Pull Firestore records into local SQLite ─────────────────
static Future<void> _pullFromFirestore(String uid) async {
  try {
    // Get all Firestore progress docs
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('progress')
        .get();

    if (snapshot.docs.isEmpty) return;

    // Get all local attempts
    final localAttempts =
        await LocalDbService.getAllAttempts(uid);

    // Build a set of local attempt signatures for comparison
    // Signature = exerciseKey + attemptDate
    final localSignatures = localAttempts
        .map((row) =>
            '${row['exerciseKey']}_${row['attemptDate']}')
        .toSet();

    // For each Firestore doc not in local — write to SQLite
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final key  = data['exerciseKey'] as String? ?? '';
      final date = data['attemptDate'] as String? ?? '';

      if (key.isEmpty || date.isEmpty) continue;

      final signature = '${key}_$date';
      if (localSignatures.contains(signature)) continue;

      // Build ExerciseAttempt from Firestore data
      try {
        final questionsRaw =
            data['questions'] as List<dynamic>? ?? [];
        final questions = questionsRaw
            .map((q) => _questionFromFirestore(
                q as Map<String, dynamic>))
            .toList();

        final attempt = ExerciseAttempt(
          exerciseKey:    key,
          exerciseType:   data['exerciseType'] as String? ?? '',
          attemptDate:    DateTime.parse(date),
          totalQuestions: data['totalQuestions'] as int? ?? 10,
          correct:        data['correct'] as int? ?? 0,
          wrong:          data['wrong'] as int? ?? 0,
          skipped:        data['skipped'] as int? ?? 0,
          synced:         true, // already in Firestore
          questions:      questions,
        );

        // Save to local SQLite as already synced
        await LocalDbService.saveAttemptSynced(
          uid:     uid,
          attempt: attempt,
        );
      } catch (_) {
        // Skip malformed records
      }
    }
  } catch (_) {
    // Silent — sync will retry next time
  }
}

// ─── Build QuestionAttempt from Firestore map ─────────────────
static QuestionAttempt _questionFromFirestore(
    Map<String, dynamic> map) {
  return QuestionAttempt(
    exerciseKey:      map['exerciseKey'] as String? ?? '',
    exerciseType:     map['exerciseType'] as String? ?? '',
    isCorrect:        map['isCorrect'] as bool? ?? false,
    isSkipped:        map['isSkipped'] as bool? ?? false,
    timeSeconds:      map['timeSeconds'] as int? ?? 0,
    replayCount:      map['replayCount'] as int? ?? 0,
    correctAnswer:    map['correctAnswer'] as String? ?? '',
    userAnswer:       map['userAnswer'] as String? ?? '',
    noteA:            map['noteA'] as String?,
    noteB:            map['noteB'] as String?,
    noteAString:      map['noteAString'] as int?,
    noteAFret:        map['noteAFret'] as int?,
    noteBString:      map['noteBString'] as int?,
    noteBFret:        map['noteBFret'] as int?,
    semitoneDistance: map['semitoneDistance'] as int?,
    notePlayed:       map['notePlayed'] as String?,
    noteString:       map['noteString'] as int?,
    noteFret:         map['noteFret'] as int?,
  );
}
}