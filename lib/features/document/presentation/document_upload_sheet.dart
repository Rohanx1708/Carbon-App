import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:attendance/core/widgets/app_loader.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/widgets/app_button.dart';
import 'package:attendance/core/widgets/app_dropdown.dart';
import 'package:attendance/core/widgets/app_text_field.dart';
import 'package:attendance/services/directory_cache_service.dart';
import 'package:attendance/services/directory_service.dart';
import 'package:attendance/state/document_provider.dart';
import 'package:attendance/state/project_provider.dart';

class DocumentUploadSheet extends StatefulWidget {
  const DocumentUploadSheet({super.key});

  @override
  State<DocumentUploadSheet> createState() => _DocumentUploadSheetState();
}

class _DocumentUploadSheetState extends State<DocumentUploadSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleC = TextEditingController(text: 'Attachment');
  String _documentableType = 'lead';
  int? _entityId;
  final _manualIdC = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  List<DirectoryItem> _entities = [];

  bool get _useManualId => _documentableType == 'meeting' || _documentableType == 'task';

  static const _types = [
    ('lead', 'Lead'),
    ('client', 'Client'),
    ('project', 'Project'),
    ('employee', 'Employee'),
    ('meeting', 'Meeting'),
    ('task', 'Task'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEntities());
  }

  @override
  void dispose() {
    _titleC.dispose();
    _manualIdC.dispose();
    super.dispose();
  }

  Future<void> _loadEntities() async {
    setState(() => _loading = true);
    try {
      final cache = DirectoryCacheService.instance;
      List<DirectoryItem> items;
      switch (_documentableType) {
        case 'client':
          items = await cache.clients();
          break;
        case 'employee':
          items = await cache.employees();
          break;
        case 'project':
          await context.read<ProjectProvider>().loadIfNeeded();
          items = context.read<ProjectProvider>().projects.map((p) => DirectoryItem(id: p.id, name: p.name)).toList();
          break;
        case 'meeting':
        case 'task':
          items = const [];
          break;
        case 'lead':
        default:
          items = await cache.leads();
          break;
      }
      if (!mounted) return;
      setState(() {
        _entities = items;
        _entityId = items.isNotEmpty ? items.first.id : null;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        AppFeedback.error(context, e);
      }
    }
  }

  int? get _resolvedEntityId {
    if (_useManualId) return int.tryParse(_manualIdC.text.trim());
    return _entityId;
  }

  Future<void> _upload() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final entityId = _resolvedEntityId;
    if (entityId == null || entityId <= 0) {
      AppFeedback.info(context, 'Select or enter a record');
      return;
    }
    final title = _titleC.text.trim();

    final picked = await FilePicker.platform.pickFiles(withData: false);
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    final path = file.path;
    if (path == null || path.isEmpty) return;

    setState(() => _submitting = true);
    final ok = await context.read<DocumentProvider>().uploadDocument(
      documentableType: _documentableType,
      documentableId: entityId,
      title: title,
      filePath: path,
      filename: file.name,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!ok) {
      AppFeedback.error(context, context.read<DocumentProvider>().error ?? Exception('Upload failed'));
      return;
    }
    AppFeedback.success(context, 'Document uploaded');
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Upload document',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            AppDropdown<String>(
              label: 'Attach to',
              labelAbove: true,
              value: _documentableType,
              items: _types.map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2))).toList(),
              onChanged: (v) async {
                if (v == null) return;
                setState(() => _documentableType = v);
                await _loadEntities();
              },
            ),
            const SizedBox(height: 12),
            if (_useManualId)
              AppTextField(
                controller: _manualIdC,
                label: 'Record ID',
                labelAbove: true,
                required: true,
                keyboardType: TextInputType.number,
                validator: (v) {
                  final id = int.tryParse((v ?? '').trim());
                  if (id == null || id <= 0) return 'Enter a valid record ID';
                  return null;
                },
              )
            else if (_loading)
              const AppLoader(expand: false, size: AppLoaderSize.medium)
            else if (_entities.isEmpty)
              const Text('No records found for this type')
            else
              AppDropdown<int>(
                label: 'Record',
                labelAbove: true,
                required: true,
                value: _entityId,
                items: _entities.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
                onChanged: (v) => setState(() => _entityId = v),
              ),
            const SizedBox(height: 12),
            AppTextField(controller: _titleC, label: 'Title', labelAbove: true, required: true),
            const SizedBox(height: 16),
            AppButton(
              label: 'Choose file & upload',
              loading: _submitting,
              loadingLabel: 'Uploading',
              icon: Icons.upload_file,
              onPressed: _submitting ? null : _upload,
            ),
          ],
        ),
      ),
    );
  }
}
