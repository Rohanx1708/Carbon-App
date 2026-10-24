import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:attendance/core/widgets/app_loader.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/feedback/user_facing_error.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/core/widgets/app_button.dart';
import 'package:attendance/core/widgets/app_choice_segments.dart';
import 'package:attendance/core/widgets/app_date_time_picker_field.dart';
import 'package:attendance/core/widgets/app_dropdown.dart';
import 'package:attendance/core/widgets/app_form_decoration.dart';
import 'package:attendance/core/widgets/app_form_field_label.dart';
import 'package:attendance/core/widgets/app_form_picker_field.dart';
import 'package:attendance/core/widgets/app_form_sticky_bar.dart';
import 'package:attendance/core/widgets/app_labeled_field.dart';
import 'package:attendance/core/widgets/app_section_title.dart';
import 'package:attendance/core/widgets/app_selection_chip.dart';
import 'package:attendance/core/widgets/app_text_field.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/meeting/data/meeting_service.dart';
import 'package:attendance/state/meeting_provider.dart';
import 'package:attendance/services/directory_cache_service.dart';
import 'package:attendance/services/directory_service.dart';

class MeetingFormScreen extends StatefulWidget {
  final Meeting? initialMeeting;

  const MeetingFormScreen({super.key, this.initialMeeting});

  @override
  State<MeetingFormScreen> createState() => _MeetingFormScreenState();
}

class _MeetingFormScreenState extends State<MeetingFormScreen> {
  final _formKey = GlobalKey<FormState>();

  bool get _isEdit => widget.initialMeeting != null;

  final ScrollController _scrollController = ScrollController();

  final GlobalKey _titleAnchorKey = GlobalKey();
  final GlobalKey _organizerAnchorKey = GlobalKey();
  final GlobalKey _meetingTypeAnchorKey = GlobalKey();
  final GlobalKey _leadAnchorKey = GlobalKey();
  final GlobalKey _clientAnchorKey = GlobalKey();
  final GlobalKey _employeesAnchorKey = GlobalKey();
  final GlobalKey _otherAnchorKey = GlobalKey();
  final GlobalKey _startAnchorKey = GlobalKey();
  final GlobalKey _endAnchorKey = GlobalKey();
  final GlobalKey _agendaAnchorKey = GlobalKey();

  final _titleC = TextEditingController();
  final _locationC = TextEditingController();
  final _agendaC = TextEditingController();
  final _notesC = TextEditingController();
  final _otherMeetingC = TextEditingController();

  int? _organizerId;
  String _meetingType = 'With Team';

  int? _selectedLeadId;
  int? _selectedClientId;
  final Set<int> _selectedEmployeeIds = <int>{};

  final LayerLink _employeeDropdownLink = LayerLink();
  OverlayEntry? _employeeDropdownOverlay;

  DateTime? _start;
  DateTime? _end;

  List<PlatformFile> _attachments = <PlatformFile>[];

  bool _submitting = false;

  String? _organizerError;
  String? _startError;
  String? _endError;
  String? _peopleError;
  String? _leadError;
  String? _clientError;

  final DirectoryCacheService _directoryCache = DirectoryCacheService.instance;
  final MeetingService _meetingService = MeetingService();
  bool _loadingDirectories = false;
  Object? _directoryError;
  List<DirectoryItem> _leads = <DirectoryItem>[];
  List<DirectoryItem> _clients = <DirectoryItem>[];
  List<DirectoryItem> _employees = <DirectoryItem>[];

