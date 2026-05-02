import 'package:flutter/material.dart';
import '../../models/pitch_exercise_model.dart';
import '../../models/exercise_access_model.dart';
import '../../services/exam_status_service.dart';
import '../../services/exercise_access_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'pitch_exercise_screen.dart';
import '../../services/best_score_service.dart';
import '../../utils/responsive.dart';

class PitchIdentificationScreen extends StatefulWidget {
  const PitchIdentificationScreen({super.key});

  @override
  State<PitchIdentificationScreen> createState() =>
      _PitchIdentificationScreenState();
}

class _PitchIdentificationScreenState
    extends State<PitchIdentificationScreen> {
  bool _exam3Passed = false;
  bool _exam6Passed = false;
  ExerciseAccess? _access;
  Map<String, int> _bestScores = {};
  bool _loadingAccess = true;

  static final List<ExerciseConfig> _exercises = [
    ExerciseConfig(stringNumber: 1, difficulty: Difficulty.easy,   label: 'String 1 – Easy',   accessKey: 'EP_PI_1E'),
    ExerciseConfig(stringNumber: 1, difficulty: Difficulty.medium, label: 'String 1 – Medium', accessKey: 'EP_PI_1M'),
    ExerciseConfig(stringNumber: 1, difficulty: Difficulty.hard,   label: 'String 1 – Hard',   accessKey: 'EP_PI_1H'),
    ExerciseConfig(stringNumber: 2, difficulty: Difficulty.easy,   label: 'String 2 – Easy',   accessKey: 'EP_PI_2E'),
    ExerciseConfig(stringNumber: 2, difficulty: Difficulty.medium, label: 'String 2 – Medium', accessKey: 'EP_PI_2M'),
    ExerciseConfig(stringNumber: 2, difficulty: Difficulty.hard,   label: 'String 2 – Hard',   accessKey: 'EP_PI_2H'),
    ExerciseConfig(stringNumber: 3, difficulty: Difficulty.easy,   label: 'String 3 – Easy',   accessKey: 'EP_PI_3E'),
    ExerciseConfig(stringNumber: 3, difficulty: Difficulty.medium, label: 'String 3 – Medium', accessKey: 'EP_PI_3M'),
    ExerciseConfig(stringNumber: 3, difficulty: Difficulty.hard,   label: 'String 3 – Hard',   accessKey: 'EP_PI_3H'),
    ExerciseConfig(
      stringNumber: 0, difficulty: Difficulty.hard,
      label: 'Exam – Strings 1, 2 & 3',
      type: ExerciseType.exam, examStrings: [1, 2, 3],
      accessKey: 'EP_PI_Exam123',
    ),
    ExerciseConfig(stringNumber: 4, difficulty: Difficulty.easy,   label: 'String 4 – Easy',   accessKey: 'EP_PI_4E'),
    ExerciseConfig(stringNumber: 4, difficulty: Difficulty.medium, label: 'String 4 – Medium', accessKey: 'EP_PI_4M'),
    ExerciseConfig(stringNumber: 4, difficulty: Difficulty.hard,   label: 'String 4 – Hard',   accessKey: 'EP_PI_4H'),
    ExerciseConfig(stringNumber: 5, difficulty: Difficulty.easy,   label: 'String 5 – Easy',   accessKey: 'EP_PI_5E'),
    ExerciseConfig(stringNumber: 5, difficulty: Difficulty.medium, label: 'String 5 – Medium', accessKey: 'EP_PI_5M'),
    ExerciseConfig(stringNumber: 5, difficulty: Difficulty.hard,   label: 'String 5 – Hard',   accessKey: 'EP_PI_5H'),
    ExerciseConfig(stringNumber: 6, difficulty: Difficulty.easy,   label: 'String 6 – Easy',   accessKey: 'EP_PI_6E'),
    ExerciseConfig(stringNumber: 6, difficulty: Difficulty.medium, label: 'String 6 – Medium', accessKey: 'EP_PI_6M'),
    ExerciseConfig(stringNumber: 6, difficulty: Difficulty.hard,   label: 'String 6 – Hard',   accessKey: 'EP_PI_6H'),
    ExerciseConfig(
      stringNumber: 0, difficulty: Difficulty.hard,
      label: 'Exam – All 6 Strings',
      type: ExerciseType.exam, examStrings: [1, 2, 3, 4, 5, 6],
      accessKey: 'EP_PI_Exam123456',
    ),
  ];

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
      ExamStatusService.isExamPassed(
          ExamStatusService.pitch3StringKey),
      ExamStatusService.isExamPassed(
          ExamStatusService.pitch6StringKey),
      BestScoreService.getAllBestScores(user.uid),
    ]);

    if (mounted) {
      setState(() {
        _access        = results[0] as ExerciseAccess;
        _exam3Passed   = results[1] as bool;
        _exam6Passed   = results[2] as bool;
        _bestScores    = results[3] as Map<String, int>;
        _loadingAccess = false;
      });
    }
  }

  bool _isUnlocked(ExerciseConfig ex) {
    if (_access == null) return false;
    return _access!.hasAccess(ex.accessKey);
  }

  bool _isExamPassed(ExerciseConfig config) {
    if (!config.isExam) return false;
    return config.examStrings!.length == 3
        ? _exam3Passed
        : _exam6Passed;
  }

  String _examKey(ExerciseConfig config) =>
      config.examStrings!.length == 3
          ? ExamStatusService.pitch3StringKey
          : ExamStatusService.pitch6StringKey;

  Color _difficultyColor(Difficulty d) {
    switch (d) {
      case Difficulty.easy:   return const Color(0xFF2E7D32);
      case Difficulty.medium: return const Color(0xFFF57F17);
      case Difficulty.hard:   return const Color(0xFFC62828);
    }
  }

  void _onExerciseTap(ExerciseConfig ex) {
    final unlocked = _isUnlocked(ex);
    if (!unlocked) {
      // _showLockedDialog();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PitchExerciseScreen(
          config: ex,
          onExamPassed: ex.isExam
              ? () async {
            await ExamStatusService.markExamPassed(
                _examKey(ex));
            _loadData();
          }
              : null,
        ),
      ),
    ).then((_) => _loadData());
  }

  // void _showLockedDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (_) => AlertDialog(
  //       backgroundColor: AppTheme.background,
  //       shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(16)),
  //       title: const Row(
  //         children: [
  //           Icon(Icons.lock, color: AppTheme.navy, size: 20),
  //           SizedBox(width: 8),
  //           Text('Locked',
  //               style: TextStyle(color: AppTheme.navy)),
  //         ],
  //       ),
  //       content: const Text(
  //         'This exercise is locked. Please contact your faculty to unlock it.',
  //         style: TextStyle(color: AppTheme.textSecondary),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('OK',
  //               style: TextStyle(color: AppTheme.accent)),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Pitch Identification'),
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
          : ListView(
        padding: EdgeInsets.symmetric(
            vertical: 16, horizontal: context.hPad),
        children: _buildSections(),
      ),
    );
  }

  List<Widget> _buildSections() {
    final widgets = <Widget>[];
    final stringNames = ['E', 'B', 'G', 'D', 'A', 'E'];
    int currentString = 0;

    for (final ex in _exercises) {
      if (!ex.isExam && ex.stringNumber != currentString) {
        currentString = ex.stringNumber;
        if (currentString > 1) {
          widgets.add(Divider(
              color: AppTheme.borderColor, height: 28));
        }
        widgets.add(_StringHeader(
          stringNumber: currentString,
          stringName: stringNames[currentString - 1],
        ));
      }

      if (ex.isExam) {
        widgets.add(const SizedBox(height: 12));
        widgets.add(_ExamTile(
          config: ex,
          passed: _isExamPassed(ex),
          unlocked: _isUnlocked(ex),
          bestScore: _bestScores[ex.accessKey],
          onTap: () => _onExerciseTap(ex),
        ));
        widgets.add(const SizedBox(height: 4));
        continue;
      }

      widgets.add(_ExerciseTile(
        config: ex,
        difficultyColor: _difficultyColor(ex.difficulty),
        unlocked: _isUnlocked(ex),
        bestScore: _bestScores[ex.accessKey],
        onTap: () => _onExerciseTap(ex),
      ));
  }
  return widgets;
  }
}

