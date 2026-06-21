import 'package:equatable/equatable.dart';

class VoiceRecording extends Equatable {
  final String id;
  final String filePath;
  final String fileName;
  final int duration; // in seconds
  final DateTime createdAt;
  final int fileSize; // in bytes

  const VoiceRecording({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.duration,
    required this.createdAt,
    required this.fileSize,
  });

  @override
  List<Object?> get props => [id, filePath, fileName, duration, createdAt, fileSize];
}
