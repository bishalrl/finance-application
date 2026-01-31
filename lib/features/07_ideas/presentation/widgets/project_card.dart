import 'package:flutter/material.dart';
import '../../domain/entities/project.dart';

/// Project card: title, short vision snippet, like count, review indicator. Calm, no urgency.
class ProjectCard extends StatelessWidget {
  final Project project;
  final bool isCompact;
  final VoidCallback? onTap;
  final VoidCallback? onLike;

  const ProjectCard({
    super.key,
    required this.project,
    this.isCompact = false,
    this.onTap,
    this.onLike,
  });

  String get _visionSnippet {
    if (project.vision.isEmpty) return 'No vision yet';
    if (project.vision.length <= 80) return project.vision;
    return '${project.vision.substring(0, 80)}…';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      project.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: isCompact ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      project.likes > 0 ? Icons.star : Icons.star_border,
                      size: 20,
                      color: project.likes > 0
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: onLike,
                    tooltip: 'This matters to me',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              if (!isCompact || project.vision.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  _visionSnippet,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: isCompact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  if (project.likes > 0)
                    Text(
                      '${project.likes} ★',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (project.likes > 0 && project.needsReview) const SizedBox(width: 12),
                  if (project.needsReview)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Review',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