  @override
  void initState() {
    super.initState();
    _applyInitialMeeting();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadDirectories();
    });
  }

  void _applyInitialMeeting() {
    final m = widget.initialMeeting;
    if (m == null) return;

    _titleC.text = m.title;
    _locationC.text = (m.location ?? '');
    _agendaC.text = m.agenda;
    _notesC.text = (m.notes ?? '');
    _otherMeetingC.text = (m.otherMeeting ?? '');

    _meetingType = m.type;
    _organizerId = int.tryParse(m.organizer);
    _selectedLeadId = int.tryParse((m.lead ?? '').trim());
    _selectedClientId = int.tryParse((m.client ?? '').trim());
    _selectedEmployeeIds
      ..clear()
      ..addAll(m.team.map((e) => int.tryParse(e)).whereType<int>());

    _start = m.startDateTime;
    _end = m.endDateTime;
  }

  Future<void> _loadDirectories() async {
    setState(() {
      _loadingDirectories = true;
      _directoryError = null;
    });
    try {
      final results = await _directoryCache.loadAll();

      if (!mounted) return;
      setState(() {
        _leads = results.leads;
        _clients = results.clients;
        _employees = results.employees;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _directoryError = e;
      });
    } finally {
      if (mounted) {
        setState(() => _loadingDirectories = false);
      }
    }
  }

  @override
  void dispose() {
    _closeEmployeeDropdown();
    _scrollController.dispose();
    _titleC.dispose();
    _locationC.dispose();
    _agendaC.dispose();
    _notesC.dispose();
    _otherMeetingC.dispose();
    super.dispose();
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: 0.15,
    );
  }

  void _onTypeChangedSegment(String next) {
    _onTypeChanged(next);
    setState(() {
      _leadError = null;
      _clientError = null;
      _peopleError = null;
    });
  }

  String _peopleSummary() {
    if (_selectedEmployeeIds.isEmpty) return 'Choose people';
    final selected = _employees.where((e) => _selectedEmployeeIds.contains(e.id)).toList();
    if (selected.isEmpty) return 'Choose people';
    if (selected.length == 1) return selected.first.name;
    return '${selected.length} people selected';
  }

  List<Widget> _selectedPeopleChips() {
    final selected = _employees.where((e) => _selectedEmployeeIds.contains(e.id)).toList();
    if (selected.isEmpty) return const [];
    return [
      const SizedBox(height: AppDimensions.spacing8),
      Wrap(
        spacing: AppDimensions.spacing8,
        runSpacing: AppDimensions.spacing8,
        children: selected
            .map(
              (e) => AppSelectionChip(
                label: e.name,
                onDeleted: () {
                  setState(() {
                    _selectedEmployeeIds.remove(e.id);
                    _peopleError = null;
                  });
                },
              ),
            )
            .toList(),
      ),
    ];
  }

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _start ?? now,
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_start ?? now));
    if (time == null) return;

    setState(() {
      _start = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _startError = null;
      if (_end != null && _start != null && _end!.isBefore(_start!)) {
        _end = null;
        _endError = null;
      }
    });
  }

  Future<void> _pickEnd() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final base = _start ?? now;

    final date = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _end ?? base,
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_end ?? base.add(const Duration(hours: 1))),
    );
    if (time == null) return;

    setState(() {
      _end = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _endError = null;
    });
  }

  Future<void> _pickAttachments() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.any, withData: false, allowMultiple: true);
    if (res != null && res.files.isNotEmpty) {
      setState(() {
        _attachments = List<PlatformFile>.from(res.files);
      });
    }
  }

  void _onTypeChanged(String? v) {
    final next = v ?? 'With Team';
    setState(() {
      _meetingType = next;
      _selectedLeadId = null;
      _selectedClientId = null;
      _selectedEmployeeIds.clear();
      _otherMeetingC.text = '';
    });
    _closeEmployeeDropdown();
  }

  void _closeEmployeeDropdown() {
    _employeeDropdownOverlay?.remove();
    _employeeDropdownOverlay = null;
  }

  void _toggleEmployeeDropdown() {
    if (_employeeDropdownOverlay != null) {
      _closeEmployeeDropdown();
      return;
    }

    final overlay = Overlay.of(context);

    final box = context.findRenderObject() as RenderBox?;
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (box == null || overlayBox == null) return;

    _employeeDropdownOverlay = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeEmployeeDropdown,
                child: const SizedBox.shrink(),
              ),
            ),
            CompositedTransformFollower(
              link: _employeeDropdownLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 56),
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(14),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260, minWidth: 320),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: _employees
                        .map(
                          (e) => StatefulBuilder(
                            builder: (context, setStateTile) {
                              final checked = _selectedEmployeeIds.contains(e.id);
                              return CheckboxListTile(
                                value: checked,
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                title: Text(
                                  e.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                controlAffinity: ListTileControlAffinity.leading,
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      _selectedEmployeeIds.add(e.id);
                                    } else {
                                      _selectedEmployeeIds.remove(e.id);
                                    }
                                  });
                                  setStateTile(() {});
                                },
                              );
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_employeeDropdownOverlay!);
  }

  Future<void> _submit() async {
    if (_submitting) return;

    setState(() {
      _organizerError = null;
      _startError = null;
      _endError = null;
      _peopleError = null;
      _leadError = null;
      _clientError = null;
    });

    final ok = _formKey.currentState!.validate();
    if (!ok) {
      if (_titleC.text.trim().isEmpty) {
        await _scrollTo(_titleAnchorKey);
        return;
      }
      if (_agendaC.text.trim().isEmpty) {
        await _scrollTo(_agendaAnchorKey);
        return;
      }
      if (_meetingType == 'Other' && _otherMeetingC.text.trim().isEmpty) {
        await _scrollTo(_otherAnchorKey);
        return;
      }
      return;
    }
    if (_organizerId == null) {
      setState(() => _organizerError = 'Please select organizer');
      await _scrollTo(_organizerAnchorKey);
      return;
    }
    if (_start == null) {
      setState(() => _startError = 'Please select start date and time');
      await _scrollTo(_startAnchorKey);
      return;
    }
    if (_end == null) {
      setState(() => _endError = 'Please select end date and time');
      await _scrollTo(_endAnchorKey);
      return;
    }
    if (_end!.isBefore(_start!)) {
      setState(() => _endError = 'End must be after start');
      await _scrollTo(_endAnchorKey);
      return;
    }

    final now = DateTime.now();
    if (_start!.isBefore(now)) {
      setState(() => _startError = 'Start cannot be in the past');
      await _scrollTo(_startAnchorKey);
      return;
    }
    if (_end!.isBefore(now)) {
      setState(() => _endError = 'End cannot be in the past');
      await _scrollTo(_endAnchorKey);
      return;
    }

    if (_meetingType == 'With Lead' && _selectedLeadId == null) {
      setState(() => _leadError = 'Please select a lead');
      await _scrollTo(_leadAnchorKey);
      return;
    }

    if (_meetingType == 'With Client' && _selectedClientId == null) {
      setState(() => _clientError = 'Please select a client');
      await _scrollTo(_clientAnchorKey);
      return;
    }

    if (_meetingType == 'With Team' && _selectedEmployeeIds.isEmpty) {
      setState(() => _peopleError = 'Select at least one person');
      await _scrollTo(_employeesAnchorKey);
      return;
    }

    if (_meetingType == 'Other' && _otherMeetingC.text.trim().isEmpty) {
      await _scrollTo(_otherAnchorKey);
      return;
    }

    if (!_isEdit) {
      final conflictEmployeeIds = <int>{_organizerId!};
      if (_meetingType == 'With Team') {
        conflictEmployeeIds.addAll(_selectedEmployeeIds);
      }

      for (final employeeId in conflictEmployeeIds) {
        final conflicts = await _meetingService.checkConflicts(
          employeeId: employeeId,
          startDateTime: _start!,
          endDateTime: _end!,
        );
        if (conflicts.hasAny) {
          AppFeedback.error(context, Exception('Schedule conflict detected for an attendee'));
          return;
        }
      }
    }

    setState(() => _submitting = true);

    final navigator = Navigator.of(context);

    try {
      final attachments = _attachments.map((f) => MeetingAttachment(name: f.name, path: f.path)).toList();

      final meeting = Meeting(
        id: widget.initialMeeting?.id,
        title: _titleC.text.trim(),
        organizer: _organizerId.toString(),
        type: _meetingType,
        lead: _meetingType == 'With Lead' ? _selectedLeadId.toString() : null,
        client: _meetingType == 'With Client' ? _selectedClientId.toString() : null,
        team: _meetingType == 'With Team' ? _selectedEmployeeIds.map((e) => e.toString()).toList() : const <String>[],
        otherMeeting: _meetingType == 'Other' ? _otherMeetingC.text.trim() : null,
        startDateTime: _start!,
        endDateTime: _end!,
        location: _locationC.text.trim().isEmpty ? null : _locationC.text.trim(),
        agenda: _agendaC.text.trim(),
        notes: _notesC.text.trim().isEmpty ? null : _notesC.text.trim(),
        attachments: attachments,
        createdAt: widget.initialMeeting?.createdAt ?? DateTime.now(),
      );

      if (_isEdit) {
        final ok = await context.read<MeetingProvider>().update(meeting);
        if (!ok) {
          throw context.read<MeetingProvider>().error ?? Exception('Failed');
        }
      } else {
        final newId = await context.read<MeetingProvider>().addAndGetId(meeting);
        if (newId == null) {
          throw context.read<MeetingProvider>().error ?? Exception('Failed');
        }
        for (final file in _attachments) {
          final path = file.path;
          if (path == null || path.isEmpty) continue;
          await _meetingService.uploadDocument(meetingId: newId, filePath: path, filename: file.name, title: file.name);
        }
      }

      if (!mounted) return;
      AppFeedback.success(context, _isEdit ? 'Meeting updated' : 'Meeting saved');
      navigator.pop(true);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  static const _fieldGap = AppDimensions.spacing12;
  static const _sectionGap = AppDimensions.spacing24;

  Widget _section(String title, List<Widget> fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionTitle(title: title),
        const SizedBox(height: AppDimensions.spacing12),
        for (var i = 0; i < fields.length; i++) ...[if (i > 0) const SizedBox(height: _fieldGap), fields[i]],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(title: _isEdit ? 'Edit Meeting' : 'New Meeting', showBack: true, showProfileAction: false),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _section('Meeting', [
                      Container(
                        key: _titleAnchorKey,
                        child: AppTextField(
                          controller: _titleC,
                          label: 'Title',
                          labelAbove: true,
                          required: true,
                          hint: 'Enter meeting title',
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.sentences,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
                        ),
                      ),
                      if (_loadingDirectories)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(child: AppProgress(size: AppLoaderSize.small)),
                        ),
                      if (_directoryError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  UserFacingError.from(_directoryError!),
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ),
                              TextButton(onPressed: _loadDirectories, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      Container(
                        key: _organizerAnchorKey,
                        child: AppDropdown<int>(
                          value: _organizerId,
                          label: 'Organizer',
                          labelAbove: true,
                          required: true,
                          hint: 'Select organizer',
                          errorText: _organizerError,
                          items: _employees
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.id,
                                  child: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                              )
                              .toList(),
                          onChanged: _loadingDirectories
                              ? null
                              : (v) => setState(() {
                                  _organizerId = v;
                                  _organizerError = null;
                                }),
                        ),
                      ),
                      Column(
                        key: _meetingTypeAnchorKey,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const AppFormFieldLabel(text: 'Meeting type', required: true),
                          const SizedBox(height: kAppFormLabelGap),
                          AppChoiceSegments<String>(
                            value: _meetingType,
                            onChanged: _onTypeChangedSegment,
                            options: const [
                              AppSegmentOption(value: 'With Team', label: 'Team'),
                              AppSegmentOption(value: 'With Client', label: 'Client'),
                              AppSegmentOption(value: 'With Lead', label: 'Lead'),
                              AppSegmentOption(value: 'Other', label: 'Other'),
                            ],
                          ),
                        ],
                      ),
                      if (_meetingType == 'With Lead')
                        Container(
                          key: _leadAnchorKey,
                          child: AppDropdown<int>(
                            value: _selectedLeadId,
                            label: 'Lead',
                            labelAbove: true,
                            required: true,
                            hint: 'Select lead',
                            errorText: _leadError,
                            items: _leads
                                .map(
                                  (n) => DropdownMenuItem(
                                    value: n.id,
                                    child: Text(n.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() {
                              _selectedLeadId = v;
                              _leadError = null;
                            }),
                          ),
                        ),
                      if (_meetingType == 'With Client')
                        Container(
                          key: _clientAnchorKey,
                          child: AppDropdown<int>(
                            value: _selectedClientId,
                            label: 'Client',
                            labelAbove: true,
                            required: true,
                            hint: 'Select client',
                            errorText: _clientError,
                            items: _clients
                                .map(
                                  (n) => DropdownMenuItem(
                                    value: n.id,
                                    child: Text(n.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() {
                              _selectedClientId = v;
                              _clientError = null;
                            }),
                          ),
                        ),
                      if (_meetingType == 'With Team')
                        Container(
                          key: _employeesAnchorKey,
                          child: AppLabeledField(
                            label: 'People',
                            required: true,
                            errorText: _peopleError,
                            child: CompositedTransformTarget(
                              link: _employeeDropdownLink,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  InkWell(
                                    onTap: _loadingDirectories ? null : _toggleEmployeeDropdown,
                                    borderRadius: BorderRadius.circular(AppDimensions.radius12),
                                    child: InputDecorator(
                                      decoration: AppFormDecoration.input(
                                        prefixIcon: const Icon(Icons.group_outlined, size: 20),
                                        suffixIcon: Icon(
                                          _employeeDropdownOverlay != null
                                              ? Icons.keyboard_arrow_up
                                              : Icons.keyboard_arrow_down,
                                          size: 22,
                                        ),
                                      ),
                                      child: Text(
                                        _peopleSummary(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _selectedEmployeeIds.isEmpty
                                              ? context.textSecondary
                                              : context.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  ..._selectedPeopleChips(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (_meetingType == 'Other')
                        Container(
                          key: _otherAnchorKey,
                          child: AppTextField(
                            controller: _otherMeetingC,
                            label: 'Other meeting',
                            labelAbove: true,
                            required: true,
                            hint: 'Describe this meeting',
                            textCapitalization: TextCapitalization.sentences,
                            validator: (v) {
                              if (_meetingType != 'Other') return null;
                              return (v == null || v.trim().isEmpty) ? 'Required' : null;
                            },
                          ),
                        ),
                    ]),
                    const SizedBox(height: _sectionGap),
                    _section('When', [
                      Container(
                        key: _startAnchorKey,
                        child: AppDateTimePickerField(
                          label: 'Start',
                          required: true,
                          value: _start,
                          onTap: _pickStart,
                          errorText: _startError,
                          placeholder: 'Select start',
                        ),
                      ),
                      Container(
                        key: _endAnchorKey,
                        child: AppDateTimePickerField(
                          label: 'End',
                          required: true,
                          value: _end,
                          onTap: _pickEnd,
                          errorText: _endError,
                          placeholder: 'Select end',
                        ),
                      ),
                      AppTextField(
                        controller: _locationC,
                        label: 'Location',
                        labelAbove: true,
                        optional: true,
                        hint: 'Add location',
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                      ),
                    ]),
                    const SizedBox(height: _sectionGap),
                    _section('Details', [
                      Container(
                        key: _agendaAnchorKey,
                        child: AppTextField(
                          controller: _agendaC,
                          label: 'Agenda',
                          labelAbove: true,
                          required: true,
                          hint: 'What will you discuss?',
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.next,
                          maxLines: 2,
                          minLines: 2,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter an agenda' : null,
                        ),
                      ),
                      AppTextField(
                        controller: _notesC,
                        label: 'Notes',
                        labelAbove: true,
                        optional: true,
                        hint: 'Any additional notes...',
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.done,
                        maxLines: 2,
                        minLines: 2,
                      ),
                      AppFormPickerField(
                        label: 'Attachments',
                        optional: true,
                        onTap: _pickAttachments,
                        prefixIcon: const Icon(Icons.attach_file, size: 20),
                        valueText: _attachments.isEmpty ? 'Add attachment' : '${_attachments.length} selected',
                        isPlaceholder: _attachments.isEmpty,
                      ),
                      if (_attachments.isNotEmpty)
                        Wrap(
                          spacing: AppDimensions.spacing8,
                          runSpacing: AppDimensions.spacing8,
                          children: _attachments
                              .map(
                                (f) => AppSelectionChip(
                                  label: f.name,
                                  onDeleted: () {
                                    setState(() {
                                      _attachments = _attachments.where((x) => x != f).toList();
                                    });
                                  },
                                ),
                              )
                              .toList(),
                        ),
                    ]),
                    const SizedBox(height: AppDimensions.spacing32),
                  ],
                ),
              ),
            ),
          ),
          AppFormStickyBar(
            child: AppButton(
              label: _isEdit ? 'Update meeting' : 'Save meeting',
              loading: _submitting,
              loadingLabel: _isEdit ? 'Updating' : 'Saving',
              icon: Icons.check,
              onPressed: _submitting ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }
}
