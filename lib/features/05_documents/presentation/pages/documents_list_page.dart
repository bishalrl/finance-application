import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/router.dart';
import '../../domain/entities/document.dart';
import '../bloc/document_bloc.dart';
import '../bloc/document_event.dart';
import '../bloc/document_state.dart';
import 'add_document_page.dart';

class DocumentsListPage extends StatelessWidget {
  const DocumentsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocConsumer<DocumentBloc, DocumentState>(
      listenWhen: (prev, curr) => prev.errorMessage != curr.errorMessage && curr.errorMessage != null,
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!), backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: state.isSearching
                ? TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search documents...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: screenWidth * 0.04),
                    ),
                    style: TextStyle(fontSize: screenWidth * 0.04),
                    onChanged: (q) {
                      context.read<DocumentBloc>().add(SearchQueryChanged(q));
                    },
                    onSubmitted: (q) {
                      context.read<DocumentBloc>().add(SearchDocumentsEvent(q));
                    },
                  )
                : Text('Documents', style: TextStyle(fontSize: screenWidth * 0.05)),
            actions: [
              IconButton(
                icon: Icon(state.isSearching ? Icons.close : Icons.search, size: screenWidth * 0.06),
                onPressed: () {
                  context.read<DocumentBloc>().add(const ToggleSearch());
                  if (!state.isSearching) {
                    context.read<DocumentBloc>().add(const ClearSearch());
                  }
                },
              ),
              if (!state.isSearching)
                IconButton(
                  icon: Icon(Icons.add, size: screenWidth * 0.06),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => BlocProvider.value(
                        value: context.read<DocumentBloc>(),
                        child: const AddDocumentPage(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: Builder(
            builder: (context) {
              if (state.status == DocumentStatus.loading && state.documents.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == DocumentStatus.error && state.documents.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.06),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.errorMessage ?? 'Failed to load', textAlign: TextAlign.center, style: TextStyle(fontSize: screenWidth * 0.04)),
                        SizedBox(height: screenHeight * 0.02),
                        TextButton(
                          onPressed: () => context.read<DocumentBloc>().add(const LoadDocuments()),
                          child: Text('Retry', style: TextStyle(fontSize: screenWidth * 0.04)),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (state.documents.isEmpty && !state.isSearching) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: screenWidth * 0.15, color: Theme.of(context).colorScheme.outline),
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        'No documents yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: screenWidth * 0.05),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        'Add your first document',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: screenWidth * 0.04,
                            ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => BlocProvider.value(
                              value: context.read<DocumentBloc>(),
                              child: const AddDocumentPage(),
                            ),
                          ),
                        ),
                        icon: Icon(Icons.add, size: screenWidth * 0.05),
                        label: Text('Add Document', style: TextStyle(fontSize: screenWidth * 0.04)),
                      ),
                    ],
                  ),
                );
              }
              if (state.documents.isEmpty && state.isSearching && state.searchQuery!.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: screenWidth * 0.15, color: Theme.of(context).colorScheme.outline),
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        'No results for "${state.searchQuery}"',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: screenWidth * 0.05),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        'Try a different search term',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: screenWidth * 0.04,
                            ),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<DocumentBloc>().add(const LoadDocuments());
                  await Future.delayed(const Duration(milliseconds: 400));
                },
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                  itemCount: state.documents.length,
                  itemBuilder: (context, index) {
                    final doc = state.documents[index];
                    return _DocumentListTile(
                      document: doc,
                      onTap: () {
                        // Navigate to detail when route is available
                        Navigator.of(context).pushNamed(AppRouter.documents);
                      },
                      onDelete: () => _confirmDelete(context, doc),
                    );
                  },
                ),
              );
            },
          ),
          floatingActionButton: BlocBuilder<DocumentBloc, DocumentState>(
            buildWhen: (p, c) => c.documents.isNotEmpty,
            builder: (context, state) {
              if (state.documents.isEmpty || state.isSearching) return const SizedBox.shrink();
              return FloatingActionButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: context.read<DocumentBloc>(),
                      child: const AddDocumentPage(),
                    ),
                  ),
                ),
                child: Icon(Icons.add, size: screenWidth * 0.06),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Document doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete document?', style: TextStyle(fontSize: MediaQuery.of(ctx).size.width * 0.05)),
        content: Text('"${doc.title}" will be permanently deleted.', style: TextStyle(fontSize: MediaQuery.of(ctx).size.width * 0.04)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(fontSize: MediaQuery.of(ctx).size.width * 0.04)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: Text('Delete', style: TextStyle(fontSize: MediaQuery.of(ctx).size.width * 0.04)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<DocumentBloc>().add(DeleteDocumentEvent(doc.id));
    }
  }
}

class _DocumentListTile extends StatelessWidget {
  final Document document;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DocumentListTile({
    required this.document,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Card(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.01),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          radius: screenWidth * 0.06,
          child: Icon(
            _iconForFileType(document.fileType),
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: screenWidth * 0.07,
          ),
        ),
        title: Text(document.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: screenWidth * 0.045)),
        subtitle: Text(
          '${document.fileType} • ${_formatDate(document.updatedAt)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: screenWidth * 0.035),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, size: screenWidth * 0.06),
          onSelected: (value) {
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(fontSize: screenWidth * 0.04))),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  IconData _iconForFileType(String type) {
    final t = type.toLowerCase();
    if (t.contains('pdf')) return Icons.picture_as_pdf;
    if (t.contains('image') || t.contains('png') || t.contains('jpg')) return Icons.image;
    return Icons.description;
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${d.day}/${d.month}/${d.year}';
  }
}
