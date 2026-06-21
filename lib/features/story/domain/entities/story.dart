import 'package:equatable/equatable.dart';

class Story extends Equatable {
  final String id;
  final String userId;
  final String? title;
  final String audioPath;
  final int duration;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Story({
    required this.id,
    required this.userId,
    this.title,
    required this.audioPath,
    required this.duration,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, userId, title, audioPath, duration, createdAt, updatedAt];
}
