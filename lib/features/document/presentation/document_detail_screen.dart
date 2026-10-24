import 'package:flutter/material.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/utils/app_date_format.dart';
import 'package:attendance/core/utils/app_open_document.dart';
import 'package:attendance/core/widgets/app_confirm_dialog.dart';
import 'package:attendance/core/widgets/app_detail.dart';
import 'package:attendance/features/document/data/document_service.dart';

class DocumentDetailScreen extends StatefulWidget {
  const DocumentDetailScreen({super.key, required this.documentId});

  final int documentId;

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  final DocumentService _service = DocumentService();
  Future<AppDocument>? _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _service.fetchDocument(widget.documentId);
    });
  }

  static String _size(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _delete(AppDocument doc) async {
    final ok = await AppConfirmDialog.show(
      context,
      title: 'Delete document',
      message: 'Remove "${doc.title}"?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _service.deleteDocument(doc.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) AppFeedback.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppDocument>(
      future: _future,
      builder: (context, snap) {
        final doc = snap.data;
        if (doc == null) {
          final waiting = snap.connectionState == ConnectionState.waiting;
          return AppDetailScaffold(
            title: 'Document',
            loading: waiting || snap.error == null,
            error: waiting ? null : snap.error,
            errorTitle: 'Could not load document',
            onRetry: _reload,
          );
        }

        final hasUrl = (doc.fileUrl ?? '').isNotEmpty;
        return AppDetailScaffold(
          title: 'Document',
          busy: _busy,
          onRefresh: () async => _reload(),
          actions: [
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: _busy ? null : () => _delete(doc),
            ),
          ],
          header: AppDetailHeader(
            title: doc.title,
            icon: Icons.description_outlined,
            subtitle: doc.documentType.name,
            subtitleIcon: Icons.category_outlined,
            caption: doc.fileName,
          ),
          sections: [
            AppDetailSection(
              title: 'File',
              icon: Icons.insert_drive_file_outlined,
              children: [
                AppDetailRow(icon: Icons.description_outlined, label: 'File name', value: doc.fileName),
                AppDetailRow(icon: Icons.category_outlined, label: 'Type', value: doc.documentType.name),
                AppDetailRow(icon: Icons.label_outline, label: 'Category', value: doc.documentType.category),
                if (doc.fileSize != null)
                  AppDetailRow(icon: Icons.sd_storage_outlined, label: 'Size', value: _size(doc.fileSize!)),
              ],
            ),
            AppDetailSection(
              title: 'Record',
              icon: Icons.link_outlined,
              children: [
                AppDetailRow(
                  icon: Icons.link_outlined,
                  label: 'Attached to',
                  value: '${appLabelize(doc.documentableType)} · ID ${doc.documentableId}',
                ),
                AppDetailRow(icon: Icons.person_outline, label: 'Uploaded by', value: doc.uploadedBy?.name),
                AppDetailRow(
                  icon: Icons.schedule_outlined,
                  label: 'Created',
                  value: AppDateFormat.dateTime(doc.createdAt),
                ),
              ],
            ),
          ],
          bottomBar: hasUrl
              ? AppDetailActionBar(
                  children: [
                    FilledButton.icon(
                      onPressed: () => AppOpenDocument.open(context, doc.fileUrl),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open file'),
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }
}
