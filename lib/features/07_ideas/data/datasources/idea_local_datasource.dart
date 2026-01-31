import 'package:hive/hive.dart';
import 'package:life_vault/core/database/hive_service.dart';
import '../models/idea_model.dart';
import '../models/project_model.dart';
import '../../domain/entities/idea.dart';
import '../../domain/entities/project.dart';

class IdeaLocalDataSource {
  final HiveService _hiveService;

  IdeaLocalDataSource(this._hiveService);

  Future<void> saveIdea(IdeaModel idea) async {
    final box = _hiveService.getBox(HiveService.ideasBox);
    await box.put(idea.id, idea);
  }

  Future<IdeaModel?> getIdeaById(String id) async {
    final box = _hiveService.getBox(HiveService.ideasBox);
    return box.get(id) as IdeaModel?;
  }

  Future<List<IdeaModel>> getAllIdeas() async {
    final box = _hiveService.getBox(HiveService.ideasBox);
    return box.values.cast<IdeaModel>().toList();
  }

  Future<List<IdeaModel>> getIdeasInbox() async {
    final all = await getAllIdeas();
    return all.where((i) => i.status == IdeaStatus.inbox).toList();
  }

  Future<List<IdeaModel>> getIdeasByLikes() async {
    final all = await getAllIdeas();
    all.sort((a, b) => b.likes.compareTo(a.likes));
    return all;
  }

  Future<void> saveProject(Project project) async {
    final box = _hiveService.getBox(HiveService.projectsBox);
    await box.put(project.id, ProjectModel.toMap(project));
  }

  Future<List<Project>> getAllProjects() async {
    final box = _hiveService.getBox(HiveService.projectsBox);
    final list = <Project>[];
    for (final value in box.values) {
      if (value is Map) {
        list.add(ProjectModel.fromMap(Map<String, dynamic>.from(value as Map)));
      }
    }
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  Future<Project?> getProjectById(String id) async {
    final box = _hiveService.getBox(HiveService.projectsBox);
    final value = box.get(id);
    if (value == null || value is! Map) return null;
    return ProjectModel.fromMap(Map<String, dynamic>.from(value as Map));
  }

  Future<void> updateProject(Project project) async {
    await saveProject(project);
  }
}
