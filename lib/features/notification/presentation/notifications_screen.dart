import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/layout/app_layout.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/core/widgets/app_choice_segments.dart';
import 'package:attendance/core/widgets/app_empty_state.dart';
import 'package:attendance/core/widgets/app_list_tile.dart';
import 'package:attendance/core/widgets/app_loading_state.dart';
import 'package:attendance/core/widgets/app_skeleton.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/notification/data/notification_models.dart';
import 'package:attendance/features/notification/presentation/notification_target.dart';
import 'package:attendance/state/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadIfNeeded();
    });
  }

  Future<void> _open(AppNotification n) async {
    final provider = context.read<NotificationProvider>();
    // Optimistic: mark read immediately so the list updates before navigation.
    unawaited(provider.markRead(n.id));
    if (!mounted) return;

    final target = notificationTarget(n);
    if (target == null) {
      AppFeedback.info(context, 'No related screen for this notification');
      return;
    }

    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => target));
    if (mounted) provider.refresh();
  }

  Future<void> _markAllRead() async {
    final provider = context.read<NotificationProvider>();
    if (!provider.hasUnread) return;
    final ok = await provider.markAllRead();
    if (!mounted) return;
    if (ok) {
      AppFeedback.success(context, 'All notifications marked as read');
      if (_unreadOnly) setState(() {});
    } else if (provider.error != null) {
      AppFeedback.error(context, provider.error!);
    }
  }

  List<AppNotification> _visible(NotificationProvider provider) {
    if (!_unreadOnly) return provider.notifications;
    return [
      for (final n in provider.notifications)
        if (!n.isRead) n,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final rows = _visible(provider);
    final unread = provider.unreadCount > 0
        ? provider.unreadCount
        : provider.notifications.where((n) => !n.isRead).length;
    final canMarkAll = provider.hasUnread && !provider.loading;

    return Scaffold(
      appBar: GradientAppBar(
        title: 'Notifications',
        showBack: true,
        showProfileAction: false,
        actions: [
          if (canMarkAll)
            IconButton(
              tooltip: 'Mark all as read',
              onPressed: _markAllRead,
              icon: const Icon(Icons.done_all_rounded, color: Colors.white),
            ),
        ],
      ),
      body: AppContentContainer(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.pagePadding,
          AppDimensions.pagePadding,
          AppDimensions.pagePadding,
          0,
        ),
        child: Column(
          children: [
            if (provider.notifications.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: AppChoiceSegments<bool>(
                      value: _unreadOnly,
                      onChanged: (v) => setState(() => _unreadOnly = v),
                      options: [
                        const AppSegmentOption(value: false, label: 'All'),
                        AppSegmentOption(value: true, label: unread > 0 ? 'Unread ($unread)' : 'Unread'),
                      ],
                    ),
                  ),
                  if (canMarkAll) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _markAllRead,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Mark all as read'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: AppLoadingState(
                isLoading: provider.loading,
                hasLoaded: provider.hasLoaded,
                hasData: rows.isNotEmpty,
                refreshing: provider.refreshing,
                error: provider.error,
                onRetry: provider.refresh,
                onRefresh: provider.refresh,
                loading: const AppSkeletonList(itemCount: 6),
                empty: AppEmptyState(
                  icon: Icons.notifications_none_outlined,
                  title: _unreadOnly ? 'No unread notifications' : 'No notifications',
                  message: _unreadOnly ? 'You are all caught up' : 'New leave, WFH and other updates will show up here',
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: rows.length,
                  itemBuilder: (context, i) {
                    final n = rows[i];
                    final showHeader =
                        i == 0 || notificationGroupLabel(n.createdAt) != notificationGroupLabel(rows[i - 1].createdAt);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showHeader) ...[
                          if (i > 0) const SizedBox(height: kAppListTileSpacing),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, left: 4),
                            child: Text(
                              notificationGroupLabel(n.createdAt),
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.textSecondary),
                            ),
                          ),
                        ],
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _NotificationTile(notification: n, onTap: () => _open(n)),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kind = notificationKind(notification);
    final unread = !notification.isRead;

    return AppListTile(
      leading: AppListTileLeading.icon(kind.icon, accent: kind.color),
      overline: kind.label,
      title: notification.title,
      subtitle: notification.message,
      trailing: Text(
        notificationTimeLabel(notification.createdAt),
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: context.textSecondary),
      ),
      accentColor: unread ? kind.color : null,
      onTap: onTap,
    );
  }
}
