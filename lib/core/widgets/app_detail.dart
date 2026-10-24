import 'package:flutter/material.dart';

import 'package:attendance/core/layout/app_content_container.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/core/widgets/app_error_state.dart';
import 'package:attendance/core/widgets/app_loader.dart';
import 'package:attendance/core/widgets/app_skeleton.dart';
import 'package:attendance/core/widgets/app_status_badge.dart';
import 'package:attendance/core/widgets/app_topbar.dart';

export 'package:attendance/core/widgets/app_status_badge.dart';

/// Maps common API status strings to a badge tone so every detail screen colours them the same way.
AppStatusTone appStatusTone(String status) {
  switch (status.toLowerCase().replaceAll(' ', '_')) {
    case 'approved':
    case 'present':
    case 'completed':
    case 'done':
    case 'active':
    case 'won':
    case 'converted':
      return AppStatusTone.success;
    case 'rejected':
    case 'absent':
    case 'cancelled':
    case 'canceled':
    case 'lost':
    case 'inactive':
    case 'overdue':
    case 'high':
    case 'urgent':
      return AppStatusTone.error;
    case 'pending':
    case 'draft':
    case 'leave':
    case 'on_hold':
    case 'postponed':
    case 'medium':
    case 'review':
    case 'in_review':
    case 'warm':
    case 'nurturing':
    case 'future_prospect':
      return AppStatusTone.warning;
    case 'in_progress':
    case 'scheduled':
    case 'holiday':
    case 'new':
    case 'open':
    case 'contacted':
    case 'qualified':
    case 'meeting_scheduled':
    case 'meeting_completed':
    case 'proposal_sent':
    case 'proposal_reviewed':
    case 'negotiation':
    case 'cold':
      return AppStatusTone.info;
    case 'hot':
      return AppStatusTone.error;
    case 'lost_closed':
      return AppStatusTone.error;
    default:
      return AppStatusTone.neutral;
  }
}

/// `in_progress` → `In Progress`
String appLabelize(String raw, {String fallback = '-'}) {
  final s = raw.trim();
  if (s.isEmpty) return fallback;
  return s
      .replaceAll('_', ' ')
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) {
        return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
      })
      .join(' ');
}

/// Shared page shell for every detail screen (modelled on Employee Details):
/// app bar, loading / error states, full-width gradient header, card sections,
/// pull-to-refresh and an optional sticky action bar.
class AppDetailScaffold extends StatelessWidget {
  const AppDetailScaffold({
    super.key,
    required this.title,
    this.actions,
    this.loading = false,
    this.error,
    this.errorTitle,
    this.onRetry,
    this.onRefresh,
    this.busy = false,
    this.header,
    this.sections = const [],
    this.bottomBar,
    this.body,
  });

  final String title;
  final List<Widget>? actions;
  final bool loading;
  final Object? error;
  final String? errorTitle;
  final VoidCallback? onRetry;
  final Future<void> Function()? onRefresh;
  final bool busy;
  final Widget? header;
  final List<Widget> sections;
  final Widget? bottomBar;

  /// Replaces the section list below the header (e.g. for tabbed layouts).
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (loading) {
      content = const AppSkeletonDetail();
    } else if (error != null) {
      content = errorTitle == null
          ? AppErrorState(error: error!, onRetry: onRetry)
          : AppErrorState(error: error!, title: errorTitle!, onRetry: onRetry);
    } else if (body != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) header!,
          Expanded(child: body!),
        ],
      );
    } else {
      Widget list = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (header != null) header!,
          AppContentContainer(
            maxWidth: 820,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < sections.length; i++) ...[if (i > 0) const SizedBox(height: 16), sections[i]],
                ],
              ),
            ),
          ),
        ],
      );
      if (onRefresh != null) {
        list = RefreshIndicator(onRefresh: onRefresh!, child: list);
      }
      content = list;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GradientAppBar(title: title, showBack: true, showProfileAction: false, actions: actions),
      body: AppBusyOverlay(busy: busy, child: content),
      bottomNavigationBar: loading || error != null ? null : bottomBar,
    );
  }
}

/// Small key fact shown under the header text.
class AppDetailStat {
  const AppDetailStat({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;
}

/// Full-width gradient header: avatar (initials / icon / photo), title,
/// an icon subtitle line, a muted caption and a status badge on the right.
class AppDetailHeader extends StatelessWidget {
  const AppDetailHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleIcon = Icons.work_outline,
    this.caption,
    this.icon = Icons.description_outlined,
    this.avatarText,
    this.avatarUrl,
    this.status,
    this.statusTone,
    this.badges = const [],
    this.stats = const [],
    this.footer,
  });

  final String title;
  final String? subtitle;
  final IconData subtitleIcon;
  final String? caption;
  final IconData icon;

  /// When set, shows initials instead of [icon].
  final String? avatarText;
  final String? avatarUrl;

  /// Shown as an [AppStatusBadge] on the right; tone defaults to [appStatusTone].
  final String? status;
  final AppStatusTone? statusTone;

