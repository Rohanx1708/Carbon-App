import 'package:flutter/material.dart';

import 'package:attendance/core/layout/responsive_context.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/widgets/app_list_tile.dart';

/// List on narrow screens; grid on tablet+ when [columns] > 1.
class AppAdaptiveList extends StatelessWidget {
  const AppAdaptiveList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.header,
    this.padding = const EdgeInsets.all(0),
    this.physics,
    this.onRefresh,
    this.separatorHeight = kAppListTileSpacing,
    this.gridChildAspectRatio = 3.4,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Widget? header;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;
  final Future<void> Function()? onRefresh;
  final double separatorHeight;
  final double gridChildAspectRatio;

  @override
  Widget build(BuildContext context) {
    final columns = context.adaptiveListColumns;

    Widget body;
    if (columns == 1) {
      final count = itemCount + (header != null ? 1 : 0);
      body = ListView.separated(
        physics: physics ?? const AlwaysScrollableScrollPhysics(),
        padding: padding,
        itemCount: count,
        separatorBuilder: (_, __) => SizedBox(height: separatorHeight),
        itemBuilder: (context, index) {
          if (header != null && index == 0) return header!;
          final dataIndex = index - (header != null ? 1 : 0);
          return itemBuilder(context, dataIndex);
        },
      );
    } else {
      body = CustomScrollView(
        physics: physics ?? const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (header != null)
            SliverToBoxAdapter(
              child: Padding(padding: padding.resolve(Directionality.of(context)).copyWith(bottom: 0), child: header),
            ),
          SliverPadding(
            padding: padding,
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: separatorHeight,
                crossAxisSpacing: AppDimensions.spacing16,
                childAspectRatio: gridChildAspectRatio,
              ),
              delegate: SliverChildBuilderDelegate(itemBuilder, childCount: itemCount),
            ),
          ),
        ],
      );
    }

    if (onRefresh != null) {
      body = RefreshIndicator(onRefresh: onRefresh!, child: body);
    }
    return body;
  }
}
