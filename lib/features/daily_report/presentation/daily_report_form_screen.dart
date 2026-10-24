import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/widgets/app_button.dart';
import 'package:attendance/core/widgets/app_form_page.dart';
import 'package:attendance/core/widgets/app_form_picker_field.dart';
import 'package:attendance/core/widgets/app_form_section_block.dart';
import 'package:attendance/core/widgets/app_picker_fields.dart';
import 'package:attendance/core/widgets/app_selection_chip.dart';
import 'package:attendance/core/widgets/app_text_field.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/daily_report/data/daily_report_models.dart';
import 'package:attendance/features/daily_report/data/daily_report_service.dart';
import 'package:attendance/features/project/data/project_service.dart';
import 'package:attendance/state/profile_provider.dart';

class DailyReportFormScreen extends StatefulWidget {
  const DailyReportFormScreen({super.key, this.existing});

  final DailyWorkReport? existing;

  @override
  State<DailyReportFormScreen> createState() => _DailyReportFormScreenState();
}

class _DailyReportFormScreenState extends State<DailyReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = DailyReportService();
  final _projectService = ProjectService();
  final _descriptionC = TextEditingController();
  final _descFocus = FocusNode();

  DateTime? _date;
  List<Project> _projects = const [];
  final Set<int> _selectedProjectIds = {};
  bool _loadingProjects = true;
  bool _submitting = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _date = DateUtils.dateOnly(DateTime.tryParse(existing.reportDate) ?? DateTime.now());
      _descriptionC.text = existing.editorText;
      _selectedProjectIds.addAll(existing.projectIds);
    } else {
      _date = DateUtils.dateOnly(DateTime.now());
    }
    _loadProjects();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<ProfileProvider>().isAdminOrManager) {
        AppFeedback.info(context, 'Admins and managers cannot submit work reports');
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _descriptionC.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    try {
      final list = await _projectService.all();
      if (!mounted) return;
      setState(() {
        _projects = list;
        _loadingProjects = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingProjects = false);
    }
  }

  List<Project> get _selectedProjects =>
      _projects.where((p) => _selectedProjectIds.contains(p.id)).toList();

  Future<void> _pickProjects() async {
    if (_loadingProjects) {
      AppFeedback.info(context, 'Loading projects…');
      return;
    }
    if (_projects.isEmpty) {
      AppFeedback.info(context, 'No projects available');
      return;
    }

    final draft = Set<int>.from(_selectedProjectIds);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.sizeOf(ctx).height * 0.55,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Select projects', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _projects.length,
                        itemBuilder: (_, i) {
                          final p = _projects[i];
                          final selected = draft.contains(p.id);
                          return CheckboxListTile(
                            value: selected,
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: AppColors.primary,
                            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            onChanged: (v) {
                              setSheet(() {
                                if (v == true) {
                                  draft.add(p.id);
                                } else {
                                  draft.remove(p.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: AppButton(
                        label: 'Done',
                        onPressed: () => Navigator.pop(ctx, true),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (ok == true && mounted) {
      setState(() {
        _selectedProjectIds
          ..clear()
          ..addAll(draft);
      });
    }
  }

  void _wrapSelection(String openTag, String closeTag) {
    final text = _descriptionC.text;
    final sel = _descriptionC.selection;
    final start = sel.start.clamp(0, text.length);
    final end = sel.end.clamp(0, text.length);
    final selected = text.substring(start, end);
    final next = '${text.substring(0, start)}$openTag$selected$closeTag${text.substring(end)}';
    final cursor = start + openTag.length + selected.length + closeTag.length;
    _descriptionC.value = TextEditingValue(text: next, selection: TextSelection.collapsed(offset: cursor));
    _descFocus.requestFocus();
  }

  void _insertList(bool ordered) {
    final text = _descriptionC.text;
    final sel = _descriptionC.selection;
    final start = sel.start.clamp(0, text.length);
    final lineStart = text.lastIndexOf('\n', start - 1) + 1;
    final prefix = ordered ? '1. ' : '• ';
    final next = '${text.substring(0, lineStart)}$prefix${text.substring(lineStart)}';
    _descriptionC.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + prefix.length),
    );
    _descFocus.requestFocus();
  }

  String _toHtml(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (RegExp(r'<(p|ul|ol|li|strong|em|b|i)\b', caseSensitive: false).hasMatch(trimmed)) {
      return trimmed;
    }

    final lines = trimmed.split('\n');
    final buf = StringBuffer();
    var inUl = false;
    var inOl = false;

    void closeLists() {
      if (inUl) {
        buf.write('</ul>');
        inUl = false;
      }
      if (inOl) {
        buf.write('</ol>');
        inOl = false;
      }
    }

    for (final line in lines) {
      final bullet = RegExp(r'^•\s+(.*)$').firstMatch(line);
      final numbered = RegExp(r'^\d+\.\s+(.*)$').firstMatch(line);
      if (bullet != null) {
        if (inOl) {
          buf.write('</ol>');
          inOl = false;
        }
        if (!inUl) {
          buf.write('<ul>');
          inUl = true;
        }
        buf.write('<li>${_inlineHtml(bullet.group(1)!)}</li>');
      } else if (numbered != null) {
        if (inUl) {
          buf.write('</ul>');
          inUl = false;
        }
        if (!inOl) {
          buf.write('<ol>');
          inOl = true;
        }
        buf.write('<li>${_inlineHtml(numbered.group(1)!)}</li>');
      } else {
        closeLists();
        if (line.trim().isEmpty) continue;
        buf.write('<p>${_inlineHtml(line)}</p>');
      }
    }
    closeLists();
    return buf.toString();
  }

  String _inlineHtml(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => '<strong>${m[1]}</strong>')
        .replaceAllMapped(RegExp(r'(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)'), (m) => '<em>${m[1]}</em>');
  }

  Future<void> _submit() async {
    if (_date == null) {
      AppFeedback.error(context, 'Select a report date');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final html = _toHtml(_descriptionC.text);
      final projectIds = _selectedProjectIds.toList()..sort();
      final existing = widget.existing;
      if (existing != null) {
        await _service.update(id: existing.id, projectIds: projectIds, workDone: html);
      } else {
        await _service.submit(date: _date!, projectIds: projectIds, workDone: html);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e);
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = _selectedProjects;

    return Scaffold(
      appBar: GradientAppBar(
        title: _isEdit ? 'Update work report' : 'Submit work report',
        showBack: true,
        showProfileAction: false,
      ),
      body: AppFormPage(
        formKey: _formKey,
        footer: AppButton(
          label: _isEdit ? 'Save changes' : 'Submit report',
          icon: _isEdit ? Icons.check : Icons.send_outlined,
          loading: _submitting,
          loadingLabel: _isEdit ? 'Saving…' : 'Submitting…',
          onPressed: _submitting ? null : _submit,
        ),
        children: [
          AppFormSectionBlock(
            title: 'Report date',
            fields: [
              AppDatePickerField(
                label: 'Date',
                required: true,
                value: _date,
                firstDate: DateTime(2020),
                lastDate: today.add(const Duration(days: 30)),
                onChanged: (d) => setState(() => _date = d),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppFormSectionBlock(
            title: 'Projects',
            fields: [
              AppFormPickerField(
                label: 'Projects',
                optional: true,
                onTap: _pickProjects,
                prefixIcon: const Icon(Icons.folder_outlined, size: 20),
                valueText: selected.isEmpty
                    ? (_loadingProjects ? 'Loading…' : 'Add projects')
                    : '${selected.length} selected',
                isPlaceholder: selected.isEmpty,
              ),
              if (selected.isNotEmpty)
                Wrap(
                  spacing: AppDimensions.spacing8,
                  runSpacing: AppDimensions.spacing8,
                  children: [
                    for (final p in selected)
                      AppSelectionChip(
                        label: p.name,
                        onDeleted: () => setState(() => _selectedProjectIds.remove(p.id)),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          AppFormSectionBlock(
            title: 'Work done',
            fields: [
              Row(
                children: [
                  _FormatBtn(label: 'B', tooltip: 'Bold', bold: true, onTap: () => _wrapSelection('**', '**')),
                  _FormatBtn(label: 'I', tooltip: 'Italic', italic: true, onTap: () => _wrapSelection('*', '*')),
                  _FormatBtn(label: '• List', tooltip: 'Bulleted list', onTap: () => _insertList(false)),
                  _FormatBtn(label: '1. List', tooltip: 'Numbered list', onTap: () => _insertList(true)),
                ],
              ),
              AppTextField(
                controller: _descriptionC,
                focusNode: _descFocus,
                label: 'What did you work on?',
                labelAbove: true,
                required: true,
                hint: 'Use bullets and formatting. Saved as HTML.',
                minLines: 6,
                maxLines: 12,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Describe what you worked on';
                  return null;
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormatBtn extends StatelessWidget {
  const _FormatBtn({required this.label, required this.onTap, this.tooltip, this.bold = false, this.italic = false});

  final String label;
  final VoidCallback onTap;
  final String? tooltip;
  final bool bold;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? label,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          minimumSize: const Size(40, 36),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          foregroundColor: AppColors.textPrimary,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
