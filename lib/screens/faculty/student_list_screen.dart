import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/student_management_service.dart';
import '../../services/student_analytics_service.dart';
import '../../theme/app_theme.dart';
import 'student_profile_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() =>
      _StudentListScreenState();
}

class _StudentListScreenState
    extends State<StudentListScreen> {
  List<StudentAnalytics> _analytics = [];
  List<StudentAnalytics> _filtered  = [];
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _loading = true);

    final currentUser = AuthService.currentUser;
    if (currentUser == null) return;

    List<UserModel> students;

    if (currentUser.role == 'admin') {
      students = await StudentManagementService.getApprovedStudents();
    } else {
      // Faculty — only own branch
      final all = await StudentManagementService.getApprovedStudents();
      students = all.where((s) => s.branch == currentUser.branch).toList();
    }

    // Only active students
    students = students.where((s) => s.isActive).toList();

    // Sort A-Z
    students.sort((a, b) {
      final f = a.firstName.toLowerCase()
          .compareTo(b.firstName.toLowerCase());
      if (f != 0) return f;
      return a.lastName.toLowerCase()
          .compareTo(b.lastName.toLowerCase());
    });

    // Compute analytics for each student in parallel
    final analyticsResults = await Future.wait(
      students.map((s) =>
          StudentAnalyticsService.compute(s)),
    );

    if (mounted) {
      setState(() {
        _analytics = analyticsResults;
        _filtered  = analyticsResults;
        _loading   = false;
      });
    }
  }

  void _applyFilter() {
    final q = _searchController.text
        .trim()
        .toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = _analytics);
      return;
    }
    setState(() {
      _filtered = _analytics.where((a) {
        final s = a.student;
        return s.firstName.toLowerCase().contains(q) ||
            s.lastName.toLowerCase().contains(q) ||
            s.email.toLowerCase().contains(q);
      }).toList();
    });
  }

  Color _statusColor(StudentStatus status) {
    switch (status) {
      case StudentStatus.needsAttention:
        return Colors.red;
      case StudentStatus.monitor:
        return Colors.orange;
      case StudentStatus.onTrack:
        return Colors.green;
    }
  }

  String _statusEmoji(StudentStatus status) {
    switch (status) {
      case StudentStatus.needsAttention: return '🔴';
      case StudentStatus.monitor:        return '🟡';
      case StudentStatus.onTrack:        return '🟢';
    }
  }

  // int get _attentionCount => _analytics
  //     .where((a) =>
  //         a.status == StudentStatus.needsAttention)
  //     .length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Student Progress'),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.navy,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
              height: 1, color: AppTheme.borderColor),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.accent))
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                        color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search among ${_analytics.length} students',
                      hintStyle: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13),
                      prefixIcon: const Icon(
                          Icons.search,
                          color: AppTheme.accent,
                          size: 20),
                      suffixIcon: _searchController
                              .text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                  Icons.clear,
                                  size: 18,
                                  color: AppTheme
                                      .textSecondary),
                              onPressed: () =>
                                  _searchController
                                      .clear(),
                            )
                          : null,
                      filled:     true,
                      fillColor:  AppTheme.cardBackground,
                      contentPadding:
                          const EdgeInsets.symmetric(
                              vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppTheme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppTheme.accent,
                            width: 2),
                      ),
                    ),
                  ),
                ),

                // Summary strip
                // if (_analytics.isNotEmpty)
                //   Padding(
                //     padding: const EdgeInsets.fromLTRB(
                //         16, 0, 16, 8),
                //     child: Row(
                //       children: [
                //         Text(
                //           '${_filtered.length} student${_filtered.length != 1 ? 's' : ''}',
                //           style: const TextStyle(
                //             color: AppTheme.textSecondary,
                //             fontSize: 12,
                //           ),
                //         ),
                //         if (_attentionCount > 0) ...[
                //           const SizedBox(width: 12),
                //           Container(
                //             padding:
                //                 const EdgeInsets.symmetric(
                //                     horizontal: 8,
                //                     vertical: 3),
                //             decoration: BoxDecoration(
                //               color: Colors.red.shade50,
                //               borderRadius:
                //                   BorderRadius.circular(10),
                //               border: Border.all(
                //                   color:
                //                       Colors.red.shade200),
                //             ),
                //             child: Text(
                //               '🔴 $_attentionCount need attention',
                //               style: TextStyle(
                //                 color:
                //                     Colors.red.shade700,
                //                 fontSize: 11,
                //                 fontWeight:
                //                     FontWeight.w600,
                //               ),
                //             ),
                //           ),
                //         ],
                //       ],
                //     ),
                //   ),

                const Divider(
                    height: 1,
                    color: AppTheme.borderColor),

                // Student list
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              const Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color:
                                      AppTheme.borderColor),
                              const SizedBox(height: 16),
                              Text(
                                _searchController
                                        .text.isNotEmpty
                                    ? 'No results found'
                                    : 'No students yet',
                                style: const TextStyle(
                                    color: AppTheme
                                        .textSecondary,
                                    fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadStudents,
                          color: AppTheme.accent,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(
                                16),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) {
                              final a = _filtered[i];
                              return _StudentCard(
                                analytics: a,
                                statusColor:
                                    _statusColor(a.status),
                                statusEmoji:
                                    _statusEmoji(a.status),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          StudentProfileScreen(
                                        analytics: a,
                                      ),
                                    ),
                                  );
                                  _loadStudents();
                                },
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final StudentAnalytics analytics;
  final Color statusColor;
  final String statusEmoji;
  final VoidCallback onTap;

  const _StudentCard({
    required this.analytics,
    required this.statusColor,
    required this.statusEmoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = analytics.student;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            // Status dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  s.firstName.isNotEmpty
                      ? s.firstName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    s.fullName,
                    style: const TextStyle(
                      color: AppTheme.navy,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    analytics.verdictLine,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}