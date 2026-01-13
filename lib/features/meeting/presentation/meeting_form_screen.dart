import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/theme/app_theme.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/meeting/data/meeting_service.dart';
import 'package:attendance/state/meeting_provider.dart';
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

  static const List<String> _meetingTypes = <String>[
    'With Lead',
    'With Client',
    'With Team',
    'Other',
  ];


  final DirectoryService _directoryService = DirectoryService();
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
      final results = await Future.wait([
        _directoryService.leads(),
        _directoryService.clients(),
        _directoryService.employees(),
      ]);

      if (!mounted) return;
      setState(() {
        _leads = results[0] as List<DirectoryItem>;
        _clients = results[1] as List<DirectoryItem>;
        _employees = results[2] as List<DirectoryItem>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _directoryError = e;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingDirectories = false;
      });
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

  InputDecoration _decoration({
    required String label,
    bool requiredField = false,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final baseLabelStyle = TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500);
    return InputDecoration(
      label: RichText(
        text: TextSpan(
          style: baseLabelStyle,
          children: [
            TextSpan(text: label),
            if (requiredField)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800),
              ),
          ],
        ),
      ),
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      labelStyle: baseLabelStyle,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTheme.primaryBlue.withAlpha((0.6 * 255).round())),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _sectionTitle(String text, IconData icon) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withAlpha((0.12 * 255).round()),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.grey.shade900),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.04 * 255).round()),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _start ?? now,
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start ?? now),
    );
    if (time == null) return;

    setState(() {
      _start = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (_end != null && _start != null && _end!.isBefore(_start!)) {
        _end = null;
      }
    });
  }

  Future<void> _pickEnd() async {
    final now = DateTime.now();
    final base = _start ?? now;

    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
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
    });
  }

  Future<void> _pickAttachments() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: false,
      allowMultiple: true,
    );
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
    if (overlay == null) return;

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
      await _scrollTo(_organizerAnchorKey);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select organizer')),
      );
      return;
    }
    if (_start == null) {
      await _scrollTo(_startAnchorKey);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start date/time')),
      );
      return;
    }
    if (_end == null) {
      await _scrollTo(_endAnchorKey);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select end date/time')),
      );
      return;
    }
    if (_end!.isBefore(_start!)) {
      await _scrollTo(_endAnchorKey);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    if (_meetingType == 'With Lead' && _selectedLeadId == null) {
      await _scrollTo(_leadAnchorKey);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select lead')),
      );
      return;
    }

    if (_meetingType == 'With Client' && _selectedClientId == null) {
      await _scrollTo(_clientAnchorKey);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select client')),
      );
      return;
    }

    if (_meetingType == 'With Team' && _selectedEmployeeIds.isEmpty) {
      await _scrollTo(_employeesAnchorKey);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select employee(s)')),
      );
      return;
    }

    if (_meetingType == 'Other' && _otherMeetingC.text.trim().isEmpty) {
      await _scrollTo(_otherAnchorKey);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter other meeting details')),
      );
      return;
    }

    setState(() => _submitting = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final attachments = _attachments
          .map(
            (f) => MeetingAttachment(name: f.name, path: f.path),
          )
          .toList();

      final meeting = Meeting(
        id: widget.initialMeeting?.id,
        title: _titleC.text.trim(),
        organizer: _organizerId.toString(),
        type: _meetingType,
        lead: _meetingType == 'With Lead' ? _selectedLeadId.toString() : null,
        client: _meetingType == 'With Client' ? _selectedClientId.toString() : null,
        team: _meetingType == 'With Team'
            ? _selectedEmployeeIds.map((e) => e.toString()).toList()
            : const <String>[],
        otherMeeting: _meetingType == 'Other' ? _otherMeetingC.text.trim() : null,
        startDateTime: _start!,
        endDateTime: _end!,
        location: _locationC.text.trim().isEmpty ? null : _locationC.text.trim(),
        agenda: _agendaC.text.trim(),
        notes: _notesC.text.trim().isEmpty ? null : _notesC.text.trim(),
        attachments: attachments,
        createdAt: widget.initialMeeting?.createdAt ?? DateTime.now(),
      );

      final ok = _isEdit
          ? await context.read<MeetingProvider>().update(meeting)
          : await context.read<MeetingProvider>().add(meeting);
      if (!ok) {
        throw context.read<MeetingProvider>().error ?? Exception('Failed');
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Meeting updated' : 'Meeting saved'),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pop(true);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String fmt(DateTime? d) => d == null ? 'Select' : DateFormat('d MMM yyyy, h:mm a').format(d);

    return Scaffold(
      appBar: GradientAppBar(title: _isEdit ? 'Edit Meeting' : 'New Meeting', showBack: true, showProfileAction: false),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isEdit ? 'Edit meeting' : 'Create meeting',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.grey.shade900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isEdit ? 'Update the details below.' : 'Fill the details below to create a meeting.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.3),
                      ),
                      const SizedBox(height: 16),
                      _sectionTitle('Basics', Icons.event_outlined),
                      const SizedBox(height: 12),
                      Container(
                        key: _titleAnchorKey,
                        child: TextFormField(
                          controller: _titleC,
                        decoration: _decoration(
                          label: 'Meeting Title',
                          requiredField: true,
                          hint: 'e.g. Weekly sync',
                          prefixIcon: const Icon(Icons.title_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_loadingDirectories)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: LinearProgressIndicator(minHeight: 3),
                        ),
                      if (_directoryError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(child: Text('Failed to load directories: ${_directoryError.toString()}')),
                              TextButton(
                                onPressed: _loadDirectories,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        key: _organizerAnchorKey,
                        child: DropdownButtonFormField<int>(
                          value: _organizerId,
                          isExpanded: true,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black),
                          items: _employees
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.id,
                                  child: Text(
                                    e.name,
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _organizerId = v),
                          decoration: _decoration(
                            label: 'Organizer (Employee)',
                            requiredField: true,
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        key: _meetingTypeAnchorKey,
                        child: DropdownButtonFormField<String>(
                          value: _meetingType,
                          isExpanded: true,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black),
                          items: _meetingTypes
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                    t,
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: _onTypeChanged,
                          decoration: _decoration(
                            label: 'Meeting Type',
                            requiredField: true,
                            prefixIcon: const Icon(Icons.category_outlined),
                          ),
                        ),
                      ),
                      if (_meetingType == 'With Lead') ...[
                        const SizedBox(height: 12),
                        Container(
                          key: _leadAnchorKey,
                          child: DropdownButtonFormField<int>(
                            value: _selectedLeadId,
                            isExpanded: true,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black),
                            items: _leads
                                .map(
                                  (n) => DropdownMenuItem(
                                    value: n.id,
                                    child: Text(
                                      n.name,
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _selectedLeadId = v),
                            decoration: _decoration(
                              label: 'Select Lead',
                              prefixIcon: const Icon(Icons.business_center_outlined),
                            ),
                          ),
                        ),
                      ],
                      if (_meetingType == 'With Client') ...[
                        const SizedBox(height: 12),
                        Container(
                          key: _clientAnchorKey,
                          child: DropdownButtonFormField<int>(
                            value: _selectedClientId,
                            isExpanded: true,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black),
                            items: _clients
                                .map(
                                  (n) => DropdownMenuItem(
                                    value: n.id,
                                    child: Text(
                                      n.name,
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _selectedClientId = v),
                            decoration: _decoration(
                              label: 'Select Client',
                              prefixIcon: const Icon(Icons.apartment_outlined),
                            ),
                          ),
                        ),
                      ],
                      if (_meetingType == 'With Team') ...[
                        const SizedBox(height: 12),
                        Container(
                          key: _employeesAnchorKey,
                          child: CompositedTransformTarget(
                          link: _employeeDropdownLink,
                          child: InkWell(
                            onTap: _loadingDirectories ? null : _toggleEmployeeDropdown,
                            borderRadius: BorderRadius.circular(14),
                            child: InputDecorator(
                              decoration: _decoration(
                                label: 'Select Employees',
                                requiredField: true,
                                prefixIcon: const Icon(Icons.group_outlined),
                                suffixIcon: Icon(
                                  _employeeDropdownOverlay != null ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                ),
                              ),
                              child: Text(
                                _selectedEmployeeIds.isEmpty
                                    ? 'Tap to select'
                                    : 'Selected: ${_selectedEmployeeIds.length}',
                                style: TextStyle(
                                  color: _selectedEmployeeIds.isEmpty ? Colors.grey.shade600 : Colors.grey.shade900,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          ),
                        ),
                      ],
                      if (_meetingType == 'Other') ...[
                        const SizedBox(height: 12),
                        Container(
                          key: _otherAnchorKey,
                          child: TextFormField(
                            controller: _otherMeetingC,
                          decoration: _decoration(
                            label: 'Other meeting',
                            hint: 'Write meeting type/details',
                            prefixIcon: const Icon(Icons.edit_note_outlined),
                          ),
                          validator: (v) {
                            if (_meetingType != 'Other') return null;
                            return (v == null || v.trim().isEmpty) ? 'Required' : null;
                          },
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _sectionTitle('Schedule', Icons.schedule_outlined),
                      const SizedBox(height: 12),
                      Container(
                        key: _startAnchorKey,
                        child: OutlinedButton.icon(
                          onPressed: _pickStart,
                          icon: const Icon(Icons.play_arrow_outlined),
                          label: Align(alignment: Alignment.centerLeft, child: Text('Start Date Time: ${fmt(_start)}')),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        key: _endAnchorKey,
                        child: OutlinedButton.icon(
                          onPressed: _pickEnd,
                          icon: const Icon(Icons.stop_outlined),
                          label: Align(alignment: Alignment.centerLeft, child: Text('End Date Time: ${fmt(_end)}')),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _locationC,
                        decoration: _decoration(
                          label: 'Location (optional)',
                          hint: 'e.g. Conference Room A',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _sectionTitle('Details', Icons.description_outlined),
                      const SizedBox(height: 12),
                      Container(
                        key: _agendaAnchorKey,
                        child: TextFormField(
                          controller: _agendaC,
                        decoration: _decoration(
                          label: 'Agenda',
                          requiredField: true,
                          hint: 'Write agenda...',
                          prefixIcon: const Icon(Icons.subject_outlined),
                        ),
                        maxLines: 3,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesC,
                        decoration: _decoration(
                          label: 'Notes (optional)',
                          hint: 'Any additional notes...',
                          prefixIcon: const Icon(Icons.sticky_note_2_outlined),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _pickAttachments,
                        icon: const Icon(Icons.attach_file),
                        label: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _attachments.isEmpty ? 'Attachments' : 'Attachments: ${_attachments.length} file(s)',
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      if (_attachments.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _attachments
                              .map(
                                (f) => Chip(
                                  label: Text(
                                    f.name,
                                    style: const TextStyle(color: Colors.black),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onDeleted: () {
                                    setState(() {
                                      _attachments = _attachments.where((x) => x != f).toList();
                                    });
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppTheme.primaryBlue, AppTheme.primaryBlueLight]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withAlpha((0.28 * 255).round()),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _submitting ? null : _submit,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_submitting)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          else
                            const Icon(Icons.save, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            _submitting ? (_isEdit ? 'Updating...' : 'Saving...') : (_isEdit ? 'Update Meeting' : 'Save Meeting'),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
