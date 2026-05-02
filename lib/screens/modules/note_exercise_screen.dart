import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/note_exercise_model.dart';
import '../../services/audio_service.dart';
import '../../services/note_question_generator.dart';
import '../../theme/app_theme.dart';
import '../../models/progress_models.dart';
import '../../services/progress_service.dart';
import '../../services/auth_service.dart';
import '../../services/exercise_access_service.dart';
import '../../utils/responsive.dart';

class NoteExerciseScreen extends StatefulWidget {
  final NoteExerciseConfig config;
  final VoidCallback? onExamPassed;

  const NoteExerciseScreen({ super.key, required this.config, this.onExamPassed,});

  @override
  State<NoteExerciseScreen> createState() => _NoteExerciseScreenState();
}

class _NoteExerciseScreenState extends State<NoteExerciseScreen> {
  late List<NoteQuestion> _questions;
  int _currentIndex = 0; // position in exercise (0–9 or 0–29)
  int _elapsedSeconds = 0;
  int _replayCount = 0;
  // int _skipCount = 0;
  bool _summaryShown = false; // ← prevents duplicate calls
  Timer? _timer;
  bool _timerStarted = false;
  String? _selectedAnswer;
  bool _answered = false;
  bool _isPlaying = false;

  final List<NoteQuestionResult> _results = [];

  // static const Color _shadowColor = Color(0x0D0A1628);
  static const Color _playShadow = Color(0x330A1628);

  // ─── Init ──────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _generateQuestions();
    _preloadAndStart();
  }

  void _generateQuestions() {
    _questions = NoteQuestionGenerator.generate(
      widget.config,
      widget.config.totalQuestions,
    );
  }

  Future<void> _preloadAndStart() async {
    if (!mounted) return;
    setState(() => _isPlaying = true);
    await AudioService.initSession();
    await AudioService.preloadQuestion(
      _questions[0].audioAsset,
      _questions[0].audioAsset, // single note — pass same twice
    );
    if (mounted) setState(() => _isPlaying = false);
    _startQuestion();
  }

  @override
  void dispose() {
    _timer?.cancel();
    AudioService.stop();
    super.dispose();
  }

  // ─── Question Flow ─────────────────────────────────────────────
  void _startQuestion() {
    _selectedAnswer = null;
    _answered = false;
    _elapsedSeconds = 0;
    _replayCount = 0;
    _timerStarted = false;
    _timer?.cancel();

    _startTimer();
    
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (mounted) _playAudioThenStartTimer();
    // });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _playAudio();
    });
  }

  Future<void> _playAudioThenStartTimer() async {
    await _playAudio();
    if (mounted && !_answered) _startTimer();
  }

  void _startTimer() {
    if (_timerStarted) return;
    _timerStarted = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_answered && mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  Future<void> _playAudio() async {
    if (_isPlaying || !mounted || _answered) return;
    setState(() => _isPlaying = true);
    final q = _questions[_currentIndex];
    await AudioService.preloadQuestion(q.audioAsset, q.audioAsset);
    await AudioService.playNote(q.audioAsset);
    if (mounted) setState(() => _isPlaying = false);
  }

  // Plays audio regardless of _answered state (for replay after answer)
  Future<void> _playAudioAny() async {
    if (_isPlaying || !mounted) return;
    setState(() => _isPlaying = true);
    final q = _questions[_currentIndex];
    await AudioService.preloadQuestion(q.audioAsset, q.audioAsset);
    await AudioService.playNote(q.audioAsset);
    if (mounted) setState(() => _isPlaying = false);
  }

  Future<void> _preloadNext() async {
    final next = _currentIndex + 1;
    if (next >= _questions.length) return;
    final q = _questions[next];
    await AudioService.preloadQuestion(q.audioAsset, q.audioAsset);
  }

  // ─── Replay ────────────────────────────────────────────────────
  void _onReplay() {
    if (_isPlaying) return;
    setState(() => _replayCount++);
    _playAudioAny();
    // Timer keeps running during replay
  }

  // ─── Answer ────────────────────────────────────────────────────
  void _onAnswer(String noteName) async {
    if (_answered) return;
    _timer?.cancel();

    final q = _questions[_currentIndex];
    final isCorrect = noteName == q.correctNote;
  final recordedTime = _elapsedSeconds - 2;   // Note audio ≈ 2 seconds
  final finalTime = recordedTime < 0 ? 0 : recordedTime;
    setState(() {
      _selectedAnswer = noteName;
      _answered = true;
    });

    await AudioService.stopNotes();
    AudioService.playFeedback(isCorrect);

    _results.add(NoteQuestionResult(
      question: q,
      userAnswer: noteName,
      isCorrect: isCorrect,
      isSkipped: false,
      timeSeconds: finalTime,
      replayCount: _replayCount,
    ));

    _preloadNext();
  }

  // ─── Skip — replace with fresh random question ─────────────────
  void _onSkip() {
    if (_answered || _isPlaying) return;
    _timer?.cancel();

    final q = _questions[_currentIndex];

    final recordedTime = _elapsedSeconds - 2;   // Note audio ≈ 2 seconds
    final finalTime = recordedTime < 0 ? 0 : recordedTime;
    _results.add(NoteQuestionResult(
      question: q,
      userAnswer: 'Skipped',
      isCorrect: false,
      isSkipped: true,
      timeSeconds: finalTime,
      replayCount: _replayCount,
    ));

    // Generate fresh replacement question
    final fresh = [NoteQuestionGenerator.generateOne(widget.config)];

    setState(() {
      // _skipCount++;
      _questions[_currentIndex] = fresh.first;
      _selectedAnswer = null;
      _answered = false;
      _elapsedSeconds = 0;
      _replayCount = 0;
      _timerStarted = false;
      _isPlaying = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _playAudioThenStartTimer();
    });
  }

  // ─── Next ──────────────────────────────────────────────────────
  void _nextQuestion() {
    if (_currentIndex + 1 >= widget.config.totalQuestions) {
      _showSummary();
      return;
    }
    setState(() {
      _currentIndex++;
      _isPlaying = false;
    });
    _startQuestion();
  }

  // ─── Exit Confirm ──────────────────────────────────────────────
  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.background,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Confirm Exit',
                style: TextStyle(
                    color: AppTheme.navy, fontWeight: FontWeight.bold)),
            content: const Text(
              'All your progress will be lost. Are you sure?',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel',
                    style: TextStyle(color: AppTheme.accent)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Exit', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldExit) {
      _timer?.cancel();
      await AudioService.stop();
    }
    return shouldExit;
  }

  Future<void> _saveProgress() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return;
      final questions = _results.map((r) {
        
        return QuestionAttempt(
          exerciseKey: widget.config.accessKey,
          exerciseType: 'note',
          isCorrect: r.isCorrect,
          isSkipped: r.isSkipped,
          timeSeconds: r.timeSeconds,
          replayCount: r.replayCount,
          correctAnswer: r.question.correctNote,
          userAnswer: r.userAnswer,
          notePlayed: r.question.correctNote,
          noteString: r.question.string,
          noteFret: r.question.fret,
        );
      }).toList();

      final total = widget.config.totalQuestions;
      final correct = _results.where((r) => r.isCorrect).length;
      final skipped = _results.where((r) => r.isSkipped).length;
      final wrong = _results.where((r) => !r.isCorrect && !r.isSkipped).length;

      final attempt = ExerciseAttempt(
        exerciseKey: widget.config.accessKey,
        exerciseType: 'note',
        attemptDate: DateTime.now(),
        totalQuestions: total,
        correct: correct,
        wrong: wrong,
        skipped: skipped,
        synced: false,
        questions: questions,
      );

      await ProgressService.saveAttempt(
        uid: user.uid,
        attempt: attempt,
      );
      // if (user.isStudent) {
      //   ExerciseAccessService.checkAndAutoUnlock(
      //     uid:          user.uid,
      //     exerciseKey: widget.config.accessKey,
      //     correct:      correct,
      //     total:        widget.config.totalQuestions,
      //   );
      // }
    } catch (_) {
      // Silently fail — will sync later when online
    }
  }

  // ─── Summary ───────────────────────────────────────────────────
  void _showSummary() {
  if (_summaryShown) return;
  _summaryShown = true;

  // Calculate all values synchronously — no async needed here
  final correct  = _results.where((r) => r.isCorrect).length;
  final total    = widget.config.totalQuestions;
  final skipped  = _results.where((r) => r.isSkipped).length;
  final wrong    = _results
      .where((r) => !r.isCorrect && !r.isSkipped)
      .length;
  final answered = _results.where((r) => !r.isSkipped).toList();
  final avgTime  = answered.isEmpty
      ? 0
      : (answered
                  .map((r) => r.timeSeconds)
                  .reduce((a, b) => a + b) /
              answered.length)
          .round();
  final isExam     = widget.config.isExam;
  final examPassed = isExam && correct == total;

  // Fire all async work in background — never awaited
  _saveProgress();
  _runAutoUnlock(correct, total);
  if (examPassed && widget.onExamPassed != null) {
    widget.onExamPassed!();
  }

  // Show dialog immediately — no await before this
  if (!mounted) return;
  _showResultDialog(
    correct:     correct,
    total:       total,
    wrong:       wrong,
    skipped:     skipped,
    avgTime:     avgTime,
    isExam:      isExam,
    examPassed:  examPassed,
  );
}

// Async unlock — runs in background, never blocks UI
void _runAutoUnlock(int correct, int total) async {
  try {
    final user = AuthService.currentUser;
    if (user == null) return;
    await ExerciseAccessService.checkAndAutoUnlock(
      uid:         user.uid,
      exerciseKey: widget.config.accessKey,
      correct:     correct,
      total:       total,
    );
  } catch (_) {
    // Silent — offline unlock handled locally
  }
}

void _showResultDialog({
  required int correct,
  required int total,
  required int wrong,
  required int skipped,
  required int avgTime,
  required bool isExam,
  required bool examPassed,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      backgroundColor: AppTheme.background,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      title: Text(
        isExam
            ? (examPassed ? '🎉 Exam Passed!' : 'Exam Complete')
            : 'Exercise Complete!',
        style: const TextStyle(
          color: AppTheme.navy,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: examPassed
                  ? const Color(0x1A4CAF50)
                  : AppTheme.accentOverlay10,
              border: Border.all(
                color: examPassed
                    ? Colors.green
                    : AppTheme.accent,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '$correct/$total',
                style: TextStyle(
                  color: examPassed
                      ? Colors.green
                      : AppTheme.navy,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (isExam) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: examPassed
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: examPassed
                      ? Colors.green.shade200
                      : Colors.red.shade200,
                ),
              ),
              child: Text(
                examPassed
                    ? 'Excellent! All correct. Exam marked as passed.'
                    : 'Need $total/$total to pass. You got $correct/$total. Try again!',
                style: TextStyle(
                  color: examPassed
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _SummaryRow(
              label: 'Correct',
              value: '$correct',
              color: Colors.green),
          _SummaryRow(
              label: 'Wrong',
              value: '$wrong',
              color: Colors.red),
          _SummaryRow(
              label: 'Skipped',
              value: '$skipped',
              color: Colors.orange),
          _SummaryRow(
              label: 'Avg Time',
              value: '${avgTime}s',
              color: AppTheme.accent),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Back to Exercises'),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              if (correct == total) {
                // Perfect score — go back to exercise list
                // The list will show next exercise unlocked
                Navigator.pop(context);
              } else {
                // Try again
                setState(() {
                  _currentIndex = 0;
                  _isPlaying    = false;
                  _summaryShown = false;
                  _results.clear();
                });
                _generateQuestions();
                _preloadAndStart();
              }
            },
            child: Text(
              correct == total
                  ? 'Next Exercise'
                  : 'Try Again',
              style: const TextStyle(color: AppTheme.accent),
            ),
          ),
        ),
      ],
    ),
  );
}

  // ─── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentIndex];
    final options = widget.config.options;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(widget.config.title),
          backgroundColor: AppTheme.background,
          foregroundColor: AppTheme.navy,
          elevation: 0,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: AppTheme.borderColor),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(context.hPad, context.rs(12), context.hPad, 0),
              child: Column(
                children: [
                  // Progress + Timer
                  Row(
                    children: [
                      Text(
                        'Q ${_currentIndex + 1} / ${widget.config.totalQuestions}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (_currentIndex + 1) /
                                widget.config.totalQuestions,
                            backgroundColor: AppTheme.borderColor,
                            color: AppTheme.accent,
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      RepaintBoundary(
                        child: Row(
                          children: [
                            const Icon(Icons.timer_outlined,
                                size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              '${_elapsedSeconds}s',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // if (_skipCount > 0) ...[
                  //   const SizedBox(height: 6),
                  //   Align(
                  //     alignment: Alignment.centerRight,
                  //     child: Text(
                  //       '$_skipCount skip${_skipCount > 1 ? 's' : ''}',
                  //       style: const TextStyle(
                  //           color: Colors.orange, fontSize: 11),
                  //     ),
                  //   ),
                  // ],

                  SizedBox(height: context.rs(14)),

                  // Question card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(context.rsc(20, min: 14, max: 26)),
                    decoration: const BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      border: Border.fromBorderSide(
                        BorderSide(color: AppTheme.borderColor),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Identify the Note!',
                          style: TextStyle(
                            color: AppTheme.navy,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: context.rs(16)),
                        GestureDetector(
                          onTap: _isPlaying ? null : _onReplay,
                          child: Container(
                            width: context.rsc(76, min: 64, max: 92),
                            height: context.rsc(76, min: 64, max: 92),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isPlaying
                                  ? AppTheme.borderColor
                                  : AppTheme.navy,
                              boxShadow: const [
                                BoxShadow(
                                  color: _playShadow,
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              _isPlaying ? Icons.volume_up : Icons.replay,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                        SizedBox(height: context.rs(8)),
                        Text(
                          _isPlaying ? 'Playing...' : 'Tap to replay',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.rs(8)),
                ],
              ),
            ),

            // Scrollable options grid
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: options.map((opt) {
                    return _NoteOptionButton(
                      noteName: opt.name,
                      answered: _answered,
                      selectedAnswer: _selectedAnswer,
                      correctAnswer: q.correctNote,
                      onTap: _answered ? null : () => _onAnswer(opt.name),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Bottom buttons
            Padding(
              padding: EdgeInsets.fromLTRB(context.hPad, context.rs(8), context.hPad, context.rs(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_answered)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _summaryShown ? null : _nextQuestion, // ← disable if already shown
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.navy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _currentIndex + 1 >= widget.config.totalQuestions
                              ? 'See Results'
                              : 'Next',
                        ),
                      ),
                    ),
                  if (!_answered)
                    TextButton(
                      onPressed: _isPlaying ? null : _onSkip,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: _isPlaying
                              ? AppTheme.borderColor
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Note Option Button ───────────────────────────────────────────
class _NoteOptionButton extends StatelessWidget {
  final String noteName;
  final bool answered;
  final String? selectedAnswer;
  final String correctAnswer;
  final VoidCallback? onTap;

  const _NoteOptionButton({
    required this.noteName,
    required this.answered,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.onTap,
  });

  Color get _bgColor {
    if (!answered) return AppTheme.white;
    if (noteName == correctAnswer) return Colors.green.shade50;
    if (noteName == selectedAnswer && noteName != correctAnswer) {
      return Colors.red.shade50;
    }
    return AppTheme.white;
  }

  Color get _borderColor {
    if (!answered) return AppTheme.borderColor;
    if (noteName == correctAnswer) return Colors.green;
    if (noteName == selectedAnswer && noteName != correctAnswer) {
      return Colors.red;
    }
    return AppTheme.borderColor;
  }

  Color get _textColor {
    if (!answered) return AppTheme.navy;
    if (noteName == correctAnswer) return Colors.green.shade700;
    if (noteName == selectedAnswer && noteName != correctAnswer) {
      return Colors.red.shade700;
    }
    return AppTheme.textSecondary;
  }

  IconData? get _icon {
    if (!answered) return null;
    if (noteName == correctAnswer) return Icons.check_circle;
    if (noteName == selectedAnswer && noteName != correctAnswer) {
      return Icons.cancel;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _borderColor, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_icon != null) ...[
              Icon(_icon,
                  size: 14,
                  color:
                      _icon == Icons.check_circle ? Colors.green : Colors.red),
              const SizedBox(width: 4),
            ],
            Text(
              noteName,
              style: TextStyle(
                color: _textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Summary Row ──────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
