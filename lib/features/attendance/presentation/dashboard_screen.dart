import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/theme/app_theme.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/attendance/presentation/app_drawer.dart';
import 'package:attendance/features/attendance/data/attendance_service.dart';
import 'package:attendance/state/attendance_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  AnimationController? _pageAnimController;
  Animation<double>? _pageFade;
  Animation<Offset>? _pageSlide;

  @override
  void initState() {
    super.initState();
    _pageAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pageFade = CurvedAnimation(
      parent: _pageAnimController!,
      curve: Curves.easeOut,
    );
    _pageSlide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _pageAnimController!,
            curve: Curves.easeOutCubic,
          ),
        );
    _pageAnimController!.forward();
  }

  Future<void> _punch(String action) async {
    try {
      final record = await context.read<AttendanceProvider>().punch(
        action: action,
      );
      if (record == null) {
        final err = context.read<AttendanceProvider>().error;
        throw err ?? Exception('Failed');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${action == 'in' ? 'Punched in' : 'Punched out'} at ${_formatTime(record.timestamp)}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _formatDate(DateTime dt) => DateFormat('EEE, d MMM yyyy').format(dt);
  String _formatTime(DateTime dt) => DateFormat('hh:mm a').format(dt);

  @override
  void dispose() {
    _pageAnimController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AttendanceProvider>();
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const GradientAppBar(title: 'Dashboard'),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FadeTransition(
            opacity: _pageFade ?? const AlwaysStoppedAnimation(1.0),
            child: SlideTransition(
              position: _pageSlide ?? const AlwaysStoppedAnimation(Offset.zero),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeaderCard(
                    loading: vm.loading,
                    onPunchIn: () => _punch('in'),
                    onPunchOut: () => _punch('out'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(
                        Icons.history,
                        color: AppTheme.primaryBlue,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Attendance History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: vm.records.isEmpty
                        ? const _EmptyState()
                        : ListView.separated(
                            itemCount: vm.records.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final r = vm.records[index];
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: Duration(
                                  milliseconds: 250 + (index % 12) * 30,
                                ),
                                curve: Curves.easeOut,
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, (1 - value) * 12),
                                      child: child,
                                    ),
                                  );
                                },
                                child: _AttendanceCard(
                                  record: r,
                                  formatDate: _formatDate,
                                  formatTime: _formatTime,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final bool loading;
  final VoidCallback onPunchIn;
  final VoidCallback onPunchOut;

  const _HeaderCard({
    required this.loading,
    required this.onPunchIn,
    required this.onPunchOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryBlue, AppTheme.primaryBlueLight],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.access_time,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attendance',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track your daily attendance',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _PunchButton(
                    onPressed: loading ? null : onPunchIn,
                    icon: Icons.login,
                    label: 'Punch In',
                    color: AppTheme.accentGreen,
                    isLoading: loading,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _PunchButton(
                    onPressed: loading ? null : onPunchOut,
                    icon: Icons.logout,
                    label: 'Punch Out',
                    color: AppTheme.accentRed,
                    isLoading: loading,
                  ),
                ),
              ],
            ),
            if (loading) ...[
              const SizedBox(height: 16),
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PunchButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color color;
  final bool isLoading;

  const _PunchButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final AttendanceRecord record;
  final String Function(DateTime) formatDate;
  final String Function(DateTime) formatTime;

  const _AttendanceCard({
    required this.record,
    required this.formatDate,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    final isPunchIn = record.action == 'in';
    final color = isPunchIn ? AppTheme.accentGreen : AppTheme.accentRed;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPunchIn ? Icons.login : Icons.logout,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isPunchIn ? 'Punch In' : 'Punch Out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          formatTime(record.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatDate(record.timestamp),
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          record.address ??
                              'Location: ${record.latitude.toStringAsFixed(4)}, ${record.longitude.toStringAsFixed(4)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
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
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.access_time_outlined,
              size: 64,
              color: AppTheme.primaryBlue.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Attendance Records',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by punching in to track your attendance',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
