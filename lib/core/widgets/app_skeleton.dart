import 'package:flutter/material.dart';

import 'package:attendance/core/layout/app_content_container.dart';
import 'package:attendance/core/theme/app_dimensions.dart';

/// Gentle opacity pulse shared by every skeleton below it (one controller per scope).
/// Respects the platform "reduce motion" setting.
class AppSkeletonPulse extends StatefulWidget {
  const AppSkeletonPulse({super.key, required this.child});

  final Widget child;

  @override
  State<AppSkeletonPulse> createState() => _AppSkeletonPulseState();
}

class _AppSkeletonPulseState extends State<AppSkeletonPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
    upperBound: 1,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = Semantics(
      label: 'Loading',
      liveRegion: true,
      child: ExcludeSemantics(child: widget.child),
    );
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
    return FadeTransition(opacity: _c, child: child);
  }
}

/// Placeholder block. Use inside an [AppSkeletonPulse] (the list / dashboard / detail skeletons include one).
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({super.key, this.width, this.height = 12, this.radius = 6});

  const AppSkeleton.circle({super.key, required double size}) : width = size, height = size, radius = 999;

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)),
    );
  }
}

class _SkeletonSurface extends StatelessWidget {
  const _SkeletonSurface({required this.child, this.padding = const EdgeInsets.all(14)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radius16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: child,
    );
  }
}

/// Mirrors a list tile: leading avatar, two text lines and a trailing badge.
class AppSkeletonCard extends StatelessWidget {
  const AppSkeletonCard({super.key, this.lines = 2, this.showLeading = true, this.showTrailing = true});

  final int lines;
  final bool showLeading;
  final bool showTrailing;

  @override
  Widget build(BuildContext context) {
    return _SkeletonSurface(
      child: Row(
        children: [
          if (showLeading) ...[const AppSkeleton(width: 44, height: 44, radius: 12), const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FractionallySizedBox(widthFactor: 0.6, child: AppSkeleton(height: 14)),
                for (var i = 1; i < lines + 1; i++) ...[
                  const SizedBox(height: 8),
                  FractionallySizedBox(widthFactor: i.isOdd ? 0.85 : 0.45, child: const AppSkeleton(height: 10)),
                ],
              ],
            ),
          ),
          if (showTrailing) ...[const SizedBox(width: 12), const AppSkeleton(width: 56, height: 22, radius: 999)],
        ],
      ),
    );
  }
}

/// Initial-load placeholder for list screens. [header] lets a screen reserve space
/// for something above the list (calendar, filters).
class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({super.key, this.itemCount = 6, this.header, this.padding = EdgeInsets.zero});

  final int itemCount;
  final Widget? header;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return AppSkeletonPulse(
      child: ListView(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          if (header != null) ...[header!, const SizedBox(height: 16)],
          for (var i = 0; i < itemCount; i++) ...[if (i > 0) const SizedBox(height: 12), const AppSkeletonCard()],
        ],
      ),
    );
  }
}

/// Large block standing in for a calendar / chart above a list.
class AppSkeletonBlock extends StatelessWidget {
  const AppSkeletonBlock({super.key, this.height = 320});

  final double height;

  @override
  Widget build(BuildContext context) {
    return _SkeletonSurface(
      child: SizedBox(
        height: height - 28,
        child: const Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppSkeleton(width: 20, height: 20),
                AppSkeleton(width: 120, height: 14),
                AppSkeleton(width: 20, height: 20),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: AppSkeleton(width: double.infinity, height: double.infinity, radius: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dashboard placeholder: hero card, stat tiles and a short list.
class AppSkeletonDashboard extends StatelessWidget {
  const AppSkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeletonPulse(
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const AppSkeleton(width: double.infinity, height: 190, radius: 20),
          const SizedBox(height: 20),
          const AppSkeleton(width: 140, height: 16),
          const SizedBox(height: 12),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 112,
            ),
            children: List.generate(
              4,
              (_) => const _SkeletonSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeleton(width: 32, height: 32, radius: 10),
                    Spacer(),
                    AppSkeleton(width: 48, height: 16),
                    SizedBox(height: 6),
                    AppSkeleton(width: 80, height: 10),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const AppSkeleton(width: 160, height: 16),
          const SizedBox(height: 12),
          const AppSkeletonCard(),
          const SizedBox(height: 12),
          const AppSkeletonCard(),
        ],
      ),
    );
  }
}

/// Detail-screen placeholder matching [AppDetailScaffold]: gradient header and section cards.
class AppSkeletonDetail extends StatelessWidget {
  const AppSkeletonDetail({super.key, this.sections = 3});

  final int sections;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return AppSkeletonPulse(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            color: primary.withValues(alpha: 0.12),
            child: const Row(
              children: [
                AppSkeleton.circle(size: 68),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FractionallySizedBox(widthFactor: 0.7, child: AppSkeleton(height: 18)),
                      SizedBox(height: 10),
                      FractionallySizedBox(widthFactor: 0.5, child: AppSkeleton(height: 12)),
                      SizedBox(height: 8),
                      FractionallySizedBox(widthFactor: 0.35, child: AppSkeleton(height: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppContentContainer(
            maxWidth: 820,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  for (var s = 0; s < sections; s++) ...[
                    if (s > 0) const SizedBox(height: 16),
                    _SkeletonSurface(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              AppSkeleton(width: 20, height: 20),
                              SizedBox(width: 8),
                              AppSkeleton(width: 110, height: 14),
                            ],
                          ),
                          for (var r = 0; r < 3; r++) ...[
                            const SizedBox(height: 16),
                            const Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Align(alignment: Alignment.centerLeft, child: AppSkeleton(width: 70)),
                                ),
                                Expanded(flex: 3, child: AppSkeleton()),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
