import 'package:flutter/material.dart';

import 'package:attendance/core/widgets/app_error_state.dart';
import 'package:attendance/core/widgets/app_loader.dart';
import 'package:attendance/core/widgets/app_skeleton.dart';

enum ViewState { loading, success, empty, error }

/// Single rule set for API-driven content:
/// - data on hand → show it (re-fetches never hide it);
/// - failed with no data → error;
/// - not loaded yet / loading → loader (so "empty" never flashes before the first response);
/// - loaded with nothing → empty.
ViewState resolveViewState({required bool hasData, required bool isLoading, bool hasLoaded = true, Object? error}) {
  if (hasData) return ViewState.success;
  if (error != null && !isLoading) return ViewState.error;
  if (isLoading || !hasLoaded) return ViewState.loading;
  return ViewState.empty;
}

/// Renders the right widget for the current [ViewState] and, when [onRefresh] is set,
/// owns pull-to-refresh for every state. Background re-fetches show a small
/// [AppRefreshPill] over the data instead of replacing it.
class AppLoadingState extends StatefulWidget {
  const AppLoadingState({
    super.key,
    required this.isLoading,
    required this.hasData,
    required this.child,
    this.hasLoaded = true,
    this.refreshing = false,
    this.error,
    this.onRetry,
    this.onRefresh,
    this.loading,
    this.empty,
    this.errorTitle,
  });

  final bool isLoading;
  final bool hasData;

  /// False until the first request has finished; keeps the empty state hidden before then.
  final bool hasLoaded;

  /// A re-fetch is running while data is already visible.
  final bool refreshing;
  final Object? error;
  final VoidCallback? onRetry;
  final Future<void> Function()? onRefresh;

  /// Initial-load placeholder; defaults to [AppSkeletonList].
  final Widget? loading;
  final Widget? empty;
  final String? errorTitle;

  /// The data view. Should be scrollable when [onRefresh] is set.
  final Widget child;

  @override
  State<AppLoadingState> createState() => _AppLoadingStateState();
}

class _AppLoadingStateState extends State<AppLoadingState> {
  bool _pulling = false;

  Future<void> _handleRefresh() async {
    setState(() => _pulling = true);
    try {
      await widget.onRefresh!();
    } finally {
      if (mounted) setState(() => _pulling = false);
    }
  }

  Widget _scrollable(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final state = resolveViewState(hasData: w.hasData, isLoading: w.isLoading, hasLoaded: w.hasLoaded, error: w.error);
    final canRefresh = w.onRefresh != null;

    final Widget body = switch (state) {
      ViewState.loading => w.loading ?? const AppSkeletonList(),
      ViewState.error =>
        canRefresh
            ? _scrollable(
                AppErrorState(error: w.error!, onRetry: w.onRetry, title: w.errorTitle ?? "We couldn't load your data"),
              )
            : AppErrorState(error: w.error!, onRetry: w.onRetry, title: w.errorTitle ?? "We couldn't load your data"),
      ViewState.empty =>
        canRefresh ? _scrollable(w.empty ?? const SizedBox.shrink()) : (w.empty ?? const SizedBox.shrink()),
      ViewState.success => w.child,
    };

    if (state == ViewState.loading) return body;

    final refreshable = canRefresh ? RefreshIndicator(onRefresh: _handleRefresh, child: body) : body;
    final showPill = state == ViewState.success && w.refreshing && !_pulling;

    return Stack(
      children: [
        Positioned.fill(child: refreshable),
        Positioned(
          top: 8,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: showPill ? const Center(child: AppRefreshPill()) : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}
