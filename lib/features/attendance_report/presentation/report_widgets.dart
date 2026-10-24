import 'package:flutter/material.dart';

import 'package:attendance/core/cache/cache_policy.dart';
import 'package:attendance/core/cache/cache_stamp.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/core/widgets/app_status_badge.dart';
import 'package:attendance/features/attendance_report/data/attendance_report_service.dart';

/// Loading bookkeeping shared by the report views: keeps old data visible while
/// a new period loads and ignores responses that arrive out of order.
mixin ReportLoader<W extends StatefulWidget, T> on State<W> {
  T? data;
  bool loading = false;
  bool refreshing = false;
  bool hasLoaded = false;
  Object? error;
  int _seq = 0;
  DateTime? _fetchedAt;
  String? _cachedKey;

  /// Override per screen (team live data vs monthly reports, etc.).
  Duration get cacheTtl => CachePolicy.reportTtl;

  /// Include period / filter identity so TTL doesn't reuse the wrong response.
  String get cacheKey => runtimeType.toString();

  Future<T> fetch();

  /// Skips the network when in-memory data is still within [cacheTtl] for [cacheKey].
  Future<void> loadIfNeeded({bool force = false}) async {
    if (!force &&
        hasLoaded &&
        data != null &&
        _cachedKey == cacheKey &&
        CacheStamp.isFresh(_fetchedAt, cacheTtl)) {
      return;
    }
    await reload();
  }

  Future<void> reload() async {
    final seq = ++_seq;
    final key = cacheKey;
    setState(() {
      error = null;
      loading = data == null;
      refreshing = data != null;
    });
    try {
      final result = await fetch();
      if (!mounted || seq != _seq) return;
      setState(() {
        data = result;
        hasLoaded = true;
        _fetchedAt = DateTime.now();
        _cachedKey = key;
      });
    } catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        error = e;
        data = null;
        hasLoaded = true;
      });
    } finally {
      if (mounted && seq == _seq) {
        setState(() {
          loading = false;
          refreshing = false;
        });
      }
    }
  }
}

/// `‹  October 2026  ›` style period switcher with an optional tap-to-pick.
class ReportPeriodBar extends StatelessWidget {
  const ReportPeriodBar({
    super.key,
    required this.label,
    required this.onPrevious,
    required this.onNext,
    this.onTap,
    this.icon = Icons.calendar_month_outlined,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous',
            onPressed: onPrevious,
            icon: Icon(Icons.chevron_left_rounded, color: scheme.primary),
          ),
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Next',
            onPressed: onNext,
            icon: Icon(Icons.chevron_right_rounded, color: onNext == null ? scheme.outlineVariant : scheme.primary),
          ),
        ],
      ),
    );
  }
}

/// Coloured count tile, e.g. "Present 12".
class ReportStat extends StatelessWidget {
  const ReportStat({super.key, required this.label, required this.value, required this.color, this.onTap});

  final String label;
  final int value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: context.textSecondary),
          ),
        ],
      ),
    );
    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: body),
    );
  }
}

/// Grid of [ReportStat]s, [columns] per row.
class ReportStatGrid extends StatelessWidget {
  const ReportStatGrid({super.key, required this.stats, this.columns = 4});

  final List<ReportStat> stats;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 8.0;
        final width = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final s in stats) SizedBox(width: width, child: s)],
        );
      },
    );
  }
}

class ReportStatusBadge extends StatelessWidget {
  const ReportStatusBadge(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final style = AttendanceStatusStyle.of(status);
    return AppStatusBadge(label: style.label, foregroundColor: style.color, backgroundColor: style.soft);
  }
}

/// Bordered surface card used for report headers and rows.
class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppDimensions.spacing14),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: child,
        ),
      ),
    );
  }
}
