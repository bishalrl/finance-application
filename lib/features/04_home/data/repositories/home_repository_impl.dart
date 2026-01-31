import 'package:dartz/dartz.dart';
import 'package:life_vault/core/errors/failures.dart';
import 'package:life_vault/features/04_home/domain/entities/dashboard_stats.dart';
import 'package:life_vault/features/04_home/domain/entities/recent_item.dart';
import 'package:life_vault/features/04_home/domain/repositories/home_repository.dart';
import 'package:life_vault/features/05_documents/domain/entities/document.dart';
import 'package:life_vault/features/05_documents/domain/repositories/document_repository.dart';
import 'package:life_vault/features/06_notes/domain/entities/note.dart';
import 'package:life_vault/features/06_notes/domain/repositories/note_repository.dart';
import 'package:life_vault/features/07_ideas/domain/entities/idea.dart';
import 'package:life_vault/features/07_ideas/domain/repositories/idea_repository.dart';
import 'package:life_vault/features/08_reminders/domain/entities/reminder.dart';
import 'package:life_vault/features/08_reminders/domain/repositories/reminder_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  final DocumentRepository _documentRepository;
  final NoteRepository _noteRepository;
  final IdeaRepository _ideaRepository;
  final ReminderRepository _reminderRepository;

  HomeRepositoryImpl({
    required DocumentRepository documentRepository,
    required NoteRepository noteRepository,
    required IdeaRepository ideaRepository,
    required ReminderRepository reminderRepository,
  })  : _documentRepository = documentRepository,
        _noteRepository = noteRepository,
        _ideaRepository = ideaRepository,
        _reminderRepository = reminderRepository;

  @override
  Future<Either<Failure, DashboardStats>> getDashboardStats() async {
    try {
      final docResult = await _documentRepository.getAllDocuments();
      final noteResult = await _noteRepository.getAllNotes();
      final ideaResult = await _ideaRepository.getIdeasInbox();
      final reminderResult = await _reminderRepository.getAllReminders();
      final expiredResult = await _documentRepository.getExpiredDocuments();
      final upcomingResult = await _reminderRepository.getUpcomingReminders();

      final documentCount = docResult.fold((_) => 0, (list) => list.length);
      final noteCount = noteResult.fold((_) => 0, (list) => list.length);
      final ideaCount = ideaResult.fold((_) => 0, (list) => list.length);
      final reminderCount = reminderResult.fold((_) => 0, (list) => list.length);
      final expiredDocuments = expiredResult.fold((_) => 0, (list) => list.length);
      final upcomingReminders = upcomingResult.fold((_) => 0, (list) => list.length);

      return Right(DashboardStats(
        documentCount: documentCount,
        noteCount: noteCount,
        reminderCount: reminderCount,
        ideaCount: ideaCount,
        expiredDocuments: expiredDocuments,
        upcomingReminders: upcomingReminders,
      ));
    } catch (e) {
      return Left(CacheFailure('Failed to get dashboard stats: $e'));
    }
  }

  @override
  Future<Either<Failure, List<RecentItem>>> getRecentItems() async {
    try {
      final docResult = await _documentRepository.getAllDocuments();
      final noteResult = await _noteRepository.getAllNotes();
      final ideaResult = await _ideaRepository.getIdeasInbox();

      final documents = docResult.fold((_) => <Document>[], (list) => list);
      final notes = noteResult.fold((_) => <Note>[], (list) => list);
      final ideas = ideaResult.fold((_) => <Idea>[], (list) => list);

      final docItems = documents
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      final noteItems = notes
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      final ideaItems = ideas
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      final recentDocs = docItems.take(5).map((d) => RecentItem(
            type: RecentItemType.document,
            id: d.id,
            title: d.title,
            subtitle: d.fileType,
            updatedAt: d.updatedAt,
          ));
      final recentNotes = noteItems.take(5).map((n) => RecentItem(
            type: RecentItemType.note,
            id: n.id,
            title: n.title,
            subtitle: n.content.length > 50 ? '${n.content.substring(0, 50)}...' : n.content,
            updatedAt: n.updatedAt,
          ));
      final recentIdeas = ideaItems.take(5).map((i) => RecentItem(
            type: RecentItemType.idea,
            id: i.id,
            title: i.title,
            subtitle: i.description,
            updatedAt: i.updatedAt,
          ));

      final merged = [...recentDocs, ...recentNotes, ...recentIdeas]
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return Right(merged.take(10).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to get recent items: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Reminder>>> getUpcomingReminders() async {
    return await _reminderRepository.getUpcomingReminders();
  }
}
