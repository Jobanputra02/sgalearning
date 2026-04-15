import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/module_progress_service.dart';
import 'faculty/student_list_screen.dart';
import '../services/student_management_service.dart';
import '../services/student_analytics_service.dart';
import 'login_screen.dart';
import 'modules/pitch_identification_screen.dart';
import 'modules/note_identification_screen.dart';
import 'modules/interval_comparison_screen.dart';
import 'modules/interval_identification_screen.dart';
import '../models/user_model.dart';
import '../screens/faculty/student_approval_screen.dart';
import 'faculty/student_profile_screen.dart';
// import '../services/student_analytics_service.dart';

class DashboardScreen extends StatefulWidget {
  final UserModel user;
  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _pitchProgress = 0.0;
  double _noteProgress = 0.0;
  StudentAnalytics? _myAnalytics;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final user = widget.user;

    final pitch = await ModuleProgressService.getPitchProgress(user.uid);
    final note = await ModuleProgressService.getNoteProgress(user.uid);

    if (widget.user.role == 'student') {
      final analytics = await StudentAnalyticsService.compute(UserModel(
        uid: widget.user.uid,
        firstName: widget.user.firstName,
        lastName: widget.user.lastName,
        email: widget.user.email,
        phone: widget.user.phone,
        branch: widget.user.branch,
        role: widget.user.role,
        city: widget.user.city,
        zipCode: widget.user.zipCode,
        createdAt: widget.user.createdAt,
        isActive: widget.user.isActive,
        isApproved: widget.user.isApproved,
      ));
      if (mounted) setState(() => _myAnalytics = analytics);
    }
    if (mounted) {
      setState(() {
        _pitchProgress = pitch;
        _noteProgress = note;
      });
    }
  }

  String get _roleLabel {
    switch (widget.user.role) {
      case 'faculty':
        return 'Faculty';
      case 'admin':
        return 'Admin';
      default:
        return 'Student';
    }
  }

  Color get _roleBadgeColor {
    switch (widget.user.role) {
      case 'faculty':
        return AppTheme.accentLight;
      case 'admin':
        return AppTheme.navy;
      default:
        return AppTheme.accent;
    }
  }

  double _progressFor(String moduleKey) {
    switch (moduleKey) {
      case 'pitch':
        return _pitchProgress;
      case 'note':
        return _noteProgress;
      default:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final modules = [
      {
        'title': 'Pitch\nIdentification',
        'emoji': '🎧',
        'gradient': AppTheme.pitchGradient,
        'moduleKey': 'pitch',
        'screen': const PitchIdentificationScreen(),
      },
      {
        'title': 'Note\nIdentification',
        'emoji': '🎸',
        'gradient': AppTheme.noteGradient,
        'moduleKey': 'note',
        'screen': const NoteIdentificationScreen(),
      },
      {
        'title': 'Interval\nComparison',
        'emoji': '🎵',
        'gradient': AppTheme.intervalCompGradient,
        'moduleKey': 'interval_comp',
        'screen': const IntervalComparisonScreen(),
      },
      {
        'title': 'Interval\nIdentification',
        'emoji': '🎹',
        'gradient': AppTheme.intervalIdGradient,
        'moduleKey': 'interval_id',
        'screen': const IntervalIdentificationScreen(),
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/images/sga.png', height: 32),
            const SizedBox(width: 10),
            const Text(
              'SGA Learning',
              style: TextStyle(
                color: AppTheme.navy,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.borderColor),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _roleBadgeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _roleBadgeColor, width: 1),
            ),
            child: Text(
              _roleLabel,
              style: TextStyle(
                color: _roleBadgeColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Add this inside actions list, before PopupMenuButton
          // if (widget.user.role == 'faculty' ||
          //     widget.user.role == 'admin') ...[
          //   _PendingBadgeButton(
          //     uid:  widget.user.uid,
          //     role: widget.user.role,
          //   ),
          // ],

          PopupMenuButton<String>(
            icon: const Icon(Icons.settings, color: AppTheme.navy),
            onSelected: (value) async {
              if (value == 'logout') {
                _logout(context);
              } else if (value == 'students') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentApprovalScreen(),
                  ),
                );
              } else if (value == 'profile') {
                // Opens the same profile screen used in student_approval_screen
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _StudentProfileScreen(student: widget.user),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              // Only show student management for faculty and admin
              if (widget.user.role == 'faculty' || widget.user.role == 'admin')
                const PopupMenuItem<String>(
                  value: 'students',
                  child: Row(
                    children: [
                      Icon(Icons.people_outline, color: AppTheme.navy),
                      SizedBox(width: 8),
                      Text('Manage Students'),
                    ],
                  ),
                ),
              // Show My Profile for students
              if (widget.user.role == 'student')
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, color: AppTheme.navy),
                      SizedBox(width: 8),
                      Text('My Profile'),
                    ],
                  ),
                ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppTheme.navy),
                    SizedBox(width: 8),
                    Text('Log out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 28),
            Text(
              'Hello, ${widget.user.firstName} 👋',
              style: const TextStyle(
                color: AppTheme.navy,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ready to train your ear today?',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            const Divider(color: AppTheme.borderColor, thickness: 1),
            const SizedBox(height: 20),
            const Text(
              'Ear Training',
              style: TextStyle(
                color: AppTheme.navy,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0,
                ),
                itemCount: modules.length,
                itemBuilder: (context, index) {
                  final module = modules[index];
                  final moduleKey = module['moduleKey'] as String;
                  return _ModuleCard(
                    title: module['title'] as String,
                    emoji: module['emoji'] as String,
                    gradient: module['gradient'] as List<Color>,
                    role: widget.user.role,
                    progress: _progressFor(moduleKey),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => module['screen'] as Widget,
                        ),
                      );
                      // Refresh progress when returning
                      _loadProgress();
                    },
                  );
                },
              ),
            ),
            if (widget.user.role == 'student' && _myAnalytics != null) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentProfileScreen(
                      analytics: _myAnalytics!,
                      isStudentView: true,
                    ),
                  ),
                ).then((_) => _loadProgress()),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderColor, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppTheme.noteGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.trending_up,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('My Progress',
                                style: TextStyle(
                                    color: AppTheme.navy,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold)),
                            Text(
                              'Pitch ${(_myAnalytics!.pitchOverallPct * 100).round()}%'
                              ' · Note ${(_myAnalytics!.noteOverallPct * 100).round()}%',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: AppTheme.textSecondary),
                    ],
                  ),
                ),
              ),
            ],
            // After the GridView Expanded widget, add:
            const SizedBox(height: 16),
            // Students card — faculty and admin only
            if (widget.user.role == 'faculty' || widget.user.role == 'admin')
              _StudentsCard(user: widget.user),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _logout(BuildContext context) async {
    await AuthService.logout();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }
}

// ─── Module Card ─────────────────────────────────────────────────
class _ModuleCard extends StatelessWidget {
  final String title;
  final String emoji;
  final List<Color> gradient;
  final String role;
  final double progress; // ← was 0.0 hardcoded
  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.emoji,
    required this.gradient,
    required this.role,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: AppTheme.navyOverlay4,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.navy,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (role == 'student') ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppTheme.borderColor,
                        valueColor: AlwaysStoppedAnimation<Color>(gradient[0]),
                        minHeight: 5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$pct% complete',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                  if (role != 'student')
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: gradient[0].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: gradient[0].withOpacity(0.3)),
                      ),
                      child: Text(
                        'Full Access',
                        style: TextStyle(
                          color: gradient[0],
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingBadgeButton extends StatefulWidget {
  final String uid;
  final String role;

  const _PendingBadgeButton({
    required this.uid,
    required this.role,
  });

  @override
  State<_PendingBadgeButton> createState() => _PendingBadgeButtonState();
}

class _PendingBadgeButtonState extends State<_PendingBadgeButton> {
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    try {
      final students = await StudentManagementService.getPendingStudents();
      if (mounted) {
        setState(() => _pendingCount = students.length);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.people_outline, color: AppTheme.navy),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StudentApprovalScreen(),
              ),
            );
            // Refresh badge on return
            _loadPendingCount();
          },
        ),
        if (_pendingCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$_pendingCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StudentsCard extends StatefulWidget {
  final UserModel user;
  const _StudentsCard({required this.user});

  @override
  State<_StudentsCard> createState() => _StudentsCardState();
}

class _StudentsCardState extends State<_StudentsCard> {
  // int _attentionCount = 0;
  int _totalStudents = 0;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    try {
      List<UserModel> students;
      if (widget.user.role == 'admin') {
        students = await StudentManagementService.getApprovedStudents();
      } else {
        final all = await StudentManagementService.getApprovedStudents();
        students = all
            .where((s) => s.branch == widget.user.branch && s.isActive)
            .toList();
      }

      // Compute analytics for attention count
      // int attention = 0;
      // for (final s in students) {
      //   final a =
      //       await StudentAnalyticsService.compute(s);
      //   if (a.status == StudentStatus.needsAttention) {
      //     attention++;
      //   }
      // }

      if (mounted) {
        setState(() {
          _totalStudents = students.length;
          // _attentionCount = attention;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const StudentListScreen(),
          ),
        );
        _loadCount();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppTheme.pitchGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child:
                  const Icon(Icons.trending_up, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Student Progress',
                      style: TextStyle(
                          color: AppTheme.navy,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    '$_totalStudents student${_totalStudents != 1 ? 's' : ''}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            // if (_attentionCount > 0)
            //   Container(
            //     padding: const EdgeInsets.symmetric(
            //         horizontal: 8, vertical: 4),
            //     decoration: BoxDecoration(
            //       color: Colors.red.shade50,
            //       borderRadius:
            //           BorderRadius.circular(10),
            //       border: Border.all(
            //           color: Colors.red.shade200),
            //     ),
            //     child: Text(
            //       '🔴 $_attentionCount',
            //       style: TextStyle(
            //         color: Colors.red.shade700,
            //         fontSize: 12,
            //         fontWeight: FontWeight.bold,
            //       ),
            //     ),
            //   ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
// ─── Student Profile Screen (My Profile use) ──────────
class _StudentProfileScreen extends StatelessWidget {
  final UserModel student;
  const _StudentProfileScreen({required this.student});
  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Student Profile'),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.navy,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.accent.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  student.firstName.isNotEmpty
                      ? student.firstName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              student.fullName,
              style: const TextStyle(
                color: AppTheme.navy,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
              ),
              child: const Text(
                'Student',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Details
            _ProfileRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: student.email,
            ),
            _ProfileRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: student.phone,
            ),
            _ProfileRow(
              icon: Icons.location_city_outlined,
              label: 'Branch',
              value: student.branch,
            ),
            _ProfileRow(
              icon: Icons.location_on_outlined,
              label: 'City',
              value: student.city,
            ),
            _ProfileRow(
              icon: Icons.markunread_mailbox_outlined,
              label: 'ZIP Code',
              value: student.zipCode,
            ),
            if (student.addressLine1 != null &&
                student.addressLine1!.isNotEmpty)
              _ProfileRow(
                icon: Icons.home_outlined,
                label: 'Address Line 1',
                value: student.addressLine1!,
              ),
            if (student.addressLine2 != null &&
                student.addressLine2!.isNotEmpty)
              _ProfileRow(
                icon: Icons.home_outlined,
                label: 'Address Line 2',
                value: student.addressLine2!,
              ),
            _ProfileRow(
              icon: Icons.calendar_today_outlined,
              label: 'Registered On',
              value: _formatDate(student.createdAt),
            ),
            const SizedBox(height: 16),
            // Read-only note
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.accent.withOpacity(0.7),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "If you want to update or Delete your profile, contact the Faculty or mail to sargamguitar2011@gmail.com",
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
// ─── Profile Row helper ───────────────────────────────────────────
class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}