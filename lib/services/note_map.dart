import '../models/pitch_exercise_model.dart';

class NoteMap {
  static const Map<int, int> _stringBaseMidi = {
    1: 64, 2: 59, 3: 55, 4: 50, 5: 45, 6: 40,
  };

  static const List<String> _noteNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F',
    'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  static String _midiToName(int midi) {
    final note = _noteNames[midi % 12];
    final octave = (midi ~/ 12) - 1;
    return '$note$octave';
  }

  static NoteModel getNote(int string, int fret) {
    final midi = _stringBaseMidi[string]! + fret;
    return NoteModel(
      string: string,
      fret: fret,
      name: _midiToName(midi),
      midi: midi,
    );
  }

  static List<NoteModel> getStringNotes(int string) {
    return List.generate(14, (fret) => getNote(string, fret));
  }

  static List<NoteModel> getMultiStringNotes(List<int> strings) {
    final notes = <NoteModel>[];
    for (final s in strings) {
      notes.addAll(getStringNotes(s));
    }
    return notes;
  }
}