  /// Extra pills under the caption.
  final List<Widget> badges;
  final List<AppDetailStat> stats;
  final Widget? footer;

  static String initials(String s) {
    final parts = s.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.map((p) => p[0]).take(2).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final url = avatarUrl;
    final Widget avatar;
    if (url != null && url.isNotEmpty) {
      avatar = CircleAvatar(radius: 34, backgroundColor: Colors.white, backgroundImage: NetworkImage(url));
    } else if (avatarText != null) {
      avatar = CircleAvatar(
        radius: 34,
        backgroundColor: Colors.white,
        child: Text(
          initials(avatarText!),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primary),
        ),
      );
    } else {
      avatar = CircleAvatar(
        radius: 34,
        backgroundColor: Colors.white,
        child: Icon(icon, size: 30, color: primary),
      );
    }

    final s = (status ?? '').trim();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: AppContentContainer(
        maxWidth: 820,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  avatar,
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.trim().isEmpty ? 'Untitled' : title,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if ((subtitle ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(subtitleIcon, color: Colors.white70, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  subtitle!,
                                  style: const TextStyle(color: Colors.white70),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if ((caption ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            caption!,
                            style: const TextStyle(color: Colors.white60, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (badges.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(spacing: 6, runSpacing: 6, children: badges),
                        ],
                      ],
                    ),
                  ),
                  if (s.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    AppStatusBadge(label: appLabelize(s), tone: statusTone ?? appStatusTone(s)),
                  ],
                ],
              ),
              if (stats.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < stats.length; i++) ...[
                        if (i > 0) Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
                        Expanded(child: _HeaderStat(stat: stats[i])),
                      ],
                    ],
                  ),
                ),
              ],
              if (footer != null) ...[const SizedBox(height: 12), footer!],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.stat});

  final AppDetailStat stat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Icon(stat.icon, size: 16, color: Colors.white70),
          const SizedBox(height: 4),
          Text(
            stat.value.trim().isEmpty ? '-' : stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// Translucent pill for use inside [AppDetailHeader.badges].
class AppDetailHeaderBadge extends StatelessWidget {
  const AppDetailHeaderBadge(this.label, {super.key, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: Colors.white), const SizedBox(width: 4)],
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Bordered card with an icon + title header, optional trailing action,
/// and dividers automatically placed between consecutive [AppDetailRow]s.
class AppDetailSection extends StatelessWidget {
  const AppDetailSection({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
    this.count,
    required this.children,
  });

  final String title;
  final IconData? icon;
  final Widget? trailing;
  final int? count;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final body = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0 && children[i] is AppDetailRow && children[i - 1] is AppDetailRow) {
        body.add(const Divider(height: 20));
      }
      body.add(children[i]);
    }

    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.subtleBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (icon != null) ...[Icon(icon, color: primary, size: 20), const SizedBox(width: 8)],
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimary),
                        ),
                      ),
                      if (count != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primary),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              ],
            ),
            const SizedBox(height: 12),
            ...body,
          ],
        ),
      ),
    );
  }
}

/// Text action for a section header, e.g. "Add" or "Upload".
class AppDetailSectionAction extends StatelessWidget {
  const AppDetailSectionAction({super.key, required this.label, this.icon, required this.onPressed});

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final style = TextButton.styleFrom(
      foregroundColor: primary,
      backgroundColor: primary.withValues(alpha: 0.08),
      minimumSize: const Size(0, 30),
      fixedSize: null,
      maximumSize: const Size(160, 30),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    );
    if (icon == null) return TextButton(onPressed: onPressed, style: style, child: Text(label));
    return TextButton.icon(
      onPressed: onPressed,
      style: style.copyWith(iconSize: const WidgetStatePropertyAll(16)),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

/// Label / value line (label 2 : value 3), as used on Employee Details.
class AppDetailRow extends StatelessWidget {
  const AppDetailRow({super.key, this.icon, required this.label, this.value, this.valueWidget, this.onTap});

  final IconData? icon;
  final String label;
  final String? value;
  final Widget? valueWidget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final v = (value ?? '').trim();
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[Icon(icon, size: 18, color: context.textSecondary), const SizedBox(width: 8)],
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textSecondary),
          ),
        ),
        Expanded(
          flex: 3,
          child:
              valueWidget ??
              Text(
                v.isEmpty ? '-' : v,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: onTap != null ? Theme.of(context).colorScheme.primary : context.textPrimary,
                ),
              ),
        ),
      ],
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: row);
  }
}

/// Paragraph block for descriptions, reasons, notes, agendas.
class AppDetailText extends StatelessWidget {
  const AppDetailText(this.text, {super.key, this.emptyText = 'Nothing added yet'});

  final String? text;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final t = (text ?? '').trim();
    if (t.isEmpty) return AppDetailEmpty(emptyText);
    return Text(t, style: TextStyle(fontSize: 14, height: 1.5, color: context.textPrimary));
  }
}

