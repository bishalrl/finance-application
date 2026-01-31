import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_vault/features/05_documents/domain/usecases/add_document.dart';
import '../../../../core/config/dependency_injection.dart' as di;
import '../../domain/entities/document.dart';
import '../bloc/add_document_bloc.dart';
import '../bloc/document_bloc.dart';
import '../bloc/document_event.dart';

/// Add document: pick file, preserve name, store in app sandbox (no compression).
/// Foundation: "Files are not modified", "File names preserved".
class AddDocumentPage extends StatelessWidget {
  const AddDocumentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddDocumentBloc(
        addDocument: di.sl<AddDocument>(),
        documentBloc: context.read<DocumentBloc>(),
      )..add(ResetAddDocumentState()),
      child: BlocConsumer<AddDocumentBloc, AddDocumentState>(
        listener: (context, state) {
          if (state is AddDocumentSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document saved')));
            Navigator.of(context).pop(true);
          } else if (state is AddDocumentFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Theme.of(context).colorScheme.error),
            );
          }
        },
        builder: (context, state) {
          final addDocumentState = state is AddDocumentInitial ? state : AddDocumentInitial();
          final screenWidth = MediaQuery.of(context).size.width;
          final screenHeight = MediaQuery.of(context).size.height;

          return Scaffold(
            appBar: AppBar(
              title: Text('Add Document', style: TextStyle(fontSize: screenWidth * 0.05)),
              actions: [
                if (addDocumentState.isSaving)
                  Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: SizedBox(width: screenWidth * 0.06, height: screenWidth * 0.06, child: const CircularProgressIndicator(strokeWidth: 2)),
                  )
                else
                  TextButton(
                    onPressed: addDocumentState.fileBytes != null
                        ? () => context.read<AddDocumentBloc>().add(SaveDocument())
                        : null,
                    child: Text('Save', style: TextStyle(fontSize: screenWidth * 0.04)),
                  ),
              ],
            ),
            body: SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: addDocumentState.isSaving ? null : () => context.read<AddDocumentBloc>().add(PickFile()),
                    icon: Icon(Icons.upload_file, size: screenWidth * 0.06),
                    label: Text(
                      addDocumentState.fileName == null ? 'Pick file (PDF, images, text…)' : 'File: ${addDocumentState.fileName}',
                      style: TextStyle(fontSize: screenWidth * 0.04),
                    ),
                  ),
                  if (addDocumentState.fileName != null) ...[
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      'File name preserved · Stored in app only',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: screenWidth * 0.035,
                          ),
                    ),
                  ],
                  SizedBox(height: screenHeight * 0.03),
                  TextField(
                    controller: TextEditingController(text: addDocumentState.title),
                    onChanged: (value) => context.read<AddDocumentBloc>().add(TitleChanged(value)),
                    decoration: InputDecoration(
                      labelText: 'Title',
                      hintText: 'Document title (default: file name)',
                      border: const OutlineInputBorder(),
                      labelStyle: TextStyle(fontSize: screenWidth * 0.04),
                      hintStyle: TextStyle(fontSize: screenWidth * 0.04),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(fontSize: screenWidth * 0.04),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  TextField(
                    controller: TextEditingController(text: addDocumentState.description),
                    onChanged: (value) => context.read<AddDocumentBloc>().add(DescriptionChanged(value)),
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      border: const OutlineInputBorder(),
                      labelStyle: TextStyle(fontSize: screenWidth * 0.04),
                    ),
                    maxLines: 2,
                    style: TextStyle(fontSize: screenWidth * 0.04),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  TextField(
                    controller: TextEditingController(text: addDocumentState.tagsInput),
                    onChanged: (value) => context.read<AddDocumentBloc>().add(TagsInputChanged(value)),
                    decoration: InputDecoration(
                      labelText: 'Tags (optional)',
                      hintText: 'e.g. important, 2026 — comma or space separated',
                      border: const OutlineInputBorder(),
                      labelStyle: TextStyle(fontSize: screenWidth * 0.04),
                      hintStyle: TextStyle(fontSize: screenWidth * 0.04),
                    ),
                    textCapitalization: TextCapitalization.none,
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        context.read<AddDocumentBloc>().add(AddTag(value));
                      }
                    },
                    style: TextStyle(fontSize: screenWidth * 0.04),
                  ),
                  if (addDocumentState.tags.isNotEmpty) ...[
                    SizedBox(height: screenHeight * 0.01),
                    Wrap(
                      spacing: screenWidth * 0.015,
                      runSpacing: screenHeight * 0.01,
                      children: addDocumentState.tags.map((t) => Chip(
                        label: Text(t, style: TextStyle(fontSize: screenWidth * 0.035)),
                        onDeleted: () => context.read<AddDocumentBloc>().add(RemoveTag(t)),
                      )).toList(),
                    ),
                  ],
                  if (addDocumentState.errorMessage != null) ...[
                    SizedBox(height: screenHeight * 0.02),
                    Text(addDocumentState.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: screenWidth * 0.04)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
