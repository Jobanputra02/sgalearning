import '../models/note_exercise_model.dart';

class NoteExerciseData {
  static const List<String> _noteNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F',
    'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  static String midiToName(int midi) {
    final note = _noteNames[midi % 12];
    final octave = (midi ~/ 12) - 1;
    return '$note$octave';
  }

  static NoteOption midiToOption(int midi) =>
      NoteOption(name: midiToName(midi), midi: midi);

  // static List<NoteOption> _rangeOptions(int from, int to) =>
  //     List.generate(to - from + 1, (i) => midiToOption(from + i));

  static const Map<int, int> _baseMidi = {
    1: 64, 2: 59, 3: 55, 4: 50, 5: 45, 6: 40,
  };

  // All unique MIDI values across given strings, sorted
  static List<NoteOption> _multiStringOptions(List<int> strings) {
    final midiSet = <int>{};
    for (final s in strings) {
      for (int f = 0; f <= 13; f++) {
        midiSet.add(_baseMidi[s]! + f);
      }
    }
    return (midiSet.toList()..sort()).map(midiToOption).toList();
  }

  // Notes unique to newString that weren't in previousStrings
  static List<NoteOption> _newNotes(
      int newString, List<int> previousStrings) {
    final prevMidi = <int>{};
    for (final s in previousStrings) {
      for (int f = 0; f <= 13; f++) {
        prevMidi.add(_baseMidi[s]! + f);
      }
    }
    final newMidi = <int>{};
    for (int f = 0; f <= 13; f++) {
      newMidi.add(_baseMidi[newString]! + f);
    }
    // Notes in newString that don't exist in previous strings
    final unique = newMidi.difference(prevMidi).toList()..sort();
    return unique.map(midiToOption).toList();
  }

  static List<NoteExerciseConfig> get exercises => [

    // ── String 1 — all random, no previous strings ──────────────
    NoteExerciseConfig(
      label: 'String 1 (E)',
      title: 'String 1 – E String',
      strings: [1],
      options: _multiStringOptions([1]),
      newNotes: [], // fully random — first exercise
      accessKey: 'EP_NI_1',
    ),

    // ── String 2 — new notes: B3, C4, C#4, D4, D#4 ──────────────
    // S2 base=59 (B3), S1 base=64 (E4)
    // Unique to S2 = midi 59,60,61,62,63 = B3,C4,C#4,D4,D#4
    NoteExerciseConfig(
      label: 'String 1+2 (E+B)',
      title: 'String 2 – B String',
      strings: [1, 2],
      options: _multiStringOptions([1, 2]),
      newNotes: _newNotes(2, [1]),
      accessKey: 'EP_NI_12',
    ),

    // ── String 3 — new notes: G3, G#3, A3, A#3 ──────────────────
    // S3 base=55 (G3), S2 lowest=59 (B3)
    // Unique to S3 = midi 55,56,57,58 = G3,G#3,A3,A#3
    NoteExerciseConfig(
      label: 'String 1+2+3 (E+B+G)',
      title: 'String 3 – G String',
      strings: [1, 2, 3],
      options: _multiStringOptions([1, 2, 3]),
      newNotes: _newNotes(3, [1, 2]),
      accessKey: 'EP_NI_123',
    ),

    // ── Exam 1 — fully random ────────────────────────────────────
    NoteExerciseConfig(
      label: 'Exam – Strings 1, 2 & 3',
      title: 'Exam – Strings 1, 2 & 3',
      strings: [1, 2, 3],
      options: _multiStringOptions([1, 2, 3]),
      type: NoteExerciseType.exam,
      newNotes: [], // exam = random
      accessKey: 'EP_NI_Exam123',
    ),

    // ── String 4 — new notes: D3, D#3, E3, F3, F#3 ──────────────
    // S4 base=50 (D3), S3 lowest=55 (G3)
    // Unique to S4 = midi 50,51,52,53,54 = D3,D#3,E3,F3,F#3
    NoteExerciseConfig(
      label: 'String 1+2+3+4',
      title: 'String 4 – D String',
      strings: [1, 2, 3, 4],
      options: _multiStringOptions([1, 2, 3, 4]),
      newNotes: _newNotes(4, [1, 2, 3]),
      accessKey: 'EP_NI_1234',
    ),

    // ── String 5 — new notes: A2, A#2, B2, C3, C#3 ──────────────
    // S5 base=45 (A2), S4 lowest=50 (D3)
    // Unique to S5 = midi 45,46,47,48,49 = A2,A#2,B2,C3,C#3
    NoteExerciseConfig(
      label: 'String 1+2+3+4+5',
      title: 'String 5 – A String',
      strings: [1, 2, 3, 4, 5],
      options: _multiStringOptions([1, 2, 3, 4, 5]),
      newNotes: _newNotes(5, [1, 2, 3, 4]),
      accessKey: 'EP_NI_12345',
    ),

    // ── String 6 — new notes: E2, F2, F#2, G2, G#2 ──────────────
    // S6 base=40 (E2), S5 lowest=45 (A2)
    // Unique to S6 = midi 40,41,42,43,44 = E2,F2,F#2,G2,G#2
    NoteExerciseConfig(
      label: 'All 6 Strings',
      title: 'String 6 – Low E String',
      strings: [1, 2, 3, 4, 5, 6],
      options: _multiStringOptions([1, 2, 3, 4, 5, 6]),
      newNotes: _newNotes(6, [1, 2, 3, 4, 5]),
      accessKey: 'EP_NI_123456',
    ),

    // ── Exam 2 — fully random ────────────────────────────────────
    NoteExerciseConfig(
      label: 'Exam – All 6 Strings',
      title: 'Exam – All 6 Strings',
      strings: [1, 2, 3, 4, 5, 6],
      options: _multiStringOptions([1, 2, 3, 4, 5, 6]),
      type: NoteExerciseType.exam,
      newNotes: [], // exam = random
      accessKey: 'EP_NI_Exam123456',
    ),
  ];
}