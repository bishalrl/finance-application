import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/add_project_bloc.dart';
import '../bloc/project_bloc.dart';
import '../bloc/project_state.dart';

class AddProjectPage extends StatelessWidget {
  const AddProjectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocProvider(
      create: (context) => AddProjectBloc(
        projectBloc: context.read<ProjectBloc>(),
      )..add(ResetAddProjectState()),
      child: BlocConsumer<AddProjectBloc, AddProjectState>(
        listener: (context, state) {
          if (state is AddProjectSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Project added')),
            );
            Navigator.of(context).pop(true);
          } else if (state is AddProjectFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final addProjectState = state is AddProjectInitial ? state : AddProjectInitial();

          return Scaffold(
            appBar: AppBar(
              title: Text('New project', style: TextStyle(fontSize: screenWidth * 0.05)),
              actions: [
                TextButton(
                  onPressed: addProjectState.isSubmitting ? null : () => context.read<AddProjectBloc>().add(SubmitProject()),
                  child: addProjectState.isSubmitting
                      ? SizedBox(
                          width: screenWidth * 0.06,
                          height: screenWidth * 0.06,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Save', style: TextStyle(fontSize: screenWidth * 0.04)),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: TextEditingController(text: addProjectState.title),
                    onChanged: (value) => context.read<AddProjectBloc>().add(TitleChanged(value)),
                    decoration: InputDecoration(
                      labelText: 'Title',
                      hintText: 'What is this about?',
                      labelStyle: TextStyle(fontSize: screenWidth * 0.04),
                      hintStyle: TextStyle(fontSize: screenWidth * 0.04),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(fontSize: screenWidth * 0.04),
                  ),
                  SizedBox(height: screenHeight * 0.025),
                  Text(
                    'Vision',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: screenWidth * 0.04,
                        ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  TextField(
                    controller: TextEditingController(text: addProjectState.vision),
                    onChanged: (value) => context.read<AddProjectBloc>().add(VisionChanged(value)),
                    decoration: InputDecoration(
                      hintText: 'Why does this matter? What would success feel like?',
                      alignLabelWithHint: true,
                      hintStyle: TextStyle(fontSize: screenWidth * 0.04),
                    ),
                    maxLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(fontSize: screenWidth * 0.04),
                  ),
                  if (addProjectState.errorMessage != null) ...[
                    SizedBox(height: screenHeight * 0.02),
                    Text(addProjectState.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: screenWidth * 0.04)),
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
