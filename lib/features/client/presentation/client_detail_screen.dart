import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/utils/app_open_document.dart';
import 'package:attendance/core/widgets/app_confirm_dialog.dart';
import 'package:attendance/core/widgets/app_detail.dart';
import 'package:attendance/core/widgets/app_prompt_dialog.dart';
import 'package:attendance/features/client/data/client_service.dart';
import 'package:attendance/features/client/presentation/client_form_screen.dart';
import 'package:attendance/state/client_detail_provider.dart';
import 'package:attendance/state/client_provider.dart';

class ClientDetailScreen extends StatelessWidget {
  const ClientDetailScreen({super.key, required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClientDetailProvider(clientId: client.id)..load(),
      child: _ClientDetailBody(fallback: client),
    );
  }
}

class _ClientDetailBody extends StatefulWidget {
  const _ClientDetailBody({required this.fallback});

  final Client fallback;

  @override
  State<_ClientDetailBody> createState() => _ClientDetailBodyState();
}

class _ClientDetailBodyState extends State<_ClientDetailBody> {
  Future<void> _delete(int id) async {
    final ok = await AppConfirmDialog.show(
      context,
      title: 'Delete client?',
      message: 'This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok != true || !mounted) return;
    final success = await context.read<ClientProvider>().deleteById(id);
    if (!mounted) return;
    if (success) {
      AppFeedback.success(context, 'Client deleted');
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _edit(Client c, ClientDetailProvider provider) async {
    final updated = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => ClientFormScreen(initial: c)));
    if (updated == true && mounted) {
      await provider.load();
      if (mounted) context.read<ClientProvider>().refresh();
    }
  }

  Future<void> _upload(ClientDetailProvider provider) async {
    final pick = await FilePicker.platform.pickFiles();
    if (pick == null || pick.files.isEmpty) return;
    final file = pick.files.first;
    final path = file.path;
    if (path == null) return;
    if (!mounted) return;
    if (file.size > 10 * 1024 * 1024) {
      AppFeedback.info(context, 'Max 10 MB');
      return;
    }
    final title = await AppPromptDialog.show(
      context,
      title: 'Upload file',
      initialValue: file.name,
      label: 'Title',
      confirmLabel: 'Upload',
      icon: Icons.upload_file_outlined,
      required: false,
    );
    if (title == null) return;
    final resolvedTitle = title.trim().isEmpty ? file.name : title.trim();
    final success = await provider.uploadDocument(filePath: path, filename: file.name, title: resolvedTitle);
    if (!mounted) return;
    if (success) AppFeedback.success(context, 'File uploaded');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClientDetailProvider>();
    final c = provider.client ?? widget.fallback;
    final detail = provider.detail;
    final projects = detail?.projects ?? const [];
    final docs = provider.documents;

    return AppDetailScaffold(
      title: 'Client Details',
      loading: provider.loading && detail == null,
      onRefresh: provider.load,
      actions: [
        IconButton(
          tooltip: 'Edit',
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          onPressed: () => _edit(c, provider),
        ),
        IconButton(
          tooltip: 'Delete',
          icon: const Icon(Icons.delete_outline, color: Colors.white),
          onPressed: () => _delete(c.id),
        ),
      ],
      header: AppDetailHeader(
        title: c.displayName,
        avatarText: c.displayName,
        subtitle: c.companyName.trim().isNotEmpty && c.companyName != c.displayName ? c.companyName : c.industry,
        subtitleIcon: Icons.corporate_fare_outlined,
        caption: c.companyName.trim().isNotEmpty && c.companyName != c.displayName ? c.industry : null,
        status: c.status,
      ),
      sections: [
        AppDetailSection(
          title: 'Contact',
          icon: Icons.contact_mail_outlined,
          children: [
            AppDetailRow(icon: Icons.person_outline, label: 'Client name', value: c.clientName),
            AppDetailRow(icon: Icons.email_outlined, label: 'Email', value: c.email),
            AppDetailRow(icon: Icons.phone_outlined, label: 'Phone', value: c.phone),
          ],
        ),
        AppDetailSection(
          title: 'Company',
          icon: Icons.business_center_outlined,
          children: [
            AppDetailRow(label: 'Company', value: c.companyName),
            AppDetailRow(label: 'Industry', value: c.industry),
            AppDetailRow(label: 'Address', value: c.address),
          ],
        ),
        if (c.notes.trim().isNotEmpty)
          AppDetailSection(title: 'Notes', icon: Icons.notes_outlined, children: [AppDetailText(c.notes)]),
        AppDetailSection(
          title: 'Projects',
          icon: Icons.folder_outlined,
          count: detail?.projectsCount ?? projects.length,
          children: [
            if (projects.isEmpty)
              const AppDetailEmpty('No projects')
            else
              for (final p in projects)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(p.projectTypeLabel.isNotEmpty ? p.projectTypeLabel : appLabelize(p.projectType)),
                  trailing: AppStatusBadge(label: appLabelize(p.status), tone: appStatusTone(p.status)),
                ),
          ],
        ),
        AppDetailSection(
          title: 'Documents',
          icon: Icons.attach_file,
          count: docs.length,
          trailing: AppDetailSectionAction(label: 'Upload', onPressed: () => _upload(provider)),
          children: [
            if (docs.isEmpty)
              const AppDetailEmpty('No files')
            else
              for (final d in docs)
                AppDetailFileTile(
                  title: d.title,
                  subtitle: d.documentTypeName,
                  onTap: () => AppOpenDocument.open(context, d.fileUrl),
                  onDelete: () async {
                    final ok = await AppConfirmDialog.show(context, title: 'Delete file?', message: d.title);
                    if (ok == true) await provider.deleteDocument(d.id);
                  },
                ),
          ],
        ),
      ],
    );
  }
}
