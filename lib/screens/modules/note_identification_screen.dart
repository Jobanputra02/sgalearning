import 'package:flutter/material.dart';
import '../../models/note_exercise_model.dart';
import '../../models/exercise_access_model.dart';
import '../../services/note_exercise_data.dart';
import '../../services/note_exam_status_service.dart';
import '../../services/exercise_access_service.dart';
import '../../services/auth_service.dart';
import '../../services/best_score_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import 'note_exercise_screen.dart';

class NoteIdentificationScreen extends StatefulWidget {
  const NoteIdentificationScreen({super.key});

  @override
  State<NoteIdentificationScreen> createState() =>
      _NoteIdentificationScreenState();
}

class _NoteIdentificationScreenState
    extends State<NoteIdentificationScreen> {
  bool _exam3Passed = false;
  bool _exam6Passed = false;
  ExerciseAccess? _access;
  bool _loadingAccess = true;

  Map<String, int> _bestScores = {}; 

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = AuthService.currentUser;
    if (user == null) return;

    final results = await Future.wait([
      ExerciseAccessService.getAccess(user.uid, user.role),
      NoteExamStatusService.isExamPassed(
          NoteExamStatusService.note3StringKey),
      NoteExamStatusService.isExamPassed(
          NoteExamStatusService.note6StringKey),
      BestScoreService.getAllBestScores(user.uid), // ✅ NEW
    ]);

    if (mounted) {
      setState(() {
        _access        = results[0] as ExerciseAccess;
        _exam3Passed   = results[1] as bool;
        _exam6Passed   = results[2] as bool;
        _bestScores    = results[3] as Map<String, int>; // ✅ NEW
        _loadingAccess = false;
      });
    }
  }

  bool _isUnlocked(NoteExerciseConfig ex) {
    if (_access == null) return false;
    return _access!.hasAccess(ex.accessKey);
  }

  bool _isExamPassed(NoteExerciseConfig config) {
    if (!config.isExam) return false;
    return config.strings.length == 3 ? _exam3Passed : _exam6Passed;
  }

  String _examKey(NoteExerciseConfig config) {
    return config.strings.length == 3
        ? NoteExamStatusService.note3StringKey
        : NoteExamStatusService.note6StringKey;
  }

  @override
  Widget build(BuildContext context) {
    final exercises = NoteExerciseData.exercises;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Note Identification'),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.navy,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderColor),
        ),
      ),
      body: _loadingAccess
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.accent))
          : ListView.builder(
              padding: EdgeInsets.symmetric(
                  vertical: 16, horizontal: context.hPad),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final ex = exercises[index];
                final unlocked = _isUnlocked(ex);
                final bestScore = _bestScores[ex.accessKey]; // ✅ NEW

                if (ex.isExam) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ExamTile(
                      config: ex,
                      passed: _isExamPassed(ex),
                      unlocked: unlocked,
                      bestScore: bestScore, // ✅ NEW
                      onTap: unlocked
                          ? () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NoteExerciseScreen(
                                    config: ex,
                                    onExamPassed: () async {
                                      await NoteExamStatusService
                                          .markExamPassed(_examKey(ex));
                                      _loadData();
                                    },
                                  ),
                                ),
                              );
                              _loadData();
                            }
                          : null,
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ExerciseTile(
                    config: ex,
                    unlocked: unlocked,
                    bestScore: bestScore, // ✅ NEW
                    onTap: unlocked
                        ? () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    NoteExerciseScreen(config: ex),
                              ),
                            );
                            _loadData();
                          }
                        : null,
                  ),
                );
              },
            ),
    );
  }
}

// ─── Exercise Tile ────────────────────────────────────────────────
class _ExerciseTile extends StatelessWidget {
  final NoteExerciseConfig config;
  final bool unlocked;
  final int? bestScore; // ✅ NEW
  final VoidCallback? onTap;

  const _ExerciseTile({
    required this.config,
    required this.unlocked,
    required this.onTap,
    this.bestScore, // ✅ NEW
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: unlocked ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: unlocked ? AppTheme.white : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 40,
              decoration: BoxDecoration(
                color: unlocked
                    ? AppTheme.accent
                    : AppTheme.textSecondary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.title,
                    style: TextStyle(
                      color: unlocked
                          ? AppTheme.navy
                          : AppTheme.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${config.options.length} possible notes  •  ${config.totalQuestions} questions',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // ✅ BEST SCORE BADGE
            if (bestScore != null) ...[
              _ScoreBadge(
                score: bestScore!,
                total: config.totalQuestions,
              ),
              const SizedBox(width: 8),
            ],

            if (!unlocked)
              const Icon(Icons.lock,
                  size: 16, color: AppTheme.textSecondary)
            else
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ─── Exam Tile ────────────────────────────────────────────────────
class _ExamTile extends StatelessWidget {
  final NoteExerciseConfig config;
  final bool passed;
  final bool unlocked;
  final int? bestScore; // ✅ NEW
  final VoidCallback? onTap;

  const _ExamTile({
    required this.config,
    required this.passed,
    required this.unlocked,
    required this.onTap,
    this.bestScore, // ✅ NEW
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: unlocked ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: !unlocked
              ? AppTheme.cardBackground
              : passed
                  ? const Color(0xFFE8F5E9)
                  : AppTheme.navyOverlay4,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: !unlocked
                ? AppTheme.borderColor
                : passed
                    ? Colors.green.shade300
                    : AppTheme.navy.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: !unlocked
                    ? AppTheme.textSecondary
                    : passed
                        ? Colors.green
                        : AppTheme.navy,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                !unlocked
                    ? Icons.lock
                    : passed
                        ? Icons.verified
                        : Icons.assignment,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.title,
                    style: TextStyle(
                      color: !unlocked
                          ? AppTheme.textSecondary
                          : passed
                              ? Colors.green.shade800
                              : AppTheme.navy,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '30 questions  •  ${config.options.length} possible notes',
                    style: TextStyle(
                      color: !unlocked
                          ? AppTheme.textSecondary
                          : passed
                              ? Colors.green.shade600
                              : AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    !unlocked
                        ? 'Locked — contact faculty to unlock'
                        : passed
                            ? '✓ Passed — retake anytime'
                            : 'Must score 80% to pass',
                    style: TextStyle(
                      color: !unlocked
                          ? AppTheme.textSecondary
                          : passed
                              ? Colors.green.shade700
                              : Colors.red.shade400,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  // ✅ BEST SCORE BADGE
                  if (bestScore != null) ...[
                    const SizedBox(height: 4),
                    _ScoreBadge(
                      score: bestScore!,
                      total: config.totalQuestions,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              !unlocked ? Icons.lock : Icons.arrow_forward_ios,
              size: 14,
              color: !unlocked
                  ? AppTheme.textSecondary
                  : passed
                      ? Colors.green.shade400
                      : AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Score Badge ──────────────────────────────────────────────────
class _ScoreBadge extends StatelessWidget {
  final int score;
  final int total;

  const _ScoreBadge({
    required this.score,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final isPerfect = score == total;
    final color = isPerfect ? Colors.green : const Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        '$score/$total',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}