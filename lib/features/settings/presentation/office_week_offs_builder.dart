import 'package:flutter/material.dart';

import 'package:attendance/features/settings/data/office_settings_service.dart';

/// Supplies the office's weekly off days (0 = Sunday … 6 = Saturday) from the
/// office settings API, using the cached value first.
class OfficeWeekOffsBuilder extends StatefulWidget {
  const OfficeWeekOffsBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, Set<int> weekOffs) builder;

  @override
  State<OfficeWeekOffsBuilder> createState() => _OfficeWeekOffsBuilderState();
}

class _OfficeWeekOffsBuilderState extends State<OfficeWeekOffsBuilder> {
  Set<int> _weekOffs = OfficeSettingsService.cached?.weekOffs.toSet() ?? const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await OfficeSettingsService().fetch();
      if (mounted) setState(() => _weekOffs = settings.weekOffs.toSet());
    } catch (e) {
      debugPrint('[OfficeWeekOffsBuilder] $e');
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _weekOffs);
}
