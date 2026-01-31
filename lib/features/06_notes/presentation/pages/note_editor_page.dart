import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/dependency_injection.dart' as di;
import '../../domain/usecases/create_note.dart';
import '../../domain/usecases/get_note_by_id.dart';
import '../../domain/usecases/update_note.dart';
import '../bloc/note_bloc.dart';
import '../bloc/note_editor_bloc.dart';

class NoteEditorPage extends StatelessWidget {
  const NoteEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final noteId = ModalRoute.of(context)?.settings.arguments as String?;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocProvider(
      create: (context) => NoteEditorBloc(
        getNoteById: di.sl<GetNoteById>(),
        createNote: di.sl<CreateNote>(),
        updateNote: di.sl<UpdateNote>(),
        noteBloc: context.read<NoteBloc>(),
      )..add(LoadNote(noteId)),
      child: BlocConsumer<NoteEditorBloc, NoteEditorState>(
        listener: (context, state) {
          if (state is NoteEditorSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note saved')));
            Navigator.of(context).pop(true);
          } else if (state is NoteEditorFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Theme.of(context).colorScheme.error),
            );
          }
        },
        builder: (context, state) {
          final editorState = state is NoteEditorInitial ? state : NoteEditorInitial();

          if (editorState.isLoading) {
            return Scaffold(
              appBar: AppBar(title: Text('Note', style: TextStyle(fontSize: screenWidth * 0.05))),
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          if (editorState.errorMessage != null && editorState.note == null) {
            return Scaffold(
              appBar: AppBar(title: Text('Note', style: TextStyle(fontSize: screenWidth * 0.05))),
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.06),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(editorState.errorMessage!, textAlign: TextAlign.center, style: TextStyle(fontSize: screenWidth * 0.04)),
                      SizedBox(height: screenHeight * 0.02),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Back', style: TextStyle(fontSize: screenWidth * 0.04)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return Scaffold(
            appBar: AppBar(
              title: Text(editorState.note != null ? 'Edit Note' : 'New Note', style: TextStyle(fontSize: screenWidth * 0.05)),
              actions: [
                if (editorState.isSaving)
                  Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: SizedBox(
                      width: screenWidth * 0.06,
                      height: screenWidth * 0.06,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  TextButton(
                    onPressed: () => context.read<NoteEditorBloc>().add(SaveNote()),
                    child: Text('Save', style: TextStyle(fontSize: screenWidth * 0.04)),
                  ),
              ],
            ),
            body: Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: TextEditingController(text: editorState.title),
                    onChanged: (value) => context.read<NoteEditorBloc>().add(TitleChanged(value)),
                    decoration: InputDecoration(
                      labelText: 'Title',
                      hintText: 'Note title',
                      border: const OutlineInputBorder(),
                      labelStyle: TextStyle(fontSize: screenWidth * 0.04),
                      hintStyle: TextStyle(fontSize: screenWidth * 0.04),
                    ),
                    maxLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(fontSize: screenWidth * 0.04),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  // Tags (foundation: "Notes can have multiple tags", "Tags global, reusable")
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(text: editorState.tagInput),
                          onChanged: (value) => context.read<NoteEditorBloc>().add(TagInputChanged(value)),
                          decoration: InputDecoration(
                            labelText: 'Tags',
                            hintText: 'Add tag…',
                            border: const OutlineInputBorder(),
                            labelStyle: TextStyle(fontSize: screenWidth * 0.04),
                            hintStyle: TextStyle(fontSize: screenWidth * 0.04),
                          ),
                          textCapitalization: TextCapitalization.none,
                          onSubmitted: (_) => context.read<NoteEditorBloc>().add(AddTag()),
                          style: TextStyle(fontSize: screenWidth * 0.04),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      IconButton(
                        onPressed: () => context.read<NoteEditorBloc>().add(AddTag()),
                        icon: Icon(Icons.add, size: screenWidth * 0.06),
                        tooltip: 'Add tag',
                      ),
                    ],
                  ),
                  if (editorState.tags.isNotEmpty) ...[
                    SizedBox(height: screenHeight * 0.01),
                    Wrap(
                      spacing: screenWidth * 0.015,
                      runSpacing: screenHeight * 0.01,
                      children: editorState.tags.map((tag) => Chip(
                        label: Text(tag, style: TextStyle(fontSize: screenWidth * 0.035)),
                        onDeleted: () => context.read<NoteEditorBloc>().add(RemoveTag(tag)),
                      )).toList(),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                  ],
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: editorState.content),
                      onChanged: (value) => context.read<NoteEditorBloc>().add(ContentChanged(value)),
                      decoration: InputDecoration(
                        labelText: 'Content',
                        hintText: 'Write your note... (plain text or markdown)',
                        alignLabelWithHint: true,
                        border: const OutlineInputBorder(),
                        labelStyle: TextStyle(fontSize: screenWidth * 0.04),
                        hintStyle: TextStyle(fontSize: screenWidth * 0.04),
                      ),
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: TextStyle(fontSize: screenWidth * 0.04),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
