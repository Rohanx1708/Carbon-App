import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/layout/app_layout.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/core/utils/app_date_format.dart';
import 'package:attendance/core/widgets/app_button.dart';
import 'package:attendance/core/widgets/app_error_state.dart';
import 'package:attendance/core/widgets/app_loader.dart';
import 'package:attendance/core/widgets/app_text_field.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/attendance/data/office_geofence.dart';
import 'package:attendance/features/settings/data/office_settings_service.dart';
import 'package:attendance/state/profile_provider.dart';

class OfficeSettingsScreen extends StatefulWidget {
  const OfficeSettingsScreen({super.key});

  @override
  State<OfficeSettingsScreen> createState() => _OfficeSettingsScreenState();
}

class _OfficeSettingsScreenState extends State<OfficeSettingsScreen> {
  final OfficeSettingsService _service = OfficeSettingsService();

  final _quotaC = TextEditingController();
  final _latC = TextEditingController();
  final _lngC = TextEditingController();
  final _radiusC = TextEditingController();

  OfficeSettings? _settings;
  TimeOfDay? _start;
  TimeOfDay? _end;
  Set<int> _weekOffs = {};
  bool _geofenceEnabled = false;
  bool _loading = true;
  bool _saving = false;
  bool _locating = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    for (final c in [_quotaC, _latC, _lngC, _radiusC]) {
      c.addListener(_onFieldChanged);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ProfileProvider>().loadIfNeeded();
      if (mounted) await _load();
    });
  }

  @override
  void dispose() {
    for (final c in [_quotaC, _latC, _lngC, _radiusC]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  void _apply(OfficeSettings s) {
    _settings = s;
    _start = OfficeSettings.parseTime(s.startTime);
    _end = OfficeSettings.parseTime(s.endTime);
    _weekOffs = s.weekOffs.toSet();
    _geofenceEnabled = s.geofenceEnabled;
    _quotaC.text = s.annualLeaveQuota.toString();
    _latC.text = s.latitude?.toString() ?? '';
    _lngC.text = s.longitude?.toString() ?? '';
    _radiusC.text = _trimNum(s.geofenceRadius);
  }

  static String _trimNum(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final settings = await _service.fetch();
      if (!mounted) return;
      setState(() {
        _apply(settings);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _pickStart() async {
    final picked = await showTimePicker(context: context, initialTime: _start ?? const TimeOfDay(hour: 9, minute: 30));
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showTimePicker(context: context, initialTime: _end ?? const TimeOfDay(hour: 18, minute: 30));
    if (picked != null) setState(() => _end = picked);
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final pos = await OfficeGeofence.currentPosition(action: 'set the office location');
      if (!mounted) return;
      setState(() {
        _latC.text = pos.latitude.toStringAsFixed(6);
        _lngC.text = pos.longitude.toStringAsFixed(6);
      });
      AppFeedback.success(context, 'Office location set to your current position');
    } catch (e) {
      if (mounted) AppFeedback.error(context, e);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  double? get _lat => double.tryParse(_latC.text.trim());
  double? get _lng => double.tryParse(_lngC.text.trim());
  double? get _radius => double.tryParse(_radiusC.text.trim());
  int? get _quota => int.tryParse(_quotaC.text.trim());

  String? get _validationError {
    if (_start == null || _end == null) return 'Select both start and end time';
    if (_rangeInvalid) return 'End time must be after start time';
    if (_quota == null || _quota! < 0) return 'Enter a valid annual leave quota';
    if (_geofenceEnabled) {
      final lat = _lat;
      final lng = _lng;
      if (lat == null || lat < -90 || lat > 90) return 'Enter a valid office latitude (-90 to 90)';
      if (lng == null || lng < -180 || lng > 180) return 'Enter a valid office longitude (-180 to 180)';
      if (_radius == null || _radius! <= 0) return 'Enter a geofence radius greater than 0';
    }
    return null;
  }

  Future<void> _save() async {
    final problem = _validationError;
    if (problem != null) {
      AppFeedback.error(context, problem);
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = await _service.update(
        startTime: OfficeSettings.formatTime(_start!),
        endTime: OfficeSettings.formatTime(_end!),
        weekOffs: _weekOffs.toList()..sort(),
        annualLeaveQuota: _quota!,
        geofenceEnabled: _geofenceEnabled,
        latitude: _lat,
        longitude: _lng,
        geofenceRadius: _radius ?? _settings?.geofenceRadius ?? 100,
      );
      if (!mounted) return;
      setState(() {
        _apply(updated);
        _saving = false;
      });
      AppFeedback.success(context, 'Office settings updated');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppFeedback.error(context, e);
    }
  }

  int? _minutes(TimeOfDay? t) => t == null ? null : t.hour * 60 + t.minute;

  int? get _durationMinutes {
    final s = _minutes(_start);
    final e = _minutes(_end);
    if (s == null || e == null || e <= s) return null;
    return e - s;
  }

  bool get _rangeInvalid => _start != null && _end != null && _durationMinutes == null;

  bool get _dirty {
    final s = _settings;
    if (s == null) return true;
    final sortedOffs = (_weekOffs.toList()..sort()).join(',');
    final originalOffs = (s.weekOffs.toList()..sort()).join(',');
    return _minutes(_start) != _minutes(OfficeSettings.parseTime(s.startTime)) ||
        _minutes(_end) != _minutes(OfficeSettings.parseTime(s.endTime)) ||
        sortedOffs != originalOffs ||
        _quota != s.annualLeaveQuota ||
        _geofenceEnabled != s.geofenceEnabled ||
        _lat != s.latitude ||
        _lng != s.longitude ||
        _radius != s.geofenceRadius;
  }

  String _display(TimeOfDay? t, String? fallback) =>
      t != null ? OfficeSettings.displayTime(OfficeSettings.formatTime(t)) : OfficeSettings.displayTime(fallback ?? '');

  static String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '$h ${h == 1 ? 'hour' : 'hours'}';
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final canEdit = profile.canEditOfficeTiming;
    final showAdminFields = profile.isAdmin;
    final scheme = Theme.of(context).colorScheme;
    final startText = _display(_start, _settings?.startTime);
    final endText = _display(_end, _settings?.endTime);
    final duration = _durationMinutes;
    final decimal = [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))];

    return Scaffold(
      appBar: const GradientAppBar(title: 'Office settings', showBack: true, showProfileAction: false),
      body: AppContentContainer(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const AppLoader(message: 'Loading settings')
            : _error != null && _settings == null
            ? AppErrorState(error: _error!, onRetry: _load)
            : ListView(
                children: [
                  Text(
                    showAdminFields ? 'Office settings' : 'Office hours',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    showAdminFields
                        ? (canEdit
                              ? 'Hours, week offs, leave quota and attendance area used across the app.'
                              : 'Office settings (view only). Contact an admin to change these.')
                        : 'Office hours (view only). Contact an admin to change these.',
                    style: TextStyle(fontSize: 14, color: context.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  _SummaryCard(
                    range: '$startText  –  $endText',
                    duration: duration == null ? null : _formatDuration(duration),
                    readOnly: !canEdit,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _TimeTile(
                          label: 'Start time',
                          value: startText,
                          icon: Icons.login_rounded,
                          accent: const Color(0xFF16A34A),
                          onTap: canEdit ? _pickStart : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TimeTile(
                          label: 'End time',
                          value: endText,
                          icon: Icons.logout_rounded,
                          accent: const Color(0xFFEA580C),
                          error: _rangeInvalid,
                          onTap: canEdit ? _pickEnd : null,
                        ),
                      ),
                    ],
                  ),
                  if (_rangeInvalid) ...[
                    const SizedBox(height: 10),
                    _InlineError('End time must be after start time', color: scheme.error),
                  ],
                  if (showAdminFields) ...[
                    const SizedBox(height: 16),
                    _SectionCard(
                      icon: Icons.event_busy_outlined,
                      title: 'Week offs',
                      subtitle: 'Days the office is closed every week',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var d = 0; d < 7; d++)
                            FilterChip(
                              label: Text(
                                OfficeSettings.weekdayLabels[d],
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: _weekOffs.contains(d) ? AppColors.surface : AppColors.textSecondary,
                                ),
                              ),
                              selected: _weekOffs.contains(d),
                              showCheckmark: false,
                              color: WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) return AppColors.primary;
                                return AppColors.background;
                              }),
                              side: BorderSide(
                                color: _weekOffs.contains(d) ? AppColors.primary : AppColors.border,
                              ),
                              onSelected: canEdit
                                  ? (on) => setState(() => on ? _weekOffs.add(d) : _weekOffs.remove(d))
                                  : null,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      icon: Icons.beach_access_outlined,
                      title: 'Leave',
                      subtitle: 'Paid leave days each employee gets per year',
                      child: AppTextField(
                        controller: _quotaC,
                        label: 'Annual leave quota (days)',
                        labelAbove: true,
                        required: true,
                        enabled: canEdit,
                        hint: 'e.g. 12',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      icon: Icons.my_location_rounded,
                      title: 'Attendance area',
                      subtitle: _geofenceEnabled
                          ? 'Check in/out only works within the radius below'
                          : 'Check in/out works from anywhere',
                      trailing: Switch(
                        value: _geofenceEnabled,
                        onChanged: canEdit ? (v) => setState(() => _geofenceEnabled = v) : null,
                      ),
                      child: !_geofenceEnabled
                          ? null
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppTextField(
                                        controller: _latC,
                                        label: 'Latitude',
                                        labelAbove: true,
                                        required: true,
                                        enabled: canEdit,
                                        hint: 'e.g. 30.336314',
                                        keyboardType: const TextInputType.numberWithOptions(
                                          decimal: true,
                                          signed: true,
                                        ),
                                        inputFormatters: decimal,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: AppTextField(
                                        controller: _lngC,
                                        label: 'Longitude',
                                        labelAbove: true,
                                        required: true,
                                        enabled: canEdit,
                                        hint: 'e.g. 78.053304',
                                        keyboardType: const TextInputType.numberWithOptions(
                                          decimal: true,
                                          signed: true,
                                        ),
                                        inputFormatters: decimal,
                                      ),
                                    ),
                                  ],
                                ),
                                if (canEdit) ...[
                                  const SizedBox(height: 10),
                                  OutlinedButton.icon(
                                    onPressed: _locating ? null : _useCurrentLocation,
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(44),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: _locating
                                        ? const AppProgress(size: AppLoaderSize.small)
                                        : const Icon(Icons.gps_fixed_rounded, size: 18),
                                    label: Text(_locating ? 'Getting location…' : 'Use my current location'),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                AppTextField(
                                  controller: _radiusC,
                                  label: 'Radius (metres)',
                                  labelAbove: true,
                                  required: true,
                                  enabled: canEdit,
                                  hint: 'e.g. 100',
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(5),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ],
                  if (_settings != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.history_rounded, size: 16, color: context.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Last updated ${AppDateFormat.dateTime(_settings!.updatedAt)}',
                            style: TextStyle(fontSize: 12.5, color: context.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (canEdit) ...[
                    const SizedBox(height: 24),
                    AppButton(
                      label: _dirty ? 'Save settings' : 'No changes to save',
                      icon: Icons.save_outlined,
                      loading: _saving,
                      loadingLabel: 'Saving…',
                      onPressed: _saving || !_dirty || _rangeInvalid ? null : _save,
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError(this.message, {required this.color});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.error_outline_rounded, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.icon, required this.title, required this.subtitle, this.trailing, this.child});

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: context.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12.5, color: context.textSecondary)),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (child != null) ...[const SizedBox(height: 14), child!],
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.range, required this.duration, required this.readOnly});

  final String range;
  final String? duration;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, Color.lerp(primary, Colors.black, 0.25)!],
        ),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.business_center_outlined, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Working hours',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    range,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          if (duration != null || readOnly) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(readOnly ? Icons.lock_outline_rounded : Icons.timelapse_rounded, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    duration ?? 'View only',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.error = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = error ? scheme.error : scheme.outlineVariant.withValues(alpha: 0.6);
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: error ? 1.5 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 17, color: accent),
                  ),
                  const Spacer(),
                  if (onTap != null) Icon(Icons.edit_outlined, size: 16, color: context.textSecondary),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: context.textSecondary),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: error ? scheme.error : context.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
