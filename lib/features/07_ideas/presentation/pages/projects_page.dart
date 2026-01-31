import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/project.dart';
import '../bloc/project_bloc.dart';
import '../bloc/project_event.dart';
import '../bloc/project_state.dart';
import '../widgets/project_card.dart';
import 'project_detail_page.dart';
import 'add_project_page.dart';

/// Project Handler home: grid/list of projects. Calm, no productivity scoring.
class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('Projects', style: TextStyle(fontSize: screenWidth * 0.05)),
        actions: [
          PopupMenuButton<ProjectSortOption>(
            icon: Icon(Icons.sort, size: screenWidth * 0.06),
            tooltip: 'Sort',
            onSelected: (option) {
              context.read<ProjectBloc>().add(SortProjects(option));
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ProjectSortOption.importance,
                child: ListTile(
                  leading: Icon(Icons.star_outline, size: screenWidth * 0.05),
                  title: Text('Importance (likes)', style: TextStyle(fontSize: screenWidth * 0.04)),
                ),
              ),
              PopupMenuItem(
                value: ProjectSortOption.recent,
                child: ListTile(
                  leading: Icon(Icons.schedule, size: screenWidth * 0.05),
                  title: Text('Recent activity', style: TextStyle(fontSize: screenWidth * 0.04)),
                ),
              ),
              PopupMenuItem(
                value: ProjectSortOption.needsReview,
                child: ListTile(
                  leading: Icon(Icons.rate_review_outlined, size: screenWidth * 0.05),
                  title: Text('Needs review', style: TextStyle(fontSize: screenWidth * 0.04)),
                ),
              ),
              PopupMenuItem(
                value: ProjectSortOption.alphabetical,
                child: ListTile(
                  leading: Icon(Icons.sort_by_alpha, size: screenWidth * 0.05),
                  title: Text('Alphabetical', style: TextStyle(fontSize: screenWidth * 0.04)),
                ),
              ),
            ],
          ),
          BlocBuilder<ProjectBloc, ProjectState>(
            buildWhen: (p, c) => p.isGridView != c.isGridView,
            builder: (context, state) {
              return IconButton(
                icon: Icon(state.isGridView ? Icons.view_list : Icons.grid_view, size: screenWidth * 0.06),
                onPressed: () => context.read<ProjectBloc>().add(const ToggleViewMode()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.add, size: screenWidth * 0.06),
            onPressed: () => _openAddProject(context),
          ),
        ],
      ),
      body: BlocConsumer<ProjectBloc, ProjectState>(
        listenWhen: (prev, curr) =>
            prev.errorMessage != curr.errorMessage && curr.errorMessage != null,
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == ProjectListStatus.loading && state.projects.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == ProjectListStatus.error && state.projects.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.06),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.errorMessage ?? 'Something went wrong',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: screenWidth * 0.04),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    TextButton(
                      onPressed: () => context.read<ProjectBloc>().add(const LoadProjects()),
                      child: Text('Retry', style: TextStyle(fontSize: screenWidth * 0.04)),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state.sortedProjects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_special_outlined,
                    size: screenWidth * 0.15,
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.6),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    'No projects yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: screenWidth * 0.05),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    'A project is a living thought — why does it matter?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: screenWidth * 0.04,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  FilledButton.icon(
                    onPressed: () => _openAddProject(context),
                    icon: Icon(Icons.add, size: screenWidth * 0.05),
                    label: Text('Add project', style: TextStyle(fontSize: screenWidth * 0.04)),
                  ),
                ],
              ),
            );
          }
          if (state.isGridView) {
            return GridView.builder(
              padding: EdgeInsets.all(screenWidth * 0.04),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: screenWidth > 600 ? 3 : 2, // Adjust crossAxisCount based on screen width
                mainAxisSpacing: screenWidth * 0.03,
                crossAxisSpacing: screenWidth * 0.03,
                childAspectRatio: 0.85, // Keep aspect ratio for consistent card size
              ),
              itemCount: state.sortedProjects.length,
              itemBuilder: (context, index) {
                final project = state.sortedProjects[index];
                return ProjectCard(
                  project: project,
                  isCompact: true,
                  onTap: () => _openDetail(context, project),
                  onLike: () => context.read<ProjectBloc>().add(LikeProjectEvent(project.id)),
                );
              },
            );
          }
          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.01),
            itemCount: state.sortedProjects.length,
            itemBuilder: (context, index) {
              final project = state.sortedProjects[index];
              return ProjectCard(
                project: project,
                isCompact: false,
                onTap: () => _openDetail(context, project),
                onLike: () => context.read<ProjectBloc>().add(LikeProjectEvent(project.id)),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddProject(context),
        child: Icon(Icons.add, size: screenWidth * 0.06),
      ),
    );
  }

  void _openAddProject(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<ProjectBloc>(),
          child: const AddProjectPage(),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, Project project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<ProjectBloc>(),
          child: ProjectDetailPage(project: project),
        ),
      ),
    );
  }
}
