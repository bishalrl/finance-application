import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/project.dart';
import '../bloc/project_bloc.dart';
import '../bloc/project_detail_bloc.dart';

/// Inside a project: Vision, Notes, Attachments, Review. No task lists, no velocity.
class ProjectDetailPage extends StatelessWidget {
  final Project project;

  const ProjectDetailPage({super.key, required this.project});

  void _openReviewDialog(BuildContext context, ProjectDetailBloc bloc) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set review reminder', style: TextStyle(fontSize: screenWidth * 0.05)),
        content: Text(
          'When would you like to be reminded to review this project?',
          style: TextStyle(fontSize: screenWidth * 0.04),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(fontSize: screenWidth * 0.04)),
          ),
          TextButton(
            onPressed: () {
              final next = DateTime.now().add(const Duration(days: 7));
              bloc.add(SetReviewReminder(next));
              Navigator.of(ctx).pop();
            },
            child: Text('In 1 week', style: TextStyle(fontSize: screenWidth * 0.04)),
          ),
          TextButton(
            onPressed: () {
              final next = DateTime.now().add(const Duration(days: 30));
              bloc.add(SetReviewReminder(next));
              Navigator.of(ctx).pop();
            },
            child: Text('In 1 month', style: TextStyle(fontSize: screenWidth * 0.04)),
          ),
          TextButton(
            onPressed: () {
              bloc.add(SetReviewReminder(null));
              Navigator.of(ctx).pop();
            },
            child: Text('No reminder', style: TextStyle(fontSize: screenWidth * 0.04)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocProvider(
      create: (context) => ProjectDetailBloc(
        getProjectById: context.read(),
        updateProject: context.read(),
        setProjectReview: context.read(),
        likeProject: context.read(),
        projectBloc: context.read<ProjectBloc>(),
      )..add(LoadProjectDetail(project.id)),
      child: BlocConsumer<ProjectDetailBloc, ProjectDetailState>(
        listenWhen: (prev, curr) =>
            (prev is ProjectDetailInitial && curr is ProjectDetailInitial && prev.errorMessage != curr.errorMessage && curr.errorMessage != null) ||
            curr is ProjectDetailFailure ||
            curr is ProjectDetailSuccess,
        listener: (context, state) {
          if (state is ProjectDetailFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          } else if (state is ProjectDetailSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Project updated')),
            );
          }
        },
        builder: (context, state) {
          final detailState = state is ProjectDetailInitial ? state : ProjectDetailInitial();
          final currentProject = detailState.project ?? project; // Use initial project if not loaded yet

          if (detailState.isLoading) {
            return Scaffold(
              appBar: AppBar(title: Text(currentProject.title, style: TextStyle(fontSize: screenWidth * 0.05))),
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          if (detailState.errorMessage != null && detailState.project == null) {
            return Scaffold(
              appBar: AppBar(title: Text(currentProject.title, style: TextStyle(fontSize: screenWidth * 0.05))),
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.06),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(detailState.errorMessage!, textAlign: TextAlign.center, style: TextStyle(fontSize: screenWidth * 0.04)),
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
              title: Text(currentProject.title, style: TextStyle(fontSize: screenWidth * 0.05)),
              actions: [
                IconButton(
                  icon: Icon(
                    currentProject.likes > 0 ? Icons.star : Icons.star_border,
                    size: screenWidth * 0.06,
                  ),
                  onPressed: () => context.read<ProjectDetailBloc>().add(LikeProjectFromDetail()),
                  tooltip: 'This matters to me',
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vision section
                  Text(
                    'Vision',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: screenWidth * 0.045,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  TextField(
                    controller: TextEditingController(text: detailState.visionInput),
                    onChanged: (value) => context.read<ProjectDetailBloc>().add(VisionChanged(value)),
                    decoration: InputDecoration(
                      hintText: 'Why does this matter? What would success feel like?',
                      border: const OutlineInputBorder(),
                      alignLabelWithHint: true,
                      hintStyle: TextStyle(fontSize: screenWidth * 0.04),
                    ),
                    maxLines: 5,
                    onSubmitted: (_) => context.read<ProjectDetailBloc>().add(SaveVision()),
                    onTapOutside: (_) => context.read<ProjectDetailBloc>().add(SaveVision()),
                    style: TextStyle(fontSize: screenWidth * 0.04),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  // Notes section (list of note contents)
                  Text(
                    'Notes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: screenWidth * 0.045,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  if (currentProject.notes.isEmpty)
                    Text(
                      'No notes yet. Add reflections over time.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                        fontSize: screenWidth * 0.04,
                      ),
                    )
                  else
                    ...currentProject.notes.map(
                      (note) => Padding(
                        padding: EdgeInsets.only(bottom: screenHeight * 0.015),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(screenWidth * 0.03),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(screenWidth * 0.02),
                          ),
                          child: Text(note, style: theme.textTheme.bodyMedium?.copyWith(fontSize: screenWidth * 0.04)),
                        ),
                      ),
                    ),
                  SizedBox(height: screenHeight * 0.03),
                  // Attachments
                  Text(
                    'Attachments',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: screenWidth * 0.045,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  if (currentProject.attachmentIds.isEmpty)
                    Text(
                      'No attachments.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: screenWidth * 0.04,
                      ),
                    )
                  else
                    Text(
                      '${currentProject.attachmentIds.length} file(s)',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: screenWidth * 0.04),
                    ),
                  SizedBox(height: screenHeight * 0.03),
                  // Review section
                  Text(
                    'Review',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: screenWidth * 0.045,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  if (currentProject.lastReviewedAt != null)
                    Text(
                      'Last reviewed: ${DateFormat.yMMMd().format(currentProject.lastReviewedAt!)}',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: screenWidth * 0.04),
                    ),
                  if (currentProject.nextReviewDate != null) ...[
                    SizedBox(height: screenHeight * 0.005),
                    Text(
                      'Next review: ${DateFormat.yMMMd().format(currentProject.nextReviewDate!)}',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: screenWidth * 0.04),
                    ),
                  ],
                  SizedBox(height: screenHeight * 0.015),
                  FilledButton.icon(
                    onPressed: () => _openReviewDialog(context, context.read<ProjectDetailBloc>()),
                    icon: Icon(Icons.rate_review_outlined, size: screenWidth * 0.05),
                    label: Text('Review now', style: TextStyle(fontSize: screenWidth * 0.04)),
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