// ─── String Header ────────────────────────────────────────────────
class _StringHeader extends StatelessWidget {
  final int stringNumber;
  final String stringName;
  const _StringHeader(
      {required this.stringNumber, required this.stringName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8, left: 4),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppTheme.navy,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text('S$stringNumber',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 10),
          Text('String $stringNumber  ($stringName)',
              style: const TextStyle(
                  color: AppTheme.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ─── Exercise Tile ────────────────────────────────────────────────
class _ExerciseTile extends StatelessWidget {
  final ExerciseConfig config;
  final Color difficultyColor;
  final bool unlocked;
  final VoidCallback onTap;
  final int? bestScore;

  const _ExerciseTile({
    required this.config,
    required this.difficultyColor,
    required this.unlocked,
    required this.onTap,
    this.bestScore,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: unlocked ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
              width: 5, height: 40,
              decoration: BoxDecoration(
                color: unlocked
                    ? difficultyColor
                    : AppTheme.textSecondary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(config.label,
                      style: TextStyle(
                          color: unlocked
                              ? AppTheme.navy
                              : AppTheme.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(
                    'Distance: ${config.semitoneRange.first}–${config.semitoneRange.last} semitones  •  10 questions',
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            if (!unlocked)
              const Icon(Icons.lock,
                  size: 16, color: AppTheme.textSecondary)
            else ...[
              // Container(
              //   padding: const EdgeInsets.symmetric(
              //       horizontal: 10, vertical: 4),
              //   decoration: BoxDecoration(
              //     color: difficultyColor.withOpacity(0.1),
              //     borderRadius: BorderRadius.circular(20),
              //     border: Border.all(
              //         color: difficultyColor.withOpacity(0.4)),
              //   ),
              //   child: Text(config.difficultyLabel,
              //       style: TextStyle(
              //           color: difficultyColor,
              //           fontSize: 11,
              //           fontWeight: FontWeight.bold)),
              // ),
              if (bestScore != null) ...[
                const SizedBox(width: 6),
                _ScoreBadge(
                  score: bestScore!,
                  total: config.totalQuestions,
                ),
              ],
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppTheme.textSecondary),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Exam Tile ────────────────────────────────────────────────────
class _ExamTile extends StatelessWidget {
  final ExerciseConfig config;
  final bool passed;
  final bool unlocked;
  final VoidCallback onTap;
  final int? bestScore;

  const _ExamTile({
    required this.config,
    required this.passed,
    required this.unlocked,
    required this.onTap,
    this.bestScore,
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
              : const Color(0x0A0A1628),
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
              width: 48, height: 48,
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
                  Text(config.label,
                      style: TextStyle(
                          color: !unlocked
                              ? AppTheme.textSecondary
                              : passed
                              ? Colors.green.shade800
                              : AppTheme.navy,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(
                    '30 questions  •  60% hard / 30% medium / 10% easy',
                    style: TextStyle(
                        color: !unlocked
                            ? AppTheme.textSecondary
                            : passed
                            ? Colors.green.shade600
                            : AppTheme.textSecondary,
                        fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(!unlocked ? 'Locked — contact faculty to unlock'
                        : passed ? '✓ Passed — retake anytime' : 'Must score 80% to pass',
                    style: TextStyle(
                        color: !unlocked
                            ? AppTheme.textSecondary
                            : passed
                            ? Colors.green.shade700
                            : Colors.red.shade400,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
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
              !unlocked
                  ? Icons.lock
                  : Icons.arrow_forward_ios,
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