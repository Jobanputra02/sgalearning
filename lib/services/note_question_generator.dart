import 'dart:math';
import '../models/note_exercise_model.dart';

class NoteQuestionGenerator {
  static final Random _random = Random();

  static const Map<int, int> _baseMidi = {
    1: 64, 2: 59, 3: 55, 4: 50, 5: 45, 6: 40,
  };

  // Build full note pool from given strings
  static List<NoteQuestion> _buildPool(List<int> strings) {
    final pool = <NoteQuestion>[];
    for (final s in strings) {
      final base = _baseMidi[s]!;
      for (int f = 0; f <= 13; f++) {
        final midi = base + f;
        pool.add(NoteQuestion(
          string: s,
          fret: f,
          correctNote: _midiToName(midi),
          midi: midi,
        ));
      }
    }
    return pool;
  }

  // Build pool filtered to specific MIDI values (for new notes)
  static List<NoteQuestion> _buildPoolForMidis(
      List<int> strings, List<int> midiValues) {
    final midiSet = midiValues.toSet();
    final pool = <NoteQuestion>[];
    for (final s in strings) {
      final base = _baseMidi[s]!;
      for (int f = 0; f <= 13; f++) {
        final midi = base + f;
        if (midiSet.contains(midi)) {
          pool.add(NoteQuestion(
            string: s,
            fret: f,
            correctNote: _midiToName(midi),
            midi: midi,
          ));
        }
      }
    }
    return pool;
  }

  static List<NoteQuestion> generate(
      NoteExerciseConfig config, int count) {

    final fullPool = _buildPool(config.strings);

    // Exams or String 1 (no newNotes) — fully random
    if (config.newNotes.isEmpty) {
      return List.generate(
        count,
        (_) => fullPool[_random.nextInt(fullPool.length)],
      );
    }

    // 70/30 split
    final newCount  = (count * 0.7).round(); // 70% from new notes
    final restCount = count - newCount;       // 30% from rest

    // Pool of new note questions
    final newMidis = config.newNotes.map((n) => n.midi).toList();
    final newPool  = _buildPoolForMidis(config.strings, newMidis);

    // Pool of rest (all notes minus new notes)
    final newMidiSet = newMidis.toSet();
    final restPool = fullPool
        .where((q) => !newMidiSet.contains(q.midi))
        .toList();

    final questions = <NoteQuestion>[];

    // Pick from new notes pool (70%)
    if (newPool.isNotEmpty) {
      for (int i = 0; i < newCount; i++) {
        questions.add(newPool[_random.nextInt(newPool.length)]);
      }
    }

    // Pick from rest pool (30%)
    if (restPool.isNotEmpty) {
      for (int i = 0; i < restCount; i++) {
        questions.add(restPool[_random.nextInt(restPool.length)]);
      }
    } else {
      // Fallback if rest pool empty — fill from full pool
      for (int i = 0; i < restCount; i++) {
        questions.add(fullPool[_random.nextInt(fullPool.length)]);
      }
    }

    // Shuffle so 70% and 30% are mixed throughout
    questions.shuffle(_random);
    return questions;
  }

  // Generate single fresh question (for skip)
  static NoteQuestion generateOne(NoteExerciseConfig config) {
    return generate(config, 1).first;
  }

  static const List<String> _noteNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F',
    'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  static String _midiToName(int midi) {
    final note = _noteNames[midi % 12];
    final octave = (midi ~/ 12) - 1;
    return '$note$octave';
  }
}