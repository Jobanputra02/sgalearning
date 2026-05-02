import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/progress_models.dart';
import '../../models/pitch_exercise_model.dart';
import '../../services/audio_service.dart';
import '../../services/auth_service.dart';
import '../../services/progress_service.dart';
import '../../services/pitch_question_generator.dart';
import '../../services/exercise_access_service.dart';
import '../../utils/responsive.dart';

class PitchExerciseScreen extends StatefulWidget {
  final ExerciseConfig config;
  final VoidCallback? onExamPassed;

  const PitchExerciseScreen({
    super.key,
    required this.config,
    this.onExamPassed,
  });

  @override
  State<PitchExerciseScreen> createState() => _PitchExerciseScreenState();
}

class _PitchExerciseScreenState extends State<PitchExerciseScreen> {
  late List<PitchQuestion> _questions;
  int _currentIndex = 0;
  int _elapsedSeconds = 0;
  int _replayCount = 0;
  bool _summaryShown = false; // ← prevents duplicate calls
  Timer? _timer;

  String? _selectedAnswer;
  bool _answered = false;
  bool _isPlaying = false;
  bool _timerStarted = false; // ← prevents timer starting before audio ends
  // int _skipCount = 0; // total skips this session

  final List<QuestionResult> _results = [];

  static const Color _shadowColor = Color(0x0D0A1628);
  static const Color _playShadow = Color(0x330A1628);

  @override
  void initState() {
    super.initState();
    _questions = widget.config.isExam
        ? PitchQuestionGenerator.generateExamQuestions(widget.config)
        : PitchQuestionGenerator.generateQuestions(
            widget.config, widget.config.totalQuestions);
    _preloadAndStart();
  }

  Future<void> _preloadAndStart() async {
    if (!mounted) return;
    setState(() => _isPlaying = true);
    await AudioService.initSession();
    final first = _questions[0];
    await AudioService.preloadQuestion(
      first.noteA.audioAsset,
      first.noteB.audioAsset,
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

  void _startQuestion() {
    _selectedAnswer = null;
    _answered = false;
    _elapsedSeconds = 0;
    _replayCount = 0;
    _timerStarted = false;
    _timer?.cancel();

    // Play audio after frame renders
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (mounted) _playAudioThenStartTimer();
    // });
    _startTimer();

    // Play audio after frame (non-blocking)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _playAudio();
    });
  }
  
  // Audio plays first, timer starts ONLY after audio finishes
  Future<void> _playAudioThenStartTimer() async {
    await _playAudio();
    // Only start timer if not already answered (e.g. fast tap)
    if (mounted && !_answered) {
      _startTimer();
    }
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
    if (_isPlaying) return;
    if (!mounted) return;
    setState(() => _isPlaying = true);

    final q = _questions[_currentIndex];
    await AudioService.preloadQuestion(q.noteA.audioAsset, q.noteB.audioAsset,);
    await AudioService.playMelodic();

    if (mounted) setState(() => _isPlaying = false);
  }

  Future<void> _preloadNext() async {
    final nextIndex = _currentIndex + 1;
    if (nextIndex >= _questions.length) return;
    final q = _questions[nextIndex];
    await AudioService.preloadQuestion(
      q.noteA.audioAsset,
      q.noteB.audioAsset,
    );
  }

  void _onReplay() {
    if (_isPlaying) return;
    _replayCount++;
    // Stop timer while replaying, restart after
    // _timer?.cancel();
    // _timerStarted = false;
    // _playAudioThenStartTimer();
    _playAudio();
  }

  void _onAnswer(String answer) async {
    if (_answered) return;
    _timer?.cancel();

    final q = _questions[_currentIndex];
    final isCorrect = answer == q.correctAnswer;
    final recordedTime = _elapsedSeconds - 4;
    final finalTime = recordedTime < 0 ? 0 : recordedTime;
    
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
    });

    // Stop notes immediately, play feedback
    await AudioService.stopNotes();
    AudioService.playFeedback(isCorrect);

    _results.add(QuestionResult(
      question: q,
      userAnswer: answer,
      isCorrect: isCorrect,
      isSkipped: false,
      timeSeconds: finalTime,
      replayCount: _replayCount,
    ));

    // Preload next in background
    _preloadNext();
  }

  void _onSkip() {
    if (_answered || _isPlaying) return;
    _timer?.cancel();

    final q = _questions[_currentIndex];
    final recordedTime = _elapsedSeconds - 4;
    final finalTime = recordedTime < 0 ? 0 : recordedTime;

    // Log this skip attempt
    _results.add(QuestionResult(
      question: q,
      userAnswer: 'Skipped',
      isCorrect: false,
      isSkipped: true,
      timeSeconds: finalTime,
      replayCount: _replayCount,
    ));

    // Generate a fresh replacement question for this slot
    final fresh = PitchQuestionGenerator.generateQuestions(
      widget.config,
      1,
    );

    setState(() {
      // _skipCount++;
      // Replace current question with new random one
      _questions[_currentIndex] = fresh.first;
      // Reset question state — same index, new question
      _selectedAnswer = null;
      _answered = false;
      _elapsedSeconds = 0;
      _replayCount = 0;
      _timerStarted = false;
      _isPlaying = false;
    });

    // Play new question audio automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _playAudioThenStartTimer();
    });
  }

  void _nextQuestion() {
    if (_currentIndex + 1 >= widget.config.totalQuestions) {
      _showSummary();
      return;
    }
    setState(() {
      _currentIndex++;
      _isPlaying = false; // reset playing state before new question
    });
    _startQuestion();
  }

  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.background,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Confirm Exit',
              style: TextStyle(
                color: AppTheme.navy,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'All your progress will be lost. Are you sure?',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.accent),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Exit',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldExit) {
      _timer?.cancel();
      await AudioService.stop(); // stop immediately on confirm
    }

    return shouldExit;
  }

  // ─── This is a separate method, NOT inside _showSummary ──────────
  Future<void> _saveProgress() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return;

      final questions = _results.map((r) {
        // pitch screen version:
        final dist = (r.question.noteA.midi - r.question.noteB.midi).abs();
        return QuestionAttempt(
          exerciseKey:      widget.config.accessKey,
          exerciseType:     'pitch',
          isCorrect:        r.isCorrect,
          isSkipped:        r.isSkipped,
          timeSeconds:      r.timeSeconds,
          replayCount:      r.replayCount,
          correctAnswer:    r.question.correctAnswer,
          userAnswer:       r.userAnswer,
          noteA:            r.question.noteA.name,
          noteB:            r.question.noteB.name,
          noteAString:      r.question.noteA.string,
          noteAFret:        r.question.noteA.fret,
          noteBString:      r.question.noteB.string,
          noteBFret:        r.question.noteB.fret,
          semitoneDistance: dist,
        );
      }).toList();
      final correct = _results.where((r) => r.isCorrect).length;
      final skipped = _results.where((r) => r.isSkipped).length;
      final wrong   = _results.where((r) => !r.isCorrect && !r.isSkipped).length;
      final attempt = ExerciseAttempt(
        exerciseKey:    widget.config.accessKey,
        exerciseType:   'pitch',
        attemptDate:    DateTime.now(),
        totalQuestions: widget.config.totalQuestions,
        correct:        correct,
        wrong:          wrong,
        skipped:        skipped,
        synced:         false,
        questions:      questions,
      );

      await ProgressService.saveAttempt(
        uid:     user.uid,
        attempt: attempt,
      );
      // Auto-unlock next exercise if student is a student role
      // if (user.isStudent) {
      //   ExerciseAccessService.checkAndAutoUnlock(
      //     uid:          user.uid,
      //     exerciseKey: widget.config.accessKey,
      //     correct:      correct,
      //     total:        widget.config.totalQuestions,
      //   );
      // }
    } catch (_) {
      // Silent — offline data stays in SQLite, syncs later
    }
  }

// ─── _showSummary is async and calls _saveProgress ───────────────
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
                _questions = widget.config.isExam? PitchQuestionGenerator.generateExamQuestions(widget.config): PitchQuestionGenerator.generateQuestions(widget.config, widget.config.totalQuestions);
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

  Color _buttonColor(String option) {
    if (!_answered) return AppTheme.white;
    final q = _questions[_currentIndex];
    if (option == q.correctAnswer) return Colors.green.shade50;
    if (option == _selectedAnswer && option != q.correctAnswer) {
      return Colors.red.shade50;
    }
    return AppTheme.white;
  }

  Color _buttonBorderColor(String option) {
    if (!_answered) return AppTheme.borderColor;
    final q = _questions[_currentIndex];
    if (option == q.correctAnswer) return Colors.green;
    if (option == _selectedAnswer && option != q.correctAnswer) {
      return Colors.red;
    }
    return AppTheme.borderColor;
  }

  IconData? _buttonIcon(String option) {
    if (!_answered) return null;
    final q = _questions[_currentIndex];
    if (option == q.correctAnswer) return Icons.check_circle;
    if (option == _selectedAnswer && option != q.correctAnswer) {
      return Icons.cancel;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentIndex];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(widget.config.label),
          backgroundColor: AppTheme.background,
          foregroundColor: AppTheme.navy,
          elevation: 0,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: AppTheme.borderColor),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(context.hPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Progress + Timer row
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
                        value:
                            (_currentIndex + 1) / widget.config.totalQuestions,
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
              // const SizedBox(height: 12),
              // if (_skipCount > 0)
              //   Align(
              //     alignment: Alignment.centerRight,
              //     child: Text(
              //       '$_skipCount skip${_skipCount > 1 ? 's' : ''}',
              //       style: const TextStyle(
              //         color: Colors.orange,
              //         fontSize: 11,
              //       ),
              //     ),
              //   ),
              SizedBox(height: context.rs(20)),

              // Question card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(context.rsc(24, min: 16, max: 32)),
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
                      'Which note is HIGHER?',
                      style: TextStyle(
                        color: AppTheme.navy,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: context.rs(20)),
                    GestureDetector(
                      onTap: _isPlaying ? null : _onReplay,
                      child: Container(
                        width: context.rsc(76, min: 64, max: 92),
                        height: context.rsc(76, min: 64, max: 92),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              _isPlaying ? AppTheme.borderColor : AppTheme.navy,
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
                    SizedBox(height: context.rs(10)),
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
              SizedBox(height: context.rs(28)),

              // Answer buttons
              Row(
                children: ['First', 'Second'].map((option) {
                  final icon = _buttonIcon(option);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: GestureDetector(
                        onTap: _answered ? null : () => _onAnswer(option),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: _buttonColor(option),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _buttonBorderColor(option),
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: _shadowColor,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              if (icon != null)
                                Icon(
                                  icon,
                                  color: icon == Icons.check_circle
                                      ? Colors.green
                                      : Colors.red,
                                  size: 28,
                                )
                              else
                                const Icon(
                                  Icons.music_note,
                                  color: AppTheme.accent,
                                  size: 28,
                                ),
                              const SizedBox(height: 8),
                              Text(
                                option,
                                style: TextStyle(
                                  color: _answered
                                      ? (option == q.correctAnswer
                                          ? Colors.green.shade700
                                          : option == _selectedAnswer
                                              ? Colors.red.shade700
                                              : AppTheme.textSecondary)
                                      : AppTheme.navy,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              SizedBox(height: context.rs(24)),

              // Bottom buttons
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_answered)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _nextQuestion,
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
                    TextButton.icon(
                      onPressed: _isPlaying ? null : _onSkip,
                      // icon: Icon(
                      //   Icons.refresh,
                      //   size: 16,
                      //   color: _isPlaying
                      //       ? AppTheme.borderColor
                      //       : AppTheme.textSecondary,
                      // ),
                      label: Text(
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
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

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
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
