import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:attendance/features/notification/presentation/notifications_screen.dart';
import 'package:attendance/state/notification_provider.dart';

/// Bell icon with unread badge for app bars (placed before profile).
class AppNotificationAction extends StatelessWidget {
  const AppNotificationAction({super.key});

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationProvider>().unreadCount;

    return IconButton(
      tooltip: 'Notifications',
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
      },
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: const Icon(Icons.notifications_outlined, color: Colors.white),
      ),
    );
  }
}
