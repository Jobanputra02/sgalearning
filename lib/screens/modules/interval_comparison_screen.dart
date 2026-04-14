import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class IntervalComparisonScreen extends StatelessWidget {
  const IntervalComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Interval Comparison'),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.navy,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderColor),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🎵', style: TextStyle(fontSize: 64)),
            SizedBox(height: 20),
            Text(
              'Interval Comparison',
              style: TextStyle(
                color: AppTheme.navy,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Exercises coming soon...',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
