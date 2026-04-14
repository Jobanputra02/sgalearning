import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/exercise_access_model.dart';
import '../../services/student_analytics_service.dart';
import '../../services/exercise_access_service.dart';
import '../../services/local_db_service.dart';
import '../../theme/app_theme.dart';

class StudentProfileScreen extends StatefulWidget {
  final StudentAnalytics analytics;
  final bool isStudentView; // true = student viewing own progress

  const StudentProfileScreen({
    super.key,
    required this.analytics,
    this.isStudentView = false,
  });

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  late StudentAnalytics _a;
  ExerciseAccess? _access;
  // bool _loadingAccess = true;
  bool _hasInternet = true;
  bool _loadingData = false;

  @override
  void initState() {
    super.initState();
    _a = widget.analytics;
    _loadAccess();
  }

  Future<void> _loadAccess() async {
    try {
      final access =
          await ExerciseAccessService.getAccess(_a.student.uid, 'student');
      if (mounted) {
        setState(() {
          _access = access;
          // _loadingAccess = false;
          _hasInternet = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          // _loadingAccess = false;
          _hasInternet = false;
        });
      }
    }
  }

  Future<void> _reload() async {
    setState(() => _loadingData = true);
    try {
      final fresh = await StudentAnalyticsService.compute(_a.student);
      final access =
          await ExerciseAccessService.getAccess(_a.student.uid, 'student');
      if (mounted) {
        setState(() {
          _a = fresh;
          _access = access;
          _hasInternet = true;
          _loadingData = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasInternet = false;
          _loadingData = false;
        });
      }
    }
  }

  Color get _statusColor {
    switch (_a.status) {
      case StudentStatus.needsAttention:
        return Colors.red;
      case StudentStatus.monitor:
        return Colors.orange;
      case StudentStatus.onTrack:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Progress'),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.navy,
        elevation: 0,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.refresh),
        //     onPressed: _reload,
        //   ),
        // ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderColor),
        ),
      ),
      body: _loadingData
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : RefreshIndicator(
              onRefresh: _reload,
              color: AppTheme.accent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // No internet banner
                    if (!_hasInternet) _NoInternetBanner(onRetry: _reload),
                    if (!_hasInternet) const SizedBox(height: 12),

                    // Header
                    _buildHeader(),
                    const SizedBox(height: 16),

                    // Streak
                    // _StreakWidget(
                    //     streak: _a.streakData),
                    // const SizedBox(height: 16),

                    // Pitch progress
                    _SectionHeader(title: 'Pitch Identification'),
                    const SizedBox(height: 8),
                    _ProgressCard(
                      label: 'Pitch Progress',
                      pct: _a.pitchOverallPct,
                      unlocked: _a.pitchUnlocked,
                      total: 20,
                      color: AppTheme.pitchGradient[0],
                      onTap: () => _push(
                        _ExerciseScorecardScreen(
                          title: 'Pitch Exercises',
                          scores: _a.pitchScores,
                          access: _access,
                          student: _a.student,
                          isStudentView: widget.isStudentView,
                          onChanged: _reload,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // // Speed vs accuracy pitch
                    // if (_a.pitchSpeedAccuracy != null)
                    //   _SpeedAccuracyCard(
                    //     data: _a.pitchSpeedAccuracy!,
                    //     label: 'Pitch',
                    //   ),
                    // if (_a.pitchSpeedAccuracy != null)
                    //   const SizedBox(height: 8),

                    // Semitone chart
                    if (_a.pitchAccuracyBySemitone.isNotEmpty) ...[
                      _TapCard(
                        title: 'Accuracy by Semitone Distance',
                        subtitle: _semitoneSubtitle(),
                        icon: Icons.multiline_chart,
                        onTap: () => _push(
                          _SemitoneChartScreen(
                            accuracyData: _a.pitchAccuracyBySemitone,
                            timeData: _a.pitchAvgTimeBySemitone,
                            attemptsData: _a.pitchAttemptsBySemitone,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Note progress
                    _SectionHeader(title: 'Note Identification'),
                    const SizedBox(height: 8),
                    _ProgressCard(
                      label: 'Note Progress',
                      pct: _a.noteOverallPct,
                      unlocked: _a.noteUnlocked,
                      total: 8,
                      color: AppTheme.noteGradient[0],
                      onTap: () => _push(
                        _ExerciseScorecardScreen(
                          title: 'Note Exercises',
                          scores: _a.noteScores,
                          access: _access,
                          student: _a.student,
                          isStudentView: widget.isStudentView,
                          onChanged: _reload,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Speed vs accuracy note
                    // if (_a.noteSpeedAccuracy != null)
                    //   _SpeedAccuracyCard(
                    //     data:  _a.noteSpeedAccuracy!,
                    //     label: 'Note',
                    //   ),
                    // if (_a.noteSpeedAccuracy != null)
                    //   const SizedBox(height: 8),

                    // Note by string/note chart
                    if (_a.noteAccuracyByString.isNotEmpty) ...[
                      _TapCard(
                        title: 'Accuracy by String/Notes',
                        subtitle: _stringSubtitle(),
                        icon: Icons.bar_chart,
                        onTap: () => _push(
                          _NoteAccuracyChartScreen(
                            byString: _a.noteAccuracyByString,
                            byNote: _a.noteAccuracyByNote,
                            timeByString: _a.noteAvgTimeByString,
                            timeByNote: _a.noteAvgTimeByNote,
                            attemptsByString: _a.noteAttemptsByString,
                            attemptsByNote: _a.noteAttemptsByNote,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Note confusion
                    if (_a.noteConfusionGroups.isNotEmpty) ...[
                      _TapCard(
                        title: 'Note Confusion',
                        subtitle: _confusionSubtitle(),
                        icon: Icons.swap_horiz,
                        onTap: () => _push(
                          _ConfusionScreen(groups: _a.noteConfusionGroups),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Stuck
                    if (_a.stuckExercises.isNotEmpty) ...[
                      _SectionHeader(title: 'Needs Attention'),
                      const SizedBox(height: 8),
                      _StuckCard(stuckKeys: _a.stuckExercises),
                      const SizedBox(height: 8),
                    ],

                    // Interval modules
                    _SectionHeader(title: 'Interval Comparison'),
                    const SizedBox(height: 8),
                    _ComingSoonCard(),
                    const SizedBox(height: 16),

                    _SectionHeader(title: 'Interval Identification'),
                    const SizedBox(height: 8),
                    _ComingSoonCard(),
                    const SizedBox(height: 16),

                    // All attempts
                    _SectionHeader(title: 'All Attempts'),
                    const SizedBox(height: 8),
                    _TapCard(
                      title: _attemptsTitle(),
                      subtitle: _attemptsSubtitle(),
                      icon: Icons.history,
                      onTap: () => _push(
                        _AllAttemptsScreen(
                          attempts: _a.allAttemptRecords,
                          student: _a.student,
                          isStudentView: widget.isStudentView,
                          onDeleted: _reload,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  void _push(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => _reload());
  }

  Widget _buildHeader() {
    final s = _a.student;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border:
                  Border.all(color: _statusColor.withOpacity(0.3), width: 2),
            ),
            child: Center(
              child: Text(
                s.firstName.isNotEmpty ? s.firstName[0].toUpperCase() : '?',
                style: TextStyle(
                    color: _statusColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.fullName,
                    style: const TextStyle(
                        color: AppTheme.navy,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(s.branch,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: _statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _a.verdictLine,
                        style: TextStyle(
                            color: _statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _semitoneSubtitle() {
    final d = _a.pitchAccuracyBySemitone;
    final att = _a.pitchAttemptsBySemitone;
    if (d.isEmpty) return 'No data yet';

    // Check reliable semitones (>10 attempts, <50% accuracy)
    final weak = d.entries
        .where((e) => (att[e.key] ?? 0) > 10 && e.value < 0.5)
        .map((e) => e.key)
        .toList()
      ..sort();

    if (weak.isNotEmpty) {
      final label = weak.take(2).map((k) => '$k').join(' and ');
      return '⚠️ Weakest semitone distance: $label';
    }

    // Check by difficulty groups
    final easy = [9, 10, 11, 12, 13];
    final medium = [5, 6, 7, 8];
    final hard = [1, 2, 3, 4];

    String? diffWarning;

    for (final entry in [
      ('Easy', easy, '9–13'),
      ('Medium', medium, '5–8'),
      ('Hard', hard, '1–4'),
    ]) {
      final name = entry.$1;
      final keys = entry.$2;
      final range = entry.$3;
      final vals =
          keys.where((k) => d.containsKey(k)).map((k) => d[k]!).toList();
      if (vals.isEmpty) continue;
      final avg = vals.reduce((a, b) => a + b) / vals.length;
      if (avg < 0.7) {
        diffWarning = '⚠️ $name: ${(avg * 100).round()}% at $range semitones';
        break;
      }
    }

    if (diffWarning != null) return diffWarning;

    // Overall average
    final overall = d.values.reduce((a, b) => a + b) / d.length;
    if (overall > 0.9) return '✅ Excellent Progress';
    if (overall > 0.7) return '✅ Good Progress';
    return '⚠️ Needs improvement';
  }

  String _stringSubtitle() {
    final byNote = _a.noteAccuracyByNote;
    final byString = _a.noteAccuracyByString;

    if (byNote.isEmpty && byString.isEmpty) {
      return 'No data yet';
    }

    // Find weak notes: >5 attempts implied by having data,
    // accuracy <50%
    // We estimate attempts from byNote having entries
    final weakNotes =
        byNote.entries.where((e) => e.value < 0.5).map((e) => e.key).toList();

    if (weakNotes.length > 3) {
      // Check if they all lie in same string
      // Map note names to strings
      final noteToString = _buildNoteToStringMap();
      final strings =
          weakNotes.map((n) => noteToString[n]).whereType<int>().toSet();
      if (strings.length == 1) {
        final s = strings.first;
        final acc = byString[s] ?? 0.0;
        return '⚠️ Weakest: String $s '
            '(${(acc * 100).round()}%)';
      }
      return '⚠️ Weak notes: '
          '${weakNotes.take(3).join(', ')}...';
    }

    if (weakNotes.isNotEmpty) {
      return '⚠️ Weak notes: ${weakNotes.take(3).join(', ')}';
    }

    if (byString.isEmpty) return 'No data yet';
    final worst = byString.entries.reduce((a, b) => a.value < b.value ? a : b);
    return '⚠️ Weakest: String ${worst.key} '
        '(${(worst.value * 100).round()}%)';
  }

  Map<String, int> _buildNoteToStringMap() {
    // Map each note name to its primary string
    const map = <String, int>{'E4': 1,'F4': 1,'F#4': 1,'G4': 1,'G#4': 1,'A4': 1,'A#4': 1,'B4': 1,'C5': 1,'C#5': 1,'D5': 1,'D#5': 1,'E5': 1,'F5': 1,'B3': 2,'C4': 2,'C#4': 2,'D4': 2,'D#4': 2,'G3': 3,'G#3': 3,'A3': 3,'A#3': 3,'D3': 4,'D#3': 4,'E3': 4,'F3': 4,'F#3': 4,'A2': 5,'A#2': 5,'B2': 5,'C3': 5,'C#3': 5,'E2': 6,'F2': 6,'F#2': 6,'G2': 6,'G#2': 6,};
    return map;
  }

  String _confusionSubtitle() {
    final g = _a.noteConfusionGroups;
    if (g.isEmpty) return 'No confusion detected';
    final top = g.first;
    final notes = top.entries.take(2).map((e) => e.answered).join(', ');
    return '⚠️ ${top.correctNote} confused with $notes';
  }

  String _attemptsSubtitle() {
    final n = _a.totalAttempts;
    if (n == 0) return 'No attempts yet';
    if (_a.lastActive == null) return 'Total: $n attempts';

    // Find oldest attempt
    final oldest = _a.allAttemptRecords.isEmpty
        ? DateTime.now()
        : _a.allAttemptRecords.last.date;
    final diff = DateTime.now().difference(oldest).inDays;

    String since;
    if (diff < 7) {
      since = '${diff == 0 ? 'today' : '$diff day${diff > 1 ? 's' : ''}'}';
    } else if (diff < 30) {
      final w = (diff / 7).ceil();
      since = '$w week${w > 1 ? 's' : ''}';
    } else if (diff < 365) {
      final m = (diff / 30).ceil();
      since = '$m month${m > 1 ? 's' : ''}';
    } else {
      final y = (diff / 365).ceil();
      since = '$y year${y > 1 ? 's' : ''}';
    }

    return 'Total $n attempts since $since';
  }

  String _attemptsTitle() {
    final n = _a.totalAttempts;
    if (n == 0) return '0 attempts';
    if (_a.lastActive == null) return '$n attempts';

    final diff =
        DateTime.now().difference(_a.allAttemptRecords.last.date).inDays;

    if (diff < 7) return '$n attempts this week';
    if (diff < 30) {
      final weeks = (diff / 7).ceil();
      return '$n attempts in $weeks week${weeks > 1 ? 's' : ''}';
    }
    if (diff < 365) {
      final months = (diff / 30).ceil();
      return '$n attempts in $months month${months > 1 ? 's' : ''}';
    }
    final years = (diff / 365).ceil();
    return '$n attempts in $years year${years > 1 ? 's' : ''}';
  }
}

// ─── No Internet Banner ───────────────────────────────────────────
class _NoInternetBanner extends StatelessWidget {
  final VoidCallback onRetry;
  const _NoInternetBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Internet required for analytics. '
              'Showing cached data.',
              style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text('Retry',
                style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─── Streak Widget ────────────────────────────────────────────────
// class _StreakWidget extends StatelessWidget {
//   final StreakData streak;
//   const _StreakWidget({required this.streak});

//   Color _cellColor(int intensity) {
//     switch (intensity) {
//       case 1:  return const Color(0xFFC6F0C2); // light green
//       case 2:  return const Color(0xFF4CAF50); // medium
//       case 3:  return const Color(0xFF1B5E20); // dark
//       default: return AppTheme.borderColor;    // no practice
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final days = streak.last28Days;
//     if (days.isEmpty) return const SizedBox();

//     // Group into 4 weeks of 7 days
//     const weekLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

//     // Get week numbers
//     String _weekLabel(DateTime day) {
//       final weekNum =
//           ((day.difference(DateTime(day.year, 1, 1))
//                           .inDays) /
//                       7)
//                   .ceil() +
//               1;
//       return 'W$weekNum';
//     }

//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: AppTheme.white,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: AppTheme.borderColor),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment:
//                 MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 'Practice Streak',
//                 style: TextStyle(
//                     color: AppTheme.navy,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14),
//               ),
//               Row(
//                 children: [
//                   const Icon(Icons.local_fire_department,
//                       color: Colors.orange, size: 18),
//                   const SizedBox(width: 4),
//                   Text(
//                     '${streak.currentStreak} day streak',
//                     style: const TextStyle(
//                         color: Colors.orange,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 13),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),

//           // Day labels MTWTFSS
//           Row(
//             children: [
//               const SizedBox(width: 28), // space for week label
//               ...weekLabels.map((l) => Expanded(
//                     child: Center(
//                       child: Text(l,
//                           style: const TextStyle(
//                               color:
//                                   AppTheme.textSecondary,
//                               fontSize: 10)),
//                     ),
//                   )),
//             ],
//           ),
//           const SizedBox(height: 4),

//           // 4 weeks of boxes
//           ...List.generate(4, (weekIdx) {
//             final weekDays = days.sublist(
//                 weekIdx * 7,
//                 (weekIdx + 1) * 7);
//             final weekLabel =
//                 _weekLabel(weekDays.first.date);

//             return Padding(
//               padding:
//                   const EdgeInsets.only(bottom: 3),
//               child: Row(
//                 children: [
//                   SizedBox(
//                     width: 28,
//                     child: Text(weekLabel,
//                         style: const TextStyle(
//                             color:
//                                 AppTheme.textSecondary,
//                             fontSize: 9)),
//                   ),
//                   ...weekDays.map((pd) => Expanded(
//                         child: Padding(
//                           padding:
//                               const EdgeInsets.all(1.5),
//                           child: AspectRatio(
//                             aspectRatio: 1,
//                             child: Tooltip(
//                               message:
//                                   '${pd.date.day}/${pd.date.month}'
//                                   ' — ${pd.attemptCount} sessions',
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   color: _cellColor(
//                                       pd.intensity),
//                                   borderRadius:
//                                       BorderRadius.circular(
//                                           3),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       )),
//                 ],
//               ),
//             );
//           }),

//           const SizedBox(height: 8),
//           // Legend
//           Row(
//             children: [
//               const SizedBox(width: 28),
//               const Text('Less ',
//                   style: TextStyle(
//                       color: AppTheme.textSecondary,
//                       fontSize: 10)),
//               ...[0, 1, 2, 3].map((i) => Container(
//                     width: 12,
//                     height: 12,
//                     margin:
//                         const EdgeInsets.symmetric(
//                             horizontal: 1),
//                     decoration: BoxDecoration(
//                       color: _cellColor(i),
//                       borderRadius:
//                           BorderRadius.circular(2),
//                       border: i == 0
//                           ? Border.all(
//                               color: AppTheme.borderColor)
//                           : null,
//                     ),
//                   )),
//               const Text(' More',
//                   style: TextStyle(
//                       color: AppTheme.textSecondary,
//                       fontSize: 10)),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// ─── Speed vs Accuracy Card ───────────────────────────────────────
// class _SpeedAccuracyCard extends StatelessWidget {
//   final SpeedAccuracyData data;
//   final String label;

//   const _SpeedAccuracyCard({
//     required this.data,
//     required this.label,
//   });

//   Color get _quadrantColor {
//     switch (data.quadrant) {
//       case 'Mastery':
//         return Colors.green;
//       case 'Learning':
//         return AppTheme.accent;
//       case 'Guessing':
//         return Colors.orange;
//       default:
//         return Colors.red;
//     }
//   }

//   IconData get _quadrantIcon {
//     switch (data.quadrant) {
//       case 'Mastery':
//         return Icons.stars;
//       case 'Learning':
//         return Icons.school;
//       case 'Guessing':
//         return Icons.casino;
//       default:
//         return Icons.help_outline;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final accPct = (data.accuracy * 100).round();
//     final avgT = data.avgTime.toStringAsFixed(1);

//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: _quadrantColor.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: _quadrantColor.withOpacity(0.3)),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 44,
//             height: 44,
//             decoration: BoxDecoration(
//               color: _quadrantColor.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(_quadrantIcon, color: _quadrantColor, size: 24),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   '$label: ${data.quadrant}',
//                   style: TextStyle(
//                       color: _quadrantColor,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 14),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   data.description,
//                   style: const TextStyle(
//                       color: AppTheme.textSecondary, fontSize: 12),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Accuracy: $accPct% · Avg time: ${avgT}s',
//                   style: TextStyle(
//                       color: _quadrantColor,
//                       fontSize: 11,
//                       fontWeight: FontWeight.w600),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// ─── Progress Card ────────────────────────────────────────────────
class _ProgressCard extends StatelessWidget {
  final String label;
  final double pct;
  final int unlocked;
  final int total;
  final Color color;
  final VoidCallback onTap;

  const _ProgressCard({
    required this.label,
    required this.pct,
    required this.unlocked,
    required this.total,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pctInt = (pct * 100).round();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppTheme.navy,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                Row(
                  children: [
                    Text('$unlocked/$total unlocked',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right,
                        size: 16, color: AppTheme.textSecondary),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      backgroundColor: AppTheme.borderColor,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('$pctInt%',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tap Card ─────────────────────────────────────────────────────
class _TapCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _TapCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppTheme.navy,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppTheme.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── Stuck Card ───────────────────────────────────────────────────
class _StuckCard extends StatelessWidget {
  final List<String> stuckKeys;
  const _StuckCard({required this.stuckKeys});

  static const _all = {
    'EP_PI_1E': 'Pitch - String 1 Easy',
    'EP_PI_1M': 'Pitch - String 1 Medium',
    'EP_PI_1H': 'Pitch - String 1 Hard',
    'EP_PI_2E': 'Pitch - String 2 Easy',
    'EP_PI_2M': 'Pitch - String 2 Medium',
    'EP_PI_2H': 'Pitch - String 2 Hard',
    'EP_PI_3E': 'Pitch - String 3 Easy',
    'EP_PI_3M': 'Pitch - String 3 Medium',
    'EP_PI_3H': 'Pitch - String 3 Hard',
    'EP_PI_Exam123': 'Pitch - Exam 1-3',
    'EP_PI_4E': 'Pitch - String 4 Easy',
    'EP_PI_4M': 'Pitch - String 4 Medium',
    'EP_PI_4H': 'Pitch - String 4 Hard',
    'EP_PI_5E': 'Pitch - String 5 Easy',
    'EP_PI_5M': 'Pitch - String 5 Medium',
    'EP_PI_5H': 'Pitch - String 5 Hard',
    'EP_PI_6E': 'Pitch - String 6 Easy',
    'EP_PI_6M': 'Pitch - String 6 Medium',
    'EP_PI_6H': 'Pitch - String 6 Hard',
    'EP_PI_Exam123456': 'Pitch - All Strings Exam',
    'EP_NI_1': 'Note - String 1',
    'EP_NI_12': 'Note - String 1+2',
    'EP_NI_123': 'Note - String 1+2+3',
    'EP_NI_Exam123': 'Note - Exam 1-3',
    'EP_NI_1234': 'Note - String 1+2+3+4',
    'EP_NI_12345': 'Note - String 1+2+3+4+5',
    'EP_NI_123456': 'Note - All Strings',
    'EP_NI_Exam123456': 'Note - All Strings Exam',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: stuckKeys.map((key) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.red, size: 15),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Stuck: ${_all[key] ?? key}'
                    ' (3+ failed attempts)',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Coming Soon Card ─────────────────────────────────────────────
class _ComingSoonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: const Row(
        children: [
          Icon(Icons.hourglass_empty, color: AppTheme.textSecondary, size: 20),
          SizedBox(width: 10),
          Text(
            'Analytics coming soon',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppTheme.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                color: AppTheme.navy,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DRILL DOWN SCREENS
// ═══════════════════════════════════════════════════════════════════

// ─── Exercise Scorecard ───────────────────────────────────────────
class _ExerciseScorecardScreen extends StatefulWidget {
  final String title;
  final List<ExerciseScore> scores;
  final ExerciseAccess? access;
  final UserModel student;
  final bool isStudentView;
  final VoidCallback onChanged;

  const _ExerciseScorecardScreen({
    required this.title,
    required this.scores,
    required this.access,
    required this.student,
    required this.isStudentView,
    required this.onChanged,
  });

  @override
  State<_ExerciseScorecardScreen> createState() =>
      _ExerciseScorecardScreenState();
}

class _ExerciseScorecardScreenState extends State<_ExerciseScorecardScreen> {
  late ExerciseAccess? _access;
  bool _saving = false;
  String? _expandedKey;

  @override
  void initState() {
    super.initState();
    _access = widget.access;
  }

  Future<void> _toggleUnlock(String key, bool current) async {
    setState(() => _saving = true);
    try {
      await ExerciseAccessService.setAccess(widget.student.uid, key, !current);
      final fresh =
          await ExerciseAccessService.getAccess(widget.student.uid, 'student');
      if (mounted) {
        setState(() => _access = fresh);
        widget.onChanged();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to update'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteAttempt(AttemptRecord attempt, String exerciseKey) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Attempt',
            style:
                TextStyle(color: AppTheme.navy, fontWeight: FontWeight.bold)),
        content: const Text(
          'This attempt cannot be recovered later. '
          'Confirm delete?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await StudentAnalyticsService.deleteAttempt(
        studentUid: widget.student.uid,
        firestoreId: attempt.firestoreId,
      );
      // Also delete from local SQLite
      await LocalDbService.deleteAttemptByDate(
        uid: widget.student.uid,
        exerciseKey: exerciseKey,
        attemptDate: attempt.date.toIso8601String(),
      );
      // setState(() {
      //   _attempts.removeWhere((a) => a.firestoreId == attempt.firestoreId);
      // });
      widget.onChanged();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to delete'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.navy,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderColor),
        ),
      ),
      body: _saving
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.scores.length,
              itemBuilder: (_, i) {
                final score = widget.scores[i];
                final isUnlocked =
                    _access?.hasAccess(score.exerciseKey) ?? false;
                final isExpanded = _expandedKey == score.exerciseKey;
                final pct = score.percentage;
                final pctColor = pct >= 0.8
                    ? Colors.green
                    : pct >= 0.6
                        ? Colors.orange
                        : Colors.red;

                return Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _expandedKey = isExpanded ? null : score.exerciseKey;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 0),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? AppTheme.white
                              : AppTheme.cardBackground,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: Radius.circular(isExpanded ? 0 : 12),
                            bottomRight: Radius.circular(isExpanded ? 0 : 12),
                          ),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          children: [
                            // Lock toggle (faculty only)
                            if (!widget.isStudentView)
                              GestureDetector(
                                onTap: () => _toggleUnlock(
                                    score.exerciseKey, isUnlocked),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: isUnlocked
                                        ? AppTheme.accent.withOpacity(0.1)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isUnlocked
                                          ? AppTheme.accent.withOpacity(0.3)
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Icon(
                                    isUnlocked ? Icons.lock_open : Icons.lock,
                                    size: 16,
                                    color: isUnlocked
                                        ? AppTheme.accent
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            if (!widget.isStudentView)
                              const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(score.label,
                                      style: TextStyle(
                                          color: isUnlocked
                                              ? AppTheme.navy
                                              : AppTheme.textSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(
                                    score.attemptCount == 0
                                        ? '0 attempts'
                                        : '${score.attemptCount} attempt${score.attemptCount > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            if (score.attemptCount > 0)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: pctColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: pctColor.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      '${score.bestCorrect}/${score.totalQuestions}',
                                      style: TextStyle(
                                          color: pctColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '..in #${score.bestAttemptNumber} attempts',
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 10),
                                  ),
                                ],
                              ),
                            const SizedBox(width: 6),
                            Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: AppTheme.textSecondary,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Expanded attempts
                    if (isExpanded)
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: score.attempts.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('No attempts yet',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12)),
                              )
                            : Column(
                                children: score.attempts
                                    .map((attempt) => _AttemptTile(
                                          attempt: attempt,
                                          label: score.label,
                                          exerciseKey: score.exerciseKey,
                                          isStudentView: widget.isStudentView,
                                          onDelete: () => _deleteAttempt(
                                              attempt, score.exerciseKey),
                                        ))
                                    .toList(),
                              ),
                      ),
                    const SizedBox(height: 10),
                  ],
                );
              },
            ),
    );
  }
}

// ─── Attempt Tile ─────────────────────────────────────────────────
class _AttemptTile extends StatefulWidget {
  final AttemptRecord attempt;
  final String exerciseKey;
  final bool isStudentView;
  final String label;
  final VoidCallback onDelete;

  const _AttemptTile({
    required this.attempt,
    required this.exerciseKey,
    required this.isStudentView,
    required this.label,
    required this.onDelete,
  });

  @override
  State<_AttemptTile> createState() => _AttemptTileState();
}

class _AttemptTileState extends State<_AttemptTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.attempt;
    final pct = (a.percentage * 100).round();
    final color = pct >= 80
        ? Colors.green
        : pct >= 60
            ? Colors.orange
            : Colors.red;
    final df = DateFormat('dd MMM yyyy  HH:mm');

    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
              Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: const TextStyle(
                            color: AppTheme.navy,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        df.format(a.date),
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11),
                      ),
                      Text(
                        '${a.correct} correct · '
                        '${a.correct} correct · '
                        '${a.wrong} wrong · '
                        '${a.skipped} skipped',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${a.correct}/${a.totalQuestions}',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 11),
                  ),
                ),
                if (!widget.isStudentView) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: widget.onDelete,
                    child: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 18),
                  ),
                ],
                const SizedBox(width: 4),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: AppTheme.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),

        // Question details
        if (_expanded)
          Container(
            color: Colors.white,
            child: Column(
              children: [
                const Divider(height: 1, color: AppTheme.borderColor),
                // Header
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 3,
                          child: Text('Question',
                              style: TextStyle(
                                  color: AppTheme.navy,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold))),
                      Expanded(
                          flex: 2,
                          child: Text('Given Answer',
                              style: TextStyle(
                                  color: AppTheme.navy,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold))),
                      SizedBox(
                          width: 40,
                          child: Text('Time',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppTheme.navy,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                ...a.questions.asMap().entries.map((entry) {
                  final qi = entry.key + 1;
                  final q = entry.value;
                  final qColor = q.isSkipped
                      ? Colors.orange
                      : q.isCorrect
                          ? Colors.green
                          : Colors.red;
                  final qLabel = q.noteA != null
                      ? '${q.noteA} vs ${q.noteB}'
                      : q.notePlayed ?? q.correctAnswer;

                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    color: qi.isOdd ? AppTheme.cardBackground : Colors.white,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            '$qLabel',
                            // 'Q$qi: $qLabel',
                            style: const TextStyle(
                                color: AppTheme.navy, fontSize: 11),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            q.isSkipped
                                ? 'Skipped'
                                : q.isCorrect
                                    ? '✓ ${q.userAnswer}'
                                    : '✗ ${q.userAnswer}\n→ ${q.correctAnswer}',
                            style: TextStyle(color: qColor, fontSize: 11),
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${q.timeSeconds}s',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 4),
              ],
            ),
          ),
        const Divider(height: 1, color: AppTheme.borderColor),
      ],
    );
  }
}

// ─── Semitone Chart Screen ────────────────────────────────────────
class _SemitoneChartScreen extends StatefulWidget {
  final Map<int, double> accuracyData;
  final Map<int, double> timeData;
  final Map<int, int> attemptsData;

  const _SemitoneChartScreen({
    required this.accuracyData,
    required this.timeData,
    required this.attemptsData,
  });

  @override
  State<_SemitoneChartScreen> createState() => _SemitoneChartScreenState();
}

class _SemitoneChartScreenState extends State<_SemitoneChartScreen> {
  int? _touched;

  @override
  @override
  Widget build(BuildContext context) {
    final entries = List.generate(13, (i) {
      final d = i + 1;
      return MapEntry(d, widget.accuracyData[d] ?? 0.0);
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Accuracy by Semitone Distance'),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.navy,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderColor),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          children: [
            // Fixed tooltip area — always same height, no shift
            SizedBox(
              height: 72,
              child: _touched == null
                  ? Center(
                      child: Text(
                        'Tap a bar to see details',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.navy,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Semitone Distance: $_touched',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Accuracy: ${((widget.accuracyData[_touched] ?? 0) * 100).round()}%'
                            '   Avg Time: ${(widget.timeData[_touched] ?? 0).toStringAsFixed(1)}s'
                            '   Attempts: ${widget.attemptsData[_touched] ?? 0}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 8),

            // Chart — fixed size, never shifts
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 1.0,
                  barTouchData: BarTouchData(
                    touchCallback: (event, response) {
                      if (response?.spot != null) {
                        setState(() {
                          _touched = response!.spot!.touchedBarGroup.x + 1;
                        });
                      } else if (event is FlTapUpEvent ||
                          event is FlPanEndEvent) {
                        setState(() => _touched = null);
                      }
                    },
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.transparent,
                      getTooltipItem: (_, __, ___, ____) => null,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Semitone Distance',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ),
                      axisNameSize: 24,
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, _) => Text(
                          '${val.toInt() + 1}',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 10),
                        ),
                        reservedSize: 22,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text(
                        'Avg Accuracy',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11),
                      ),
                      axisNameSize: 20,
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, _) => Text(
                          '${(val * 100).round()}%',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 9),
                        ),
                        reservedSize: 36,
                        interval: 0.25,
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 0.25,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppTheme.borderColor,
                      strokeWidth: 1,
                    ),
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(entries.length, (i) {
                    final dist = entries[i].key;
                    final val = entries[i].value;
                    final hasData = widget.accuracyData.containsKey(dist);
                    final isTouched = _touched == dist;
                    Color barColor;
                      if (!hasData) {
                        barColor = Colors.transparent;
                      } else if (dist >= 1 && dist <= 4) {
                        barColor = isTouched ? Colors.redAccent.shade200 : Colors.red.shade200;
                      } else if (dist >= 5 && dist <= 8) {
                        barColor = isTouched ? Colors.yellowAccent.shade200 : Colors.yellow.shade200;
                      } else {
                        barColor = isTouched ? Colors.greenAccent.shade200 : Colors.green.shade200;
                      }

                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: hasData ? val.clamp(0.0, 1.0) : 0,
                          color: barColor,
                          width: 18,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Note Accuracy Chart Screen ───────────────────────────────────
class _NoteAccuracyChartScreen extends StatefulWidget {
  final Map<int, double> byString;
  final Map<String, double> byNote;
  final Map<int, double> timeByString;
  final Map<String, double> timeByNote;
  final Map<int, int> attemptsByString;
  final Map<String, int> attemptsByNote; // ← add

  const _NoteAccuracyChartScreen({
    required this.byString,
    required this.byNote,
    required this.timeByString,
    required this.timeByNote,
    required this.attemptsByString,
    required this.attemptsByNote,
  });

  @override
  State<_NoteAccuracyChartScreen> createState() =>
      _NoteAccuracyChartScreenState();
}

class _NoteAccuracyChartScreenState extends State<_NoteAccuracyChartScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int? _touchedString;
  String? _touchedNote;

  // All 37 unique notes from low E to high E in order
  static const _noteOrder = ['E2','F2','F#2','G2','G#2','A2','A#2','B2','C3','C#3','D3','D#3','E3','F3','F#3','G3','G#3','A3','A#3','B3','C4','C#4','D4','D#4','E4','F4','F#4','G4','G#4','A4','A#4','B4','C5','C#5','D5','D#5','E5','F5',];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Accuracy by String/Notes'),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.navy,
        elevation: 0,
        bottom: TabBar(
          controller: _tab,
          labelColor: AppTheme.navy,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.accent,
          tabs: const [
            Tab(text: 'By String'),
            Tab(text: 'By Note'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildStringChart(),
          _buildNoteChart(),
        ],
      ),
    );
  }

  Widget _buildStringChart() {
    final strings = List.generate(6, (i) => i + 1);

    return GestureDetector(
      onPanUpdate: (details) {
        // Find which string is under finger
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final localY = details.localPosition.dy - 120; // offset for header
        const itemHeight = 28.0; // padding(10) + bar(18)
        final idx = (localY / itemHeight).floor();
        if (idx >= 0 && idx < strings.length) {
          setState(() => _touchedString = strings[idx]);
        }
      },
      onPanEnd: (_) => setState(() => _touchedString = null),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed tooltip area
            SizedBox(
              height: 56,
              child: _touchedString == null
                  ? const SizedBox()
                  : _buildTooltip(
                      label: 'String $_touchedString',
                      accuracy: widget.byString[_touchedString] ?? 0,
                      time: widget.timeByString[_touchedString] ?? 0,
                      attempts: widget.attemptsByString[_touchedString] ?? 0,
                    ),
            ),
            const SizedBox(height: 8),
            const Text('Accuracy by String',
                style: TextStyle(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            const SizedBox(height: 16),
            ...strings.map((s) {
              final hasData = widget.byString.containsKey(s);
              final acc = widget.byString[s] ?? 0.0;
              final pct = (acc * 100).round();
              final isTouched = _touchedString == s;
              final color = !hasData
                  ? AppTheme.borderColor
                  : pct >= 80
                      ? Colors.green
                      : pct >= 60
                          ? Colors.orange
                          : Colors.red;

              return GestureDetector(
                onTap: () => setState(
                    () => _touchedString = _touchedString == s ? null : s),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: isTouched
                      ? BoxDecoration(
                          border: Border.all(
                              color: AppTheme.accent.withOpacity(0.3),
                              width: 1),
                          borderRadius: BorderRadius.circular(4),
                        )
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 56,
                          child: Text('String $s',
                              style: const TextStyle(
                                  color: AppTheme.navy, fontSize: 12)),
                        ),
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 22,
                                decoration: BoxDecoration(
                                  color: AppTheme.borderColor.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              if (hasData)
                                FractionallySizedBox(
                                  widthFactor: acc.clamp(0.02, 1.0),
                                  child: Container(
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 38,
                          child: Text(
                            hasData ? '$pct%' : '—',
                            style: TextStyle(
                                color: hasData ? color : AppTheme.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteChart() {
    // Track note attempts from confusion groups or estimate
    final noteAttempts = <String, int>{};
    for (final n in widget.byNote.keys) {
      // Estimate attempts: if we have accuracy data we had attempts
      noteAttempts[n] = 1; // placeholder — real count needs extra data
    }

    return GestureDetector(
      onPanUpdate: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final localY = details.localPosition.dy - 140;
        const itemHeight = 24.0;
        final idx = (localY / itemHeight).floor();
        final reversed = _noteOrder.reversed.toList();
        if (idx >= 0 && idx < reversed.length) {
          setState(() => _touchedNote = reversed[idx]);
        }
      },
      onPanEnd: (_) => setState(() => _touchedNote = null),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed tooltip
            SizedBox(
              height: 56,
              child: _touchedNote == null
                  ? const SizedBox()
                  : _buildTooltipNote(
                      note: _touchedNote!,
                      accuracy: widget.byNote[_touchedNote] ?? 0,
                      time: widget.timeByNote[_touchedNote] ?? 0,
                      attempts: widget.attemptsByNote[_touchedNote] ?? 0,
                    ),
            ),
            const SizedBox(height: 8),
            const Text('Accuracy by Note',
                style: TextStyle(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            const SizedBox(height: 4),
            const Text('F5 (highest) → E2 (lowest)',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            const SizedBox(height: 12),
            ..._noteOrder.reversed.map((note) {
              final hasData = widget.byNote.containsKey(note);
              final acc = widget.byNote[note] ?? 0.0;
              final pct = (acc * 100).round();
              final isTouched = _touchedNote == note;
              final color = !hasData
                  ? AppTheme.borderColor
                  : pct >= 80
                      ? Colors.green
                      : pct >= 60
                          ? Colors.orange
                          : Colors.red;

              return GestureDetector(
                onTap: hasData
                    ? () => setState(
                        () => _touchedNote = _touchedNote == note ? null : note)
                    : null,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: isTouched
                      ? BoxDecoration(
                          border: Border.all(
                              color: AppTheme.accent.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(3),
                        )
                      : null,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 42,
                        child: Text(note,
                            style: const TextStyle(
                                color: AppTheme.navy, fontSize: 11)),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 18,
                              decoration: BoxDecoration(
                                color: AppTheme.borderColor.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            if (hasData)
                              FractionallySizedBox(
                                widthFactor: acc.clamp(0.02, 1.0),
                                child: Container(
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 34,
                        child: Text(
                          hasData ? '$pct%' : '—',
                          style: TextStyle(
                              color: hasData ? color : AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTooltipNote({
    required String note,
    required double accuracy,
    required double time,
    required int attempts,
  }) {
    // Count attempts for this note from byNote data
    // We need to pass attempts — update method signature
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.navy,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 20,
        children: [
          Text(note,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          Text(
            'Accuracy: ${(accuracy * 100).round()}%'
            '  · Avg: ${time.toStringAsFixed(1)}s'
            '  · $attempts attempts',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildTooltip({
    required String label,
    required double accuracy,
    required double time,
    required int attempts,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.navy,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          Text(
            'Accuracy: ${(accuracy * 100).round()}%'
            '  · Avg: ${time.toStringAsFixed(1)}s'
            '  · $attempts attempts',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─── Confusion Screen ─────────────────────────────────────────────
class _ConfusionScreen extends StatelessWidget {
  final List<ConfusionGroup> groups;
  const _ConfusionScreen({required this.groups});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Note Confusion'),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.navy,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderColor),
        ),
      ),
      body: groups.isEmpty
          ? const Center(
              child: Text('No confusion detected 🎉',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 16)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              itemBuilder: (_, i) {
                final g = groups[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              g.correctNote,
                              style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'confused ${g.totalCount}× total',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...g.entries.take(5).map((e) {
                        final frac =
                            g.totalCount == 0 ? 0.0 : e.count / g.totalCount;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.arrow_forward,
                                  size: 13, color: Colors.red),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: 44,
                                child: Text(e.answered,
                                    style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                              ),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: frac,
                                    backgroundColor: Colors.red.shade50,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.red.withOpacity(0.3 + frac * 0.7),
                                    ),
                                    minHeight: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${e.count}×',
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 11)),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ─── All Attempts Screen ──────────────────────────────────────────
class _AllAttemptsScreen extends StatefulWidget {
  final List<AttemptRecord> attempts;
  final UserModel student;
  final bool isStudentView;
  final VoidCallback onDeleted;

  const _AllAttemptsScreen({
    required this.attempts,
    required this.student,
    required this.isStudentView,
    required this.onDeleted,
  });

  @override
  State<_AllAttemptsScreen> createState() => _AllAttemptsScreenState();
}

class _AllAttemptsScreenState extends State<_AllAttemptsScreen> {
  static const _labels = {
    'EP_PI_1E': 'Pitch - S1 Easy',
    'EP_PI_1M': 'Pitch - S1 Medium',
    'EP_PI_1H': 'Pitch - S1 Hard',
    'EP_PI_2E': 'Pitch - S2 Easy',
    'EP_PI_2M': 'Pitch - S2 Medium',
    'EP_PI_2H': 'Pitch - S2 Hard',
    'EP_PI_3E': 'Pitch - S3 Easy',
    'EP_PI_3M': 'Pitch - S3 Medium',
    'EP_PI_3H': 'Pitch - S3 Hard',
    'EP_PI_Exam123': 'Pitch - Exam 1-3',
    'EP_PI_4E': 'Pitch - S4 Easy',
    'EP_PI_4M': 'Pitch - S4 Medium',
    'EP_PI_4H': 'Pitch - S4 Hard',
    'EP_PI_5E': 'Pitch - S5 Easy',
    'EP_PI_5M': 'Pitch - S5 Medium',
    'EP_PI_5H': 'Pitch - S5 Hard',
    'EP_PI_6E': 'Pitch - S6 Easy',
    'EP_PI_6M': 'Pitch - S6 Medium',
    'EP_PI_6H': 'Pitch - S6 Hard',
    'EP_PI_Exam123456': 'Pitch - Exam All',
    'EP_NI_1': 'Note - S1',
    'EP_NI_12': 'Note - S1+2',
    'EP_NI_123': 'Note - S1+2+3',
    'EP_NI_Exam123': 'Note - Exam 1-3',
    'EP_NI_1234': 'Note - S1+2+3+4',
    'EP_NI_12345': 'Note - S1+2+3+4+5',
    'EP_NI_123456': 'Note - All',
    'EP_NI_Exam123456': 'Note - Exam All',
  };

  late List<AttemptRecord> _attempts;

  @override
  void initState() {
    super.initState();
    _attempts = List.from(widget.attempts);
  }

  Future<void> _deleteAttempt(AttemptRecord attempt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Attempt',
            style:
                TextStyle(color: AppTheme.navy, fontWeight: FontWeight.bold)),
        content: const Text(
          'This attempt cannot be recovered later. '
          'Confirm delete?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await StudentAnalyticsService.deleteAttempt(
        studentUid: widget.student.uid,
        firestoreId: attempt.firestoreId,
      );
      setState(() => _attempts.remove(attempt));
      widget.onDeleted();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // final df = DateFormat('dd MMM yyyy  HH:mm');

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('All Attempts'),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.navy,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderColor),
        ),
      ),
      body: _attempts.isEmpty
          ? const Center(
              child: Text('No attempts yet',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 16)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _attempts.length,
              itemBuilder: (_, i) {
                final a = _attempts[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: _AttemptTile(
                      attempt:      a,
                      exerciseKey:  a.exerciseKey,
                      label:        _labels[a.exerciseKey] ?? a.exerciseKey,
                      isStudentView: widget.isStudentView,
                      onDelete:     widget.isStudentView
                          ? () {}
                          : () => _deleteAttempt(a),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