/// Muted placeholder shown inside a section when it has no content.
class AppDetailEmpty extends StatelessWidget {
  const AppDetailEmpty(this.message, {super.key, this.icon});

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: TextStyle(color: context.textSecondary, fontWeight: FontWeight.w600),
    );
  }
}

/// Entry for comments, logs and history.
class AppDetailTimelineItem extends StatelessWidget {
  const AppDetailTimelineItem({
    super.key,
    required this.title,
    this.meta,
    this.body,
    this.icon = Icons.timeline,
    this.isLast = false,
  });

  final String title;
  final String? meta;
  final String? body;
  final IconData icon;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final lines = <String>[
      if ((body ?? '').trim().isNotEmpty) body!.trim(),
      if ((meta ?? '').trim().isNotEmpty) meta!.trim(),
    ];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppDimensions.radius12),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: lines.isEmpty ? null : Text(lines.join('\n'), style: TextStyle(color: context.textSecondary)),
      isThreeLine: lines.length > 1,
    );
  }
}

/// Attachment row with optional open and delete actions.
class AppDetailFileTile extends StatelessWidget {
  const AppDetailFileTile({super.key, required this.title, this.subtitle, this.onTap, this.onDelete});

  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final canOpen = onTap != null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(canOpen ? Icons.insert_drive_file_outlined : Icons.description_outlined),
      title: Text(
        title.trim().isEmpty ? 'File' : title,
        style: TextStyle(fontWeight: FontWeight.w700, color: canOpen ? Theme.of(context).colorScheme.primary : null),
      ),
      subtitle: (subtitle ?? '').trim().isNotEmpty ? Text(subtitle!) : null,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canOpen) Icon(Icons.open_in_new_rounded, size: 18, color: context.textSecondary),
          if (onDelete != null)
            IconButton(tooltip: 'Delete', icon: const Icon(Icons.delete_outline), onPressed: onDelete),
        ],
      ),
    );
  }
}

/// Simple person row (team members, attendees).
class AppDetailPersonTile extends StatelessWidget {
  const AppDetailPersonTile({super.key, required this.name, this.subtitle, this.trailing});

  final String name;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppDimensions.radius12),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          AppDetailHeader.initials(name),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary),
        ),
      ),
      title: Text(name.trim().isEmpty ? '-' : name, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: (subtitle ?? '').trim().isNotEmpty
          ? Text(subtitle!, style: TextStyle(color: context.textSecondary))
          : null,
      trailing: trailing,
    );
  }
}

/// Sticky bottom bar holding a detail screen's primary actions.
class AppDetailActionBar extends StatelessWidget {
  const AppDetailActionBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    const shape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14)));
    final common = ButtonStyle(
      fixedSize: const WidgetStatePropertyAll(Size.fromHeight(50)),
      minimumSize: const WidgetStatePropertyAll(Size(0, 50)),
      maximumSize: const WidgetStatePropertyAll(Size(double.infinity, 50)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
      iconSize: const WidgetStatePropertyAll(19),
      shape: const WidgetStatePropertyAll(shape),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
    );
    final outlinedSide = WidgetStateProperty.resolveWith<BorderSide>(
      (states) => BorderSide(
        color: states.contains(WidgetState.disabled)
            ? theme.colorScheme.outlineVariant
            : theme.colorScheme.primary.withValues(alpha: 0.5),
        width: 1.2,
      ),
    );
    final barTheme = theme.copyWith(
      filledButtonTheme: FilledButtonThemeData(style: common.merge(theme.filledButtonTheme.style)),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: common.copyWith(side: outlinedSide).merge(theme.outlinedButtonTheme.style),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: common.merge(theme.elevatedButtonTheme.style)),
    );
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: context.subtleBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Row(
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(
                      child: Theme(
                        data: barTheme,
                        child: DefaultTextStyle.merge(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          child: children[i],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Overflow (⋮) menu entry for secondary or destructive actions in the app bar.
class AppDetailMenuItem {
  const AppDetailMenuItem({required this.label, required this.icon, required this.onTap, this.destructive = false});

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;
}

class AppDetailMenu extends StatelessWidget {
  const AppDetailMenu({super.key, required this.items});

  final List<AppDetailMenuItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<int>(
      tooltip: 'More',
      icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      constraints: const BoxConstraints(minWidth: 210, maxWidth: 280),
      menuPadding: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      onSelected: (i) => items[i].onTap(),
      itemBuilder: (_) => [
        for (var i = 0; i < items.length; i++) ...[
          if (items[i].destructive && i > 0 && !items[i - 1].destructive) const PopupMenuDivider(height: 9),
          PopupMenuItem<int>(
            value: i,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _AppDetailMenuRow(item: items[i]),
          ),
        ],
      ],
    );
  }
}

class _AppDetailMenuRow extends StatelessWidget {
  const _AppDetailMenuRow({required this.item});

  final AppDetailMenuItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = item.destructive ? scheme.error : scheme.primary;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(item.icon, size: 18, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: item.destructive ? scheme.error : context.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
