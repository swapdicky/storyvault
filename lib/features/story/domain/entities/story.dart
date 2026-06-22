import 'package:equatable/equatable.dart';

class Story extends Equatable {
  final String id;
  final String userId;
  final String? title;
  final String audioPath;
  final int duration;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? transcript;

  const Story({
    required this.id,
    required this.userId,
    this.title,
    required this.audioPath,
    required this.duration,
    required this.createdAt,
    required this.updatedAt,
    this.transcript,
  });

  @override
  List<Object?> get props => [id, userId, title, audioPath, duration, createdAt, updatedAt, transcript];

  Story copyWith({
    String? id,
    String? userId,
    String? title,
    String? audioPath,
    int? duration,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? transcript,
  }) {
    return Story(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      audioPath: audioPath ?? this.audioPath,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      transcript: transcript ?? this.transcript,
    );
  }
}
