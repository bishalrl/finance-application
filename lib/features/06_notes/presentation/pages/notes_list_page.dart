import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/router.dart';
import '../../domain/entities/note.dart';
import '../bloc/note_bloc.dart';
import '../bloc/note_event.dart';
import '../bloc/note_state.dart';

class NotesListPage extends StatelessWidget {
  const NotesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocConsumer<NoteBloc, NoteState>(
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
                      hintText: 'Search notes...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: screenWidth * 0.04),
                    ),
                    style: TextStyle(fontSize: screenWidth * 0.04),
                    onChanged: (q) {
                      context.read<NoteBloc>().add(SearchQueryChanged(q));
                    },
                    onSubmitted: (q) {
                      context.read<NoteBloc>().add(SearchNotesEvent(q));
                    },
                  )
                : Text('Notes', style: TextStyle(fontSize: screenWidth * 0.05)),
            actions: [
              IconButton(
                icon: Icon(state.isSearching ? Icons.close : Icons.search, size: screenWidth * 0.06),
                onPressed: () {
                  context.read<NoteBloc>().add(const ToggleSearch());
                  if (!state.isSearching) {
                    // If search is being closed, clear the search query and reload notes
                    context.read<NoteBloc>().add(const SearchNotesEvent(''));
                  }
                },
              ),
              if (!state.isSearching)
                IconButton(
                  icon: Icon(Icons.add, size: screenWidth * 0.06),
                  onPressed: () => Navigator.of(context).pushNamed(AppRouter.noteEditor),
                ),
            ],
          ),
          body: Builder(
            builder: (context) {
              if (state.status == NoteStatus.loading && state.notes.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == NoteStatus.error && state.notes.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.06),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.errorMessage ?? 'Failed to load', textAlign: TextAlign.center, style: TextStyle(fontSize: screenWidth * 0.04)),
                        SizedBox(height: screenHeight * 0.02),
                        TextButton(
                          onPressed: () => context.read<NoteBloc>().add(const LoadNotes()),
                          child: Text('Retry', style: TextStyle(fontSize: screenWidth * 0.04)),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (state.notes.isEmpty && !state.isSearching) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.note_add, size: screenWidth * 0.15, color: Theme.of(context).colorScheme.outline),
                      SizedBox(height: screenHeight * 0.02),
                      Text('No notes yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: screenWidth * 0.05)),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        'Create your first note',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: screenWidth * 0.04,
                            ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).pushNamed(AppRouter.noteEditor),
                        icon: Icon(Icons.add, size: screenWidth * 0.05),
                        label: Text('New Note', style: TextStyle(fontSize: screenWidth * 0.04)),
                      ),
                    ],
                  ),
                );
              }
              if (state.notes.isEmpty && state.isSearching && state.searchQuery.isNotEmpty) {
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
                  context.read<NoteBloc>().add(const LoadNotes());
                  await Future.delayed(const Duration(milliseconds: 400));
                },
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                  itemCount: state.notes.length,
                  itemBuilder: (context, index) {
                    final note = state.notes[index];
                    return _NoteListTile(
                      note: note,
                      onTap: () => Navigator.of(context).pushNamed(AppRouter.noteEditor, arguments: note.id),
                      onDelete: () => _confirmDelete(context, note),
                    );
                  },
                ),
              );
            },
          ),
          floatingActionButton: BlocBuilder<NoteBloc, NoteState>(
            buildWhen: (p, c) => c.notes.isNotEmpty,
            builder: (context, state) {
              if (state.notes.isEmpty || state.isSearching) return const SizedBox.shrink();
              return FloatingActionButton(
                onPressed: () => Navigator.of(context).pushNamed(AppRouter.noteEditor),
                child: Icon(Icons.add, size: screenWidth * 0.06),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Note note) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete note?', style: TextStyle(fontSize: screenWidth * 0.05)),
        content: Text('"${note.title}" will be permanently deleted.', style: TextStyle(fontSize: screenWidth * 0.04)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(fontSize: screenWidth * 0.04)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: Text('Delete', style: TextStyle(fontSize: screenWidth * 0.04)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<NoteBloc>().add(DeleteNoteEvent(note.id));
    }
  }
}

class _NoteListTile extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NoteListTile({required this.note, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Card(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.01),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          radius: screenWidth * 0.06,
          child: Icon(Icons.note, color: Theme.of(context).colorScheme.onPrimaryContainer, size: screenWidth * 0.07),
        ),
        title: Text(note.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: screenWidth * 0.045)),
        subtitle: Text(
          note.preview,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: screenWidth * 0.035),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, size: screenWidth * 0.06),
          onSelected: (value) { if (value == 'delete') onDelete(); },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(fontSize: screenWidth * 0.04))),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
