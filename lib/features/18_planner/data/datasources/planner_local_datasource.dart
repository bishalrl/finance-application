import 'package:life_vault/core/database/hive_service.dart';
import '../../domain/entities/planner_moment.dart';
import '../models/planner_moment_model.dart';

class PlannerLocalDataSource {
  final HiveService _hiveService;

  PlannerLocalDataSource(this._hiveService);

  Future<void> saveMoment(PlannerMoment moment) async {
    final box = _hiveService.getBox(HiveService.plannerMomentsBox);
    await box.put(moment.id, PlannerMomentModel.toMap(moment));
  }

  Future<PlannerMoment?> getMomentById(String id) async {
    final box = _hiveService.getBox(HiveService.plannerMomentsBox);
    final value = box.get(id);
    if (value == null || value is! Map) return null;
    return PlannerMomentModel.fromMap(Map<String, dynamic>.from(value as Map));
  }

  Future<List<PlannerMoment>> getAllMoments() async {
    final box = _hiveService.getBox(HiveService.plannerMomentsBox);
    final list = <PlannerMoment>[];
    for (final value in box.values) {
      if (value is Map) {
        list.add(PlannerMomentModel.fromMap(Map<String, dynamic>.from(value as Map)));
      }
    }
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  Future<List<PlannerMoment>> getMomentsForDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final all = await getAllMoments();
    return all.where((m) {
      final d = m.date;
      final inRange = !d.isBefore(start) && d.isBefore(end);
      if (inRange) return true;
      if (m.dateEnd != null) {
        final overlap = m.date.isBefore(end) && m.dateEnd!.isAfter(start);
        if (overlap) return true;
      }
      return false;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<List<PlannerMoment>> getMomentsInRange(DateTime start, DateTime end) async {
    final all = await getAllMoments();
    return all.where((m) {
      if (m.dateEnd == null) {
        return !m.date.isBefore(start) && !m.date.isAfter(end);
      }
      return m.date.isBefore(end) && m.dateEnd!.isAfter(start);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> updateMoment(PlannerMoment moment) async {
    await saveMoment(moment);
  }

  Future<void> deleteMoment(String id) async {
    final box = _hiveService.getBox(HiveService.plannerMomentsBox);
    await box.delete(id);
  }
}
