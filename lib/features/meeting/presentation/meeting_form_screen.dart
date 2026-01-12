import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/theme/app_theme.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/meeting/data/meeting_service.dart';
import 'package:attendance/state/lead_provider.dart';
import 'package:attendance/state/meeting_provider.dart';

class MeetingFormScreen extends StatefulWidget {
  const MeetingFormScreen({super.key});

  @override
  State<MeetingFormScreen> createState() => _MeetingFormScreenState();
}

class _MeetingFormScreenState extends State<MeetingFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleC = TextEditingController();
  final _locationC = TextEditingController();
  final _agendaC = TextEditingController();
  final _notesC = TextEditingController();
  final _otherMeetingC = TextEditingController();

  String? _organizer;
  String _meetingType = 'With Team';

  String? _selectedLead;
  String? _selectedClient;
  String? _selectedTeamMember;

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

  static const List<String> _employees = <String>[
    'Aarav Sharma',
    'Isha Verma',
    'Rahul Gupta',
    'Neha Singh',
    'Vikram Mehta',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LeadProvider>().load();
    });
  }

  @override
  void dispose() {
    _titleC.dispose();
    _locationC.dispose();
    _agendaC.dispose();
    _notesC.dispose();
    _otherMeetingC.dispose();
    super.dispose();
  }

  InputDecoration _decoration({required String label, String? hint, Widget? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
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
      _selectedLead = null;
      _selectedClient = null;
      _selectedTeamMember = null;
      _otherMeetingC.text = '';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_organizer == null || _organizer!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select organizer')),
      );
      return;
    }
    if (_start == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start date/time')),
      );
      return;
    }
    if (_end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select end date/time')),
      );
      return;
    }
    if (_end!.isBefore(_start!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    if (_meetingType == 'With Lead' && (_selectedLead == null || _selectedLead!.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select lead')),
      );
      return;
    }

    if (_meetingType == 'With Client' && (_selectedClient == null || _selectedClient!.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select client')),
      );
      return;
    }

    if (_meetingType == 'With Team' && (_selectedTeamMember == null || _selectedTeamMember!.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select employee')),
      );
      return;
    }

    if (_meetingType == 'Other' && _otherMeetingC.text.trim().isEmpty) {
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
        title: _titleC.text.trim(),
        organizer: _organizer!.trim(),
        type: _meetingType,
        lead: _meetingType == 'With Lead' ? _selectedLead : null,
        client: _meetingType == 'With Client' ? _selectedClient : null,
        team: _meetingType == 'With Team' && _selectedTeamMember != null ? <String>[_selectedTeamMember!.trim()] : const <String>[],
        otherMeeting: _meetingType == 'Other' ? _otherMeetingC.text.trim() : null,
        startDateTime: _start!,
        endDateTime: _end!,
        location: _locationC.text.trim().isEmpty ? null : _locationC.text.trim(),
        agenda: _agendaC.text.trim(),
        notes: _notesC.text.trim().isEmpty ? null : _notesC.text.trim(),
        attachments: attachments,
        createdAt: DateTime.now(),
      );

      final ok = await context.read<MeetingProvider>().add(meeting);
      if (!ok) {
        throw context.read<MeetingProvider>().error ?? Exception('Failed');
      }

      messenger.showSnackBar(
        const SnackBar(content: Text('Meeting saved'), backgroundColor: Colors.green),
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
    final leadVm = context.watch<LeadProvider>();
    final leadNames = leadVm.leads.map((l) => l.clientCompany).where((e) => e.trim().isNotEmpty).toSet().toList()..sort();

    final clientNames = leadNames;

    String fmt(DateTime? d) => d == null ? 'Select' : DateFormat('d MMM yyyy, h:mm a').format(d);

    return Scaffold(
      appBar: const GradientAppBar(title: 'New Meeting', showBack: true, showProfileAction: false),
      body: SafeArea(
        child: SingleChildScrollView(
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
                        'Create meeting',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.grey.shade900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Fill the details below to create a meeting.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.3),
                      ),
                      const SizedBox(height: 16),
                      _sectionTitle('Basics', Icons.event_outlined),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _titleC,
                        decoration: _decoration(
                          label: 'Meeting Title *',
                          hint: 'e.g. Weekly sync',
                          prefixIcon: const Icon(Icons.title_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _organizer,
                        items: _employees.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => _organizer = v),
                        decoration: _decoration(
                          label: 'Organizer (Employee) *',
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _meetingType,
                        items: _meetingTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: _onTypeChanged,
                        decoration: _decoration(
                          label: 'Meeting Type *',
                          prefixIcon: const Icon(Icons.category_outlined),
                        ),
                      ),
                      if (_meetingType == 'With Lead') ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedLead,
                          items: leadNames.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                          onChanged: (v) => setState(() => _selectedLead = v),
                          decoration: _decoration(
                            label: 'Select Lead *',
                            prefixIcon: const Icon(Icons.business_center_outlined),
                          ),
                        ),
                      ],
                      if (_meetingType == 'With Client') ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedClient,
                          items: clientNames.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                          onChanged: (v) => setState(() => _selectedClient = v),
                          decoration: _decoration(
                            label: 'Select Client *',
                            prefixIcon: const Icon(Icons.apartment_outlined),
                          ),
                        ),
                      ],
                      if (_meetingType == 'With Team') ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedTeamMember,
                          items: _employees.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => setState(() => _selectedTeamMember = v),
                          decoration: _decoration(
                            label: 'Select Employee *',
                            prefixIcon: const Icon(Icons.group_outlined),
                          ),
                        ),
                      ],
                      if (_meetingType == 'Other') ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _otherMeetingC,
                          decoration: _decoration(
                            label: 'Other meeting *',
                            hint: 'Write meeting type/details',
                            prefixIcon: const Icon(Icons.edit_note_outlined),
                          ),
                          validator: (v) {
                            if (_meetingType != 'Other') return null;
                            return (v == null || v.trim().isEmpty) ? 'Required' : null;
                          },
                        ),
                      ],
                      const SizedBox(height: 18),
                      _sectionTitle('Schedule', Icons.schedule_outlined),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _pickStart,
                        icon: const Icon(Icons.play_arrow_outlined),
                        label: Align(alignment: Alignment.centerLeft, child: Text('Start Date Time: ${fmt(_start)}')),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _pickEnd,
                        icon: const Icon(Icons.stop_outlined),
                        label: Align(alignment: Alignment.centerLeft, child: Text('End Date Time: ${fmt(_end)}')),
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
                      TextFormField(
                        controller: _agendaC,
                        decoration: _decoration(
                          label: 'Agenda *',
                          hint: 'Write agenda...',
                          prefixIcon: const Icon(Icons.subject_outlined),
                        ),
                        maxLines: 3,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
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
                            _attachments.isEmpty ? 'Attachments (multiple)' : 'Attachments: ${_attachments.length} file(s)',
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
                            _submitting ? 'Saving...' : 'Save Meeting',
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
