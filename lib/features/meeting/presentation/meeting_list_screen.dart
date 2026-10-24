import 'package:flutter/material.dart';
import 'package:attendance/core/utils/app_date_format.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/layout/app_layout.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/widgets/app_empty_state.dart';
import 'package:attendance/core/widgets/app_error_state.dart';
import 'package:attendance/core/widgets/app_list_tile.dart';
import 'package:attendance/core/widgets/app_skeleton.dart';
import 'package:attendance/core/widgets/app_status_badge.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/meeting/data/meeting_service.dart';
import 'package:attendance/features/meeting/presentation/meeting_detail_screen.dart';
import 'package:attendance/state/meeting_provider.dart';

class MeetingListScreen extends StatefulWidget {
  const MeetingListScreen({super.key});

  @override
  State<MeetingListScreen> createState() => _MeetingListScreenState();
}

class _MeetingListScreenState extends State<MeetingListScreen> {
  final TextEditingController _searchC = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MeetingProvider>().loadIfNeeded();
    });
    _searchC.addListener(() {
      final next = _searchC.text.trim();
      if (next == _query) return;
      setState(() => _query = next);
    });
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  String _rangeLabel(Meeting m) {
    final start = AppDateFormat.dateTime(m.startDateTime);
    final end = DateFormat('h:mm a').format(m.endDateTime);
    return '$start - $end';
  }

  String _typeLabel(String type) {
    return type.replaceFirst(RegExp(r'^With\s+', caseSensitive: false), '').trim();
  }

  (Color fg, Color bg) _typeBadgeColors(String label) {
    switch (label.toLowerCase()) {
      case 'lead':
        return (AppColors.info, AppColors.infoSoft);
      case 'client':
        return (AppColors.primary, AppColors.primarySoft);
      case 'team':
        return (AppColors.success, AppColors.successSoft);
      case 'other':
        return (AppColors.warning, AppColors.warningSoft);
      default:
        return (AppColors.textSecondary, AppColors.background);
    }
  }

  List<Meeting> _filterMeetings(List<Meeting> meetings) {
    final q = _query.toLowerCase();
    if (q.isEmpty) return meetings;

    return meetings.where((m) {
      final title = m.title.toLowerCase();
      final organizerResolved = ((m.organizerName ?? '').trim().isNotEmpty ? (m.organizerName ?? '') : m.organizer);
      final organizer = organizerResolved.toLowerCase();
      final type = _typeLabel(m.type).toLowerCase();
      final date = AppDateFormat.date(m.startDateTime).toLowerCase();

      return title.contains(q) || organizer.contains(q) || type.contains(q) || date.contains(q);
    }).toList();
  }

  Future<void> _openMeeting(Meeting meeting) async {
    final updated = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => MeetingDetailScreen(meeting: meeting)));
    if (updated == true && mounted) {
      await context.read<MeetingProvider>().refresh();
    }
  }

  Widget _searchField() {
    return TextField(
      controller: _searchC,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search meetings...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(onPressed: () => _searchC.clear(), icon: const Icon(Icons.close)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeetingProvider>();
    final filtered = _filterMeetings(provider.meetings);

    Widget body;
    if (provider.meetings.isEmpty && (provider.loading || !provider.hasLoaded) && provider.error == null) {
      body = const AppSkeletonList();
    } else if (provider.error != null && provider.meetings.isEmpty) {
      body = AppErrorState(error: provider.error!, onRetry: () => provider.refresh());
    } else if (provider.meetings.isEmpty) {
      body = RefreshIndicator(
        onRefresh: provider.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            AppEmptyState(
              icon: Icons.event_outlined,
              title: 'No meetings',
              message: 'Scheduled meetings will appear here',
            ),
          ],
        ),
      );
    } else if (filtered.isEmpty) {
      body = RefreshIndicator(
        onRefresh: provider.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _searchField(),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'No results',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: AppAdaptiveList(
              onRefresh: provider.refresh,
              padding: const EdgeInsets.only(bottom: 16),
              header: Padding(padding: const EdgeInsets.only(bottom: 16), child: _searchField()),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final m = filtered[i];
                final label = _typeLabel(m.type);
                final (fg, bg) = _typeBadgeColors(label);
                final organizerDisplay =
                    ((m.organizerName ?? '').trim().isNotEmpty ? (m.organizerName ?? '') : m.organizer).trim();
                final loc = (m.location ?? '').trim();

                return AppListTile(
                  title: m.title,
                  subtitle: organizerDisplay.isEmpty ? null : organizerDisplay,
                  subtitleLines: [_rangeLabel(m), if (loc.isNotEmpty) loc],
                  trailing: AppStatusBadge(label: label, backgroundColor: bg, foregroundColor: fg),
                  onTap: () => _openMeeting(m),
                );
              },
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: const GradientAppBar(title: 'Meetings List', showBack: true, showProfileAction: false),
      body: AppContentContainer(padding: const EdgeInsets.all(AppDimensions.pagePadding), child: body),
    );
  }
}
