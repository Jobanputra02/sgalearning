import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import '../models/progress_models.dart';

class LocalDbService {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sga_progress.db');

    return openDatabase(
      path,
      version: 2, // bumped version
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE attempts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uid TEXT NOT NULL,
            exerciseKey TEXT NOT NULL,
            exerciseType TEXT NOT NULL,
            attemptDate TEXT NOT NULL,
            totalQuestions INTEGER NOT NULL,
            correct INTEGER NOT NULL,
            wrong INTEGER NOT NULL,
            skipped INTEGER NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0,
            pending INTEGER NOT NULL DEFAULT 0,
            questionsJson TEXT NOT NULL
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_uid ON attempts (uid)');
        await db.execute(
            'CREATE INDEX idx_exercise ON attempts (uid, exerciseKey)');
        await db.execute(
            'CREATE INDEX idx_synced ON attempts (synced)');
        // Unlock queue table
        await db.execute('''
          CREATE TABLE unlock_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uid TEXT NOT NULL,
            exerciseKey TEXT NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0
          )
      ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add pending column to existing installs
          await db.execute(
              'ALTER TABLE attempts ADD COLUMN pending INTEGER NOT NULL DEFAULT 0');
          if (oldVersion < 3) {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS unlock_queue (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                uid TEXT NOT NULL,
                exerciseKey TEXT NOT NULL,
                synced INTEGER NOT NULL DEFAULT 0
              )
            ''');
          }
        }
      },
    );
  }

  // Save a completed attempt — returns local id
  static Future<int> saveAttempt({
    required String uid,
    required ExerciseAttempt attempt,
  }) async {
    final database = await db;
    return database.insert('attempts', {
      'uid':            uid,
      'exerciseKey':    attempt.exerciseKey,
      'exerciseType':   attempt.exerciseType,
      'attemptDate':    attempt.attemptDate.toIso8601String(),
      'totalQuestions': attempt.totalQuestions,
      'correct':        attempt.correct,
      'wrong':          attempt.wrong,
      'skipped':        attempt.skipped,
      'synced':         0,
      'pending':        0,
      'questionsJson':  jsonEncode(
          attempt.questions.map((q) => q.toMap()).toList()),
    });
  }

  // Get unsynced AND not pending attempts
  static Future<List<Map<String, dynamic>>> getUnsynced(
      String uid) async {
    final database = await db;
    return database.query(
      'attempts',
      where: 'uid = ? AND synced = 0 AND pending = 0',
      whereArgs: [uid],
      orderBy: 'attemptDate ASC',
    );
  }

  // Mark as pending — locked for sync, won't be picked up again
  static Future<void> markPending(int localId) async {
    final database = await db;
    await database.update(
      'attempts',
      {'pending': 1},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  // Mark as synced — final state
  static Future<void> markSynced(int localId) async {
    final database = await db;
    await database.update(
      'attempts',
      {'synced': 1, 'pending': 0},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  // Reset pending — called if sync failed
  static Future<void> resetPending(int localId) async {
    final database = await db;
    await database.update(
      'attempts',
      {'pending': 0},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  // Get all attempts for a user and exercise
  static Future<List<Map<String, dynamic>>> getAttempts({
    required String uid,
    required String exerciseKey,
  }) async {
    final database = await db;
    return database.query(
      'attempts',
      where: 'uid = ? AND exerciseKey = ?',
      whereArgs: [uid, exerciseKey],
      orderBy: 'attemptDate DESC',
    );
  }

  static Future<List<Map<String, dynamic>>> getAllAttempts(
      String uid) async {
    final database = await db;
    return database.query(
      'attempts',
      where: 'uid = ?',
      whereArgs: [uid],
      orderBy: 'attemptDate DESC',
    );
  }
  
  static Future<void> clearAllAttempts(String uid) async {
  final database = await db;
  await database.delete(
    'attempts',
    where: 'uid = ?',
    whereArgs: [uid],
  );
}

  // Save an already-synced attempt (pulled from Firestore)
static Future<void> saveAttemptSynced({
  required String uid,
  required ExerciseAttempt attempt,
}) async {
  final database = await db;

  // Check if already exists by exerciseKey + attemptDate
  final existing = await database.query(
    'attempts',
    where: 'uid = ? AND exerciseKey = ? AND attemptDate = ?',
    whereArgs: [
      uid,
      attempt.exerciseKey,
      attempt.attemptDate.toIso8601String(),
    ],
    limit: 1,
  );

  if (existing.isNotEmpty) return; // already in local db

  await database.insert('attempts', {
    'uid':            uid,
    'exerciseKey':    attempt.exerciseKey,
    'exerciseType':   attempt.exerciseType,
    'attemptDate':    attempt.attemptDate.toIso8601String(),
    'totalQuestions': attempt.totalQuestions,
    'correct':        attempt.correct,
    'wrong':          attempt.wrong,
    'skipped':        attempt.skipped,
    'synced':         1, // already synced
    'pending':        0,
    'questionsJson':  jsonEncode(
        attempt.questions.map((q) => q.toMap()).toList()),
  });
}
// Save a pending unlock
static Future<void> saveUnlock({
  required String uid,
  required String exerciseKey,
}) async {
  final database = await db;

  // Check if already queued
  // final existing = await database.query(
  //   'unlock_queue',
  //   where: 'uid = ? AND exerciseKey = ?',
  //   whereArgs: [uid, exerciseKey],
  //   limit: 1,
  // );
  // if (existing.isNotEmpty) return;

  await database.insert('unlock_queue', {
    'uid':        uid,
    'exerciseKey': exerciseKey,
    'synced':     0,
  });
}

// Get all unsynced unlocks for a user
static Future<List<Map<String, dynamic>>> getUnsyncedUnlocks(
    String uid) async {
  final database = await db;
  return database.query(
    'unlock_queue',
    where: 'uid = ? AND synced = 0',
    whereArgs: [uid],
  );
}

// Mark unlock as synced
static Future<void> markUnlockSynced(int id) async {
  final database = await db;
  await database.update(
    'unlock_queue',
    {'synced': 1},
    where: 'id = ?',
    whereArgs: [id],
  );
}
static Future<void> deleteAttemptByDate({
  required String uid,
  required String exerciseKey,
  required String attemptDate,
}) async {
  final database = await db;
  await database.delete(
    'attempts',
    where:
        'uid = ? AND exerciseKey = ? AND attemptDate = ?',
    whereArgs: [uid, exerciseKey, attemptDate],
  );
}
}