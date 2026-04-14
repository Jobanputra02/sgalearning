import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/student_management_service.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';

class StudentApprovalScreen extends StatefulWidget {
  const StudentApprovalScreen({super.key});

  @override
  State<StudentApprovalScreen> createState() =>
      _StudentApprovalScreenState();
}

class _StudentApprovalScreenState
    extends State<StudentApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // int get _pendingCount  => _pending.length;
  // int get _approvedCount => _approved.length;

  List<UserModel> _pending  = [];
  List<UserModel> _approved = [];
  bool _loading = true;

  // Search and filter
  final _searchController = TextEditingController();
  String _searchQuery    = '';
  // String? _brancFilter;  // null = show all
  // bool _filterByBranch = true; // default: same branch as faculty

  // Current faculty branch
  // String get _facultyBranch => AuthService.currentUser?.branch ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {setState(() {});    });
    // Default filter = faculty's own branch
    // _branchFilter = _facultyBranch;
    _loadStudents();

    _searchController.addListener(() {
      setState(() => _searchQuery =
          _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _loading = true);
    final currentUser = AuthService.currentUser;
     final branch = currentUser?.role == 'admin' ? null: currentUser?.branch;
    final results = await Future.wait([
      StudentManagementService.getPendingStudents(branchFilter: branch ),
      StudentManagementService.getApprovedStudents(branchFilter: branch),
    ]);
    if (mounted) {
      setState(() {
        _pending  = results[0]
          ..sort((a, b) {
            final first = a.firstName.toLowerCase()
                .compareTo(b.firstName.toLowerCase());
            if (first != 0) return first;
            return a.lastName.toLowerCase()
                .compareTo(b.lastName.toLowerCase());
          });
        _approved = results[1]
          ..sort((a, b) {
            final first = a.firstName.toLowerCase()
                .compareTo(b.firstName.toLowerCase());
            if (first != 0) return first;
            return a.lastName.toLowerCase()
                .compareTo(b.lastName.toLowerCase());
          });
        _loading = false;
      });
    }
  }

  // Apply search + branch filter
  List<UserModel> _filtered(List<UserModel> list) {
    if (_searchQuery.isEmpty) return list;
    return list.where((s) {
      return s.firstName.toLowerCase().contains(_searchQuery) ||
          s.lastName.toLowerCase().contains(_searchQuery) ||
          s.email.toLowerCase().contains(_searchQuery) ||
          s.branch.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  // void _toggleBranchFilter() {
  //   setState(() {
  //     if (_branchFilter != null) {
  //       // Remove filter — show all
  //       _branchFilter    = null;
  //       _filterByBranch  = false;
  //     } else {
  //       // Restore faculty branch filter
  //       _branchFilter   = _facultyBranch;
  //       _filterByBranch = true;
  //     }
  //   });
  // }

  Future<void> _approve(UserModel student) async {
    final confirm = await _confirmDialog(
      title:        'Approve Student',
      message:
          'Allow ${student.fullName} to login and access exercises?',
      confirmText:  'Approve',
      confirmColor: Colors.green,
    );
    if (!confirm) return;
    try {
      await StudentManagementService.approveStudent(student.uid);
      if (mounted) {
        _showSnack('${student.firstName} approved successfully');
        _loadStudents();
      }
    } catch (_) {
      if (mounted) _showSnack('Failed. Try again.');
    }
  }

  Future<void> _reject(UserModel student) async {
    final confirm = await _confirmDialog(
      title:        'Reject Student',
      message:
          'Reject ${student.fullName}? They will not be able to login.',
      confirmText:  'Reject',
      confirmColor: Colors.red,
    );
    if (!confirm) return;
    try {
      await StudentManagementService.rejectStudent(student.uid);
      if (mounted) {
        _showSnack('${student.firstName} rejected.');
        _loadStudents();
      }
    } catch (_) {
      if (mounted) _showSnack('Failed. Try again.');
    }
  }

  Future<void> _deactivate(UserModel student) async {
    final confirm = await _confirmDialog(
      title:        'Deactivate Student',
      message:
          '${student.fullName} will lose access immediately.',
      confirmText:  'Deactivate',
      confirmColor: Colors.red,
    );
    if (!confirm) return;
    try {
      await StudentManagementService.deactivateStudent(
          student.uid);
      if (mounted) {
        _showSnack('${student.firstName} deactivated.');
        _loadStudents();
      }
    } catch (_) {
      if (mounted) _showSnack('Failed. Try again.');
    }
  }

  Future<void> _activate(UserModel student) async {
    final confirm = await _confirmDialog(
      title: 'Activate Student',
      message: 'Restore access for ${student.fullName}?',
      confirmText:  'Activate',
      confirmColor: Colors.green,
    );
    if (!confirm) return;
    try {
      await StudentManagementService.activateStudent(
          student.uid);
      if (mounted) {
        _showSnack('${student.firstName} activated.');
        _loadStudents();
      }
    } catch (_) {
      if (mounted) _showSnack('Failed. Try again.');
    }
  }

  Future<bool> _confirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.background,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text(title,
                style: const TextStyle(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.bold)),
            content: Text(message,
                style: const TextStyle(
                    color: AppTheme.textSecondary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel',
                    style: TextStyle(
                        color: AppTheme.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(confirmText),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredPending  = _filtered(_pending);
    final filteredApproved = _filtered(_approved);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Student Approvals'),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.navy,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              const Divider(
                  height: 1, color: AppTheme.borderColor),
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.navy,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.accent,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Pending'),
                        if (filteredPending.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _CountBadge(
                            count: filteredPending.length,
                            color: Colors.red,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Approved'),
                        if (filteredApproved.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _CountBadge(
                            count: filteredApproved.length,
                            color: Colors.green,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.accent))
          : Column(
              children: [
                // ── Search + Filter bar ───────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(
                      16, 12, 16, 8),
                  color: AppTheme.background,
                  child: Column(
                    children: [
                      // Search field
                      TextField(
                        controller: _searchController,
                        style: const TextStyle(
                            color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText:
                              _tabController.index == 0
                              ? 'Search among ${_filtered(_pending).length} approvals'
                              : 'Search among ${_filtered(_approved).length} students',
                          hintStyle: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13),
                          prefixIcon: const Icon(
                              Icons.search,
                              color: AppTheme.accent,
                              size: 20),
                          suffixIcon:
                              _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                          Icons.clear,
                                          size: 18,
                                          color: AppTheme
                                              .textSecondary),
                                      onPressed: () {
                                        _searchController
                                            .clear();
                                        setState(() =>
                                            _searchQuery = '');
                                      },
                                    )
                                  : null,
                          filled: true,
                          fillColor: AppTheme.cardBackground,
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
                      // const SizedBox(height: 8),

                      // Branch filter row
                      // Row(
                      //   children: [
                      //     const Icon(
                      //         Icons.filter_list,
                      //         size: 16,
                      //         color: AppTheme.textSecondary),
                      //     const SizedBox(width: 6),
                      //     const Text(
                      //       'Branch:',
                      //       style: TextStyle(
                      //         color: AppTheme.textSecondary,
                      //         fontSize: 13,
                      //       ),
                      //     ),
                      //     const SizedBox(width: 8),

                      //     // Branch filter chip
                      //     GestureDetector(
                      //       onTap: _toggleBranchFilter,
                      //       child: AnimatedContainer(
                      //         duration: const Duration(
                      //             milliseconds: 200),
                      //         padding:
                      //             const EdgeInsets.symmetric(
                      //                 horizontal: 12,
                      //                 vertical: 6),
                      //         decoration: BoxDecoration(
                      //           color: _filterByBranch
                      //               ? AppTheme.accent
                      //               : AppTheme.cardBackground,
                      //           borderRadius:
                      //               BorderRadius.circular(20),
                      //           border: Border.all(
                      //             color: _filterByBranch
                      //                 ? AppTheme.accent
                      //                 : AppTheme.borderColor,
                      //           ),
                      //         ),
                      //         child: Row(
                      //           mainAxisSize: MainAxisSize.min,
                      //           children: [
                      //             Icon(
                      //               _filterByBranch
                      //                   ? Icons.check
                      //                   : Icons.location_city_outlined,
                      //               size: 13,
                      //               color: _filterByBranch
                      //                   ? Colors.white
                      //                   : AppTheme
                      //                       .textSecondary,
                      //             ),
                      //             const SizedBox(width: 5),
                      //             Text(
                      //               _filterByBranch
                      //                   ? _facultyBranch
                      //                   : 'All Branches',
                      //               style: TextStyle(
                      //                 color: _filterByBranch
                      //                     ? Colors.white
                      //                     : AppTheme
                      //                         .textSecondary,
                      //                 fontSize: 12,
                      //                 fontWeight:
                      //                     FontWeight.w600,
                      //               ),
                      //             ),
                      //           ],
                      //         ),
                      //       ),
                      //     ),

                      //     if (_filterByBranch) ...[
                      //       const SizedBox(width: 8),
                      //       GestureDetector(
                      //         onTap: _toggleBranchFilter,
                      //         child: Container(
                      //           padding:
                      //               const EdgeInsets.symmetric(
                      //                   horizontal: 10,
                      //                   vertical: 6),
                      //           decoration: BoxDecoration(
                      //             color: AppTheme.cardBackground,
                      //             borderRadius:
                      //                 BorderRadius.circular(20),
                      //             border: Border.all(
                      //                 color:
                      //                     AppTheme.borderColor),
                      //           ),
                      //           child: const Text(
                      //             'Show All',
                      //             style: TextStyle(
                      //               color: AppTheme.textSecondary,
                      //               fontSize: 12,
                      //             ),
                      //           ),
                      //         ),
                      //       ),
                      //     ],

                      //     const Spacer(),

                      //     // Result count
                      //     Text(
                      //       _tabController.index == 0
                      //           ? '${filteredPending.length} student${filteredPending.length != 1 ? 's' : ''}'
                      //           : '${filteredApproved.length} student${filteredApproved.length != 1 ? 's' : ''}',
                      //       style: const TextStyle(
                      //         color: AppTheme.textSecondary,
                      //         fontSize: 12,
                      //       ),
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                ),

                const Divider(
                    height: 1, color: AppTheme.borderColor),

                // ── Tab content ───────────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Pending
                      filteredPending.isEmpty
                          ? _EmptyState(
                              icon: _searchQuery.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.check_circle_outline,
                              message: _searchQuery.isNotEmpty
                                  ? 'No results for "$_searchQuery"'
                                  : 'No pending approvals',
                            )
                          : RefreshIndicator(
                              onRefresh: _loadStudents,
                              color: AppTheme.accent,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredPending.length,
                                itemBuilder: (_, i) =>_StudentTile(
                                  student: filteredPending[i],
                                  isPending: true,
                                  onApprove: () => _approve(filteredPending[i]),
                                  onReject: () => _reject(filteredPending[i]),
                                  onActivate: () {}, // not used for pending

                                ),
                              ),
                            ),

                      // Approved
                      // Approved tab
                      filteredApproved.isEmpty
                          ? _EmptyState(
                              icon: _searchQuery.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.people_outline,
                              message: _searchQuery.isNotEmpty
                                  ? 'No results for "$_searchQuery"'
                                  : 'No approved students yet',
                            )
                          : RefreshIndicator(
                              onRefresh: _loadStudents,
                              color: AppTheme.accent,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredApproved.length,
                                itemBuilder: (_, i) => _StudentTile(
                                  student:    filteredApproved[i],
                                  isPending:  false,
                                  onApprove:  () {},
                                  onReject:   () =>
                                      _deactivate(filteredApproved[i]), onActivate: () => _activate(filteredApproved[i]),
                                ),
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

// ─── Count Badge ──────────────────────────────────────────────────
class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;
  const _CountBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState(
      {required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.borderColor),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16)),
        ],
      ),
    );
  }
}

// ─── Student Tile ─────────────────────────────────────────────────
class _StudentTile extends StatelessWidget {
  final UserModel student;
  final bool isPending;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onActivate; // ← new

  const _StudentTile({
    required this.student,
    required this.isPending,
    required this.onApprove,
    required this.onReject,
    required this.onActivate, // ← new
  });

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final isActive = student.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.white
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? AppTheme.borderColor
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isPending
                      ? Colors.orange.shade50
                      : isActive
                          ? Colors.green.shade50
                          : Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isPending
                        ? Colors.orange.shade200
                        : isActive
                            ? Colors.green.shade200
                            : Colors.grey.shade300,
                  ),
                ),
                child: Center(
                  child: Text(
                    student.firstName.isNotEmpty
                        ? student.firstName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: isPending
                          ? Colors.orange.shade700
                          : isActive
                              ? Colors.green.shade700
                              : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            student.fullName,
                            style: TextStyle(
                              color: isActive
                                  ? AppTheme.navy
                                  : Colors.grey,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Active / Inactive badge
                        if (!isPending)
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius:
                                  BorderRadius.circular(10),
                              border: Border.all(
                                color: isActive
                                    ? Colors.green.shade200
                                    : Colors.red.shade200,
                              ),
                            ),
                            child: Text(
                              isActive
                                  ? 'Active'
                                  : 'Inactive',
                              style: TextStyle(
                                color: isActive
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                            Icons.location_city_outlined,
                            size: 12,
                            color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(student.branch,
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12)),
                        const SizedBox(width: 10),
                        const Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(_formatDate(student.createdAt),
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              // Profile button
              IconButton(
                icon: const Icon(Icons.info_outline,
                    color: AppTheme.accent, size: 20),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        _StudentProfileScreen(
                            student: student),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              if (isPending) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(
                          color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ] else if (isActive) ...[
                // Active — show deactivate button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.block, size: 16),
                    label: const Text('Deactivate'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(
                          color: Colors.red.shade200),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ] else ...[
                // Inactive — show activate button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onActivate,
                    icon: const Icon(
                        Icons.check_circle_outline,
                        size: 16),
                    label: const Text('Activate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Student Profile Screen ───────────────────────────────────────
class _StudentProfileScreen extends StatelessWidget {
  final UserModel student;
  const _StudentProfileScreen({required this.student});

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

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
          child:
              Divider(height: 1, color: AppTheme.borderColor),
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
                    width: 2),
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.accent.withOpacity(0.3)),
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
            _ProfileField(
                icon: Icons.email_outlined,
                label: 'Email',
                value: student.email),
            _ProfileField(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: student.phone),
            _ProfileField(
                icon: Icons.location_city_outlined,
                label: 'Branch',
                value: student.branch),
            _ProfileField(
                icon: Icons.location_on_outlined,
                label: 'City',
                value: student.city),
            _ProfileField(
                icon: Icons.markunread_mailbox_outlined,
                label: 'ZIP Code',
                value: student.zipCode),
            if (student.addressLine1 != null &&
                student.addressLine1!.isNotEmpty)
              _ProfileField(
                  icon: Icons.home_outlined,
                  label: 'Address Line 1',
                  value: student.addressLine1!),
            if (student.addressLine2 != null &&
                student.addressLine2!.isNotEmpty)
              _ProfileField(
                  icon: Icons.home_outlined,
                  label: 'Address Line 2',
                  value: student.addressLine2!),
            _ProfileField(
                icon: Icons.calendar_today_outlined,
                label: 'Registered On',
                value: _formatDate(student.createdAt)),
            _ProfileField(
                icon: Icons.verified_user_outlined,
                label: 'Status',
                value: student.isApproved
                    ? 'Approved'
                    : 'Pending Approval',
                valueColor: student.isApproved
                    ? Colors.green
                    : Colors.orange),
          ],
        ),
      ),
    );
  }
}

// ─── Profile Field ────────────────────────────────────────────────
class _ProfileField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _ProfileField({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
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
                  style: TextStyle(
                    color: valueColor ?? AppTheme.navy,
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