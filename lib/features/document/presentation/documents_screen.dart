import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/layout/app_layout.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/core/widgets/app_empty_state.dart';
import 'package:attendance/core/widgets/app_error_state.dart';
import 'package:attendance/core/widgets/app_loading_state.dart';
import 'package:attendance/core/widgets/app_skeleton.dart';
import 'package:attendance/core/widgets/app_list_tile.dart';
import 'package:attendance/core/widgets/app_search_field.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/attendance/presentation/app_drawer.dart';
import 'package:attendance/features/document/data/document_service.dart';
import 'package:attendance/features/document/presentation/document_detail_screen.dart';
import 'package:attendance/features/document/presentation/document_type_form_screen.dart';
import 'package:attendance/features/document/presentation/document_upload_sheet.dart';
import 'package:attendance/state/document_provider.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _searchC = TextEditingController();
  String? _typeFilter;

  static const _typeFilters = [
    (null, 'All types'),
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
    _tabs = TabController(length: 2, vsync: this)..addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentProvider>().loadDocumentsIfNeeded(
        query: DocumentListQuery(
          documentableType: _typeFilter,
          search: _searchC.text.trim().isEmpty ? null : _searchC.text.trim(),
        ),
      );
      context.read<DocumentProvider>().loadDocumentTypesIfNeeded();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _refreshDocuments() {
    return context.read<DocumentProvider>().loadDocuments(
      query: DocumentListQuery(
        documentableType: _typeFilter,
        search: _searchC.text.trim().isEmpty ? null : _searchC.text.trim(),
      ),
    );
  }

  Future<void> _openUpload() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const DocumentUploadSheet(),
    );
    if (ok == true && mounted) _refreshDocuments();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentProvider>();

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const GradientAppBar(title: 'Documents'),
      body: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: 'Files'),
                Tab(text: 'Types'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                AppContentContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      AppSearchField(
                        controller: _searchC,
                        hint: 'Search documents…',
                        onSubmitted: (_) => _refreshDocuments(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              value: _typeFilter,
                              decoration: const InputDecoration(labelText: 'Attached to', isDense: true),
                              items: _typeFilters.map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2))).toList(),
                              onChanged: (v) {
                                setState(() => _typeFilter = v);
                                _refreshDocuments();
                              },
                            ),
                          ),
                          IconButton(
                            tooltip: 'Apply search',
                            onPressed: _refreshDocuments,
                            icon: const Icon(Icons.refresh),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: AppLoadingState(
                          isLoading: provider.loading,
                          hasLoaded: provider.hasLoaded,
                          hasData: provider.documents.isNotEmpty,
                          error: provider.error,
                          onRetry: _refreshDocuments,
                          onRefresh: _refreshDocuments,
                          empty: const AppEmptyState(
                            icon: Icons.folder_open_outlined,
                            title: 'No documents',
                            message: 'Upload a file or change filters',
                          ),
                          child: AppAdaptiveList(
                            itemCount: provider.documents.length,
                            itemBuilder: (context, i) {
                              final d = provider.documents[i];
                              return AppListTile(
                                leading: AppListTileLeading.icon(Icons.description_outlined, accent: AppColors.primary),
                                title: d.title,
                                subtitleLines: [
                                  if (d.fileName != null) d.fileName!,
                                  d.documentType.name,
                                  d.attachmentLabel,
                                ],
                                onTap: () async {
                                  final updated = await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(builder: (_) => DocumentDetailScreen(documentId: d.id)),
                                  );
                                  if (updated == true && mounted) _refreshDocuments();
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _DocumentTypesTab(onChanged: () => provider.loadDocumentTypes()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _tabs.index == 0
            ? _openUpload
            : () async {
                final created = await Navigator.of(
                  context,
                ).push<bool>(MaterialPageRoute(builder: (_) => const DocumentTypeFormScreen()));
                if (created == true && mounted) {
                  await provider.loadDocumentTypes();
                }
              },
        child: Icon(_tabs.index == 0 ? Icons.upload_file : Icons.add),
      ),
    );
  }
}

class _DocumentTypesTab extends StatelessWidget {
  const _DocumentTypesTab({required this.onChanged});

  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentProvider>();

    final state = resolveViewState(
      hasData: provider.documentTypes.isNotEmpty,
      isLoading: provider.typesLoading,
      hasLoaded: provider.typesHasLoaded,
      error: provider.typesError,
    );
    if (state == ViewState.loading) {
      return const AppSkeletonList(padding: EdgeInsets.all(16));
    }
    if (state == ViewState.error) {
      return AppErrorState(error: provider.typesError!, onRetry: onChanged);
    }
    if (state == ViewState.empty) {
      return const AppEmptyState(
        icon: Icons.category_outlined,
        title: 'No document types',
        message: 'Tap + to create a type',
      );
    }

    return AppAdaptiveList(
      padding: const EdgeInsets.all(16),
      itemCount: provider.documentTypes.length,
      onRefresh: () async => provider.loadDocumentTypes(),
      itemBuilder: (context, i) {
        final t = provider.documentTypes[i];
        return AppListTile(
          leading: AppListTileLeading.icon(Icons.label_outline, accent: AppColors.info),
          title: t.name,
          subtitleLines: [
            t.category,
            if (t.description.isNotEmpty) t.description,
            t.isMandatory ? 'Mandatory' : 'Optional',
          ],
          trailing: Icon(
            t.isActive ? Icons.check_circle : Icons.remove_circle_outline,
            color: t.isActive ? AppColors.success : context.textSecondary,
            size: 20,
          ),
          onTap: () async {
            final updated = await Navigator.of(
              context,
            ).push<bool>(MaterialPageRoute(builder: (_) => DocumentTypeFormScreen(initial: t)));
            if (updated == true) onChanged();
          },
        );
      },
    );
  }
}
