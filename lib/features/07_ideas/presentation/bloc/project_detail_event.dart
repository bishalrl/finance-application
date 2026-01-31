part of 'project_detail_bloc.dart';

@immutable
sealed class ProjectDetailEvent {}

class LoadProjectDetail extends ProjectDetailEvent {
  final String projectId;

  LoadProjectDetail(this.projectId);
}

class VisionChanged extends ProjectDetailEvent {
  final String vision;

  VisionChanged(this.vision);
}

class SaveVision extends ProjectDetailEvent {}

class SetReviewReminder extends ProjectDetailEvent {
  final DateTime? nextReviewDate;

  SetReviewReminder(this.nextReviewDate);
}

class LikeProjectFromDetail extends ProjectDetailEvent {}
