import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/idea.dart';
import '../bloc/idea_bloc.dart';
import '../bloc/idea_event.dart';
import '../bloc/idea_state.dart';

class IdeasInboxPage extends StatelessWidget {
  const IdeasInboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('Ideas', style: TextStyle(fontSize: screenWidth * 0.05)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, size: screenWidth * 0.06),
            onPressed: () => _showAddIdeaDialog(context),
          ),
        ],
      ),
      body: BlocConsumer<IdeaBloc, IdeaState>(
        listenWhen: (prev, curr) => prev.errorMessage != curr.errorMessage && curr.errorMessage != null,
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!), backgroundColor: Theme.of(context).colorScheme.error),
            );
          }
        },
        builder: (context, state) {
          if (state.status == IdeasListStatus.loading && state.ideas.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == IdeasListStatus.error && state.ideas.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.06),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.errorMessage ?? 'Failed to load', textAlign: TextAlign.center, style: TextStyle(fontSize: screenWidth * 0.04)),
                    SizedBox(height: screenHeight * 0.02),
                    TextButton(
                      onPressed: () => context.read<IdeaBloc>().add(const LoadIdeas()),
                      child: Text('Retry', style: TextStyle(fontSize: screenWidth * 0.04)),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state.ideas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lightbulb_outline, size: screenWidth * 0.15, color: Theme.of(context).colorScheme.outline),
                  SizedBox(height: screenHeight * 0.02),
                  Text('No ideas yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: screenWidth * 0.05)),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    'Capture your first idea',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: screenWidth * 0.04,
                        ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  FilledButton.icon(
                    onPressed: () => _showAddIdeaDialog(context),
                    icon: Icon(Icons.add, size: screenWidth * 0.05),
                    label: Text('Add Idea', style: TextStyle(fontSize: screenWidth * 0.04)),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              context.read<IdeaBloc>().add(const LoadIdeas());
              await Future.delayed(const Duration(milliseconds: 400));
            },
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01, horizontal: screenWidth * 0.04),
              itemCount: state.ideas.length,
              itemBuilder: (context, index) {
                final idea = state.ideas[index];
                return _IdeaCard(
                  idea: idea,
                  onLike: () => context.read<IdeaBloc>().add(LikeIdeaEvent(idea.id)),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: BlocBuilder<IdeaBloc, IdeaState>(
        buildWhen: (p, c) => c.ideas.isNotEmpty,
        builder: (context, state) {
          if (state.ideas.isEmpty) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: () => _showAddIdeaDialog(context),
            child: Icon(Icons.add, size: screenWidth * 0.06),
          );
        },
      ),
    );
  }

  void _showAddIdeaDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final titleController = TextEditingController();
    final descController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('New Idea', style: TextStyle(fontSize: screenWidth * 0.05)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(fontSize: screenWidth * 0.04),
              ),
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(fontSize: screenWidth * 0.04),
            ),
            SizedBox(height: screenHeight * 0.015),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(fontSize: screenWidth * 0.04),
              ),
              maxLines: 3,
              style: TextStyle(fontSize: screenWidth * 0.04),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Cancel', style: TextStyle(fontSize: screenWidth * 0.04))),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              context.read<IdeaBloc>().add(CreateIdeaEvent(
                    title: title,
                    description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                  ));
              Navigator.of(ctx).pop();
            },
            child: Text('Add', style: TextStyle(fontSize: screenWidth * 0.04)),
          ),
        ],
      ),
    );
  }
}

class _IdeaCard extends StatelessWidget {
  final Idea idea;
  final VoidCallback onLike;

  const _IdeaCard({required this.idea, required this.onLike});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Card(
      margin: EdgeInsets.only(bottom: screenHeight * 0.01),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFF59E0B).withOpacity(0.2),
          radius: screenWidth * 0.06,
          child: Icon(Icons.lightbulb_outline, color: const Color(0xFFF59E0B), size: screenWidth * 0.07),
        ),
        title: Text(idea.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: screenWidth * 0.045)),
        subtitle: idea.description != null && idea.description!.isNotEmpty
            ? Text(idea.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: screenWidth * 0.035))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(idea.likes > 0 ? Icons.favorite : Icons.favorite_border, color: Theme.of(context).colorScheme.primary, size: screenWidth * 0.06),
              onPressed: onLike,
            ),
            Text('${idea.likes}', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: screenWidth * 0.035)),
          ],
        ),
      ),
    );
  }
}
