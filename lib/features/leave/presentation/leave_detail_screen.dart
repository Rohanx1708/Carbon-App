import 'package:flutter/material.dart';
import 'package:attendance/core/theme/app_theme.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/leave/data/leave_service.dart';

class LeaveDetailScreen extends StatelessWidget {
  final LeaveRequest leave;
  const LeaveDetailScreen({super.key, required this.leave});

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sept','Oct','Nov','Dec'];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  int _daysInclusive(DateTime a, DateTime b) => b.difference(DateTime(a.year, a.month, a.day)).inDays + 1;

  @override
  Widget build(BuildContext context) {
    final String status = leave.status.toLowerCase();
    final Color statusColor = status == 'approved'
        ? AppTheme.accentGreen
        : (status == 'rejected' ? AppTheme.accentRed : AppTheme.accentOrange);

    final String typeLabel = leave.type == 'casual'
        ? 'Casual Leave'
        : (leave.type == 'sick' ? 'Sick Leave' : '${leave.type[0].toUpperCase()}${leave.type.substring(1)} Leave');

    final Color stripeColor = leave.type == 'sick'
        ? AppTheme.accentRed
        : (leave.type == 'casual' ? AppTheme.primaryBlue : AppTheme.accentPurple);

    final int days = _daysInclusive(leave.startDate, leave.endDate);

    return Scaffold(
      appBar: const GradientAppBar(title: 'Leave Details', showBack: true, showProfileAction: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top stripe
              ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                child: Container(height: 6, color: stripeColor),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(typeLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatDate(leave.startDate)} — ${_formatDate(leave.endDate)}',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.grey.shade900),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.timelapse, size: 16, color: AppTheme.primaryBlue),
                              const SizedBox(width: 6),
                              Text('$days ${days == 1 ? 'day' : 'days'}', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryBlue)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: statusColor.withOpacity(0.25)),
                      ),
                      child: Text(
                        status == 'approved'
                            ? 'Approved'
                            : (status == 'rejected' ? 'Rejected' : 'Pending'),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Details sections
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.assignment_outlined, color: AppTheme.primaryBlue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Reason', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text(leave.reason, style: TextStyle(color: Colors.grey.shade700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.category_outlined, color: AppTheme.primaryBlue),
                        const SizedBox(width: 8),
                        Text(typeLabel, style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, color: AppTheme.primaryBlue),
                        const SizedBox(width: 8),
                        Text('${_formatDate(leave.startDate)} — ${_formatDate(leave.endDate)}', style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.attach_file, color: AppTheme.primaryBlue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            leave.attachmentName ?? 'No attachment',
                            style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Timeline (Create -> Review -> Approved/Rejected)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: _Timeline(status: status),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final String status; // 'pending' | 'approved' | 'rejected'
  const _Timeline({required this.status});

  int get _currentStep => status == 'approved' ? 3 : (status == 'rejected' ? 2 : 1);

  Color _colorFor(bool active) => active ? const Color(0xFF7C3AED) : Colors.grey.shade400;

  Widget _step(String label, int index) {
    final bool active = index <= _currentStep;
    final c = _colorFor(active);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: active ? c : Colors.transparent,
            border: Border.all(color: c, width: 2),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: index == 1 && active
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : Text(
                  index.toString(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: active ? Colors.white : c),
                ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? Colors.grey.shade800 : Colors.grey.shade600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _step('Create', 1),
          Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Container(height: 2, color: Colors.grey.shade300))),
          _step('Review', 2),
          Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Container(height: 2, color: Colors.grey.shade300))),
          _step(status == 'approved' ? 'Approved' : (status == 'rejected' ? 'Rejected' : 'Awaiting'), 3),
        ],
      ),
    );
  }
}



