import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/recording.dart';

abstract class RecordingRepository {
  Future<Either<Failure, void>> startRecording();
  Future<Either<Failure, void>> pauseRecording();
  Future<Either<Failure, void>> resumeRecording();
  Future<Either<Failure, VoiceRecording>> stopRecording();
  Future<Either<Failure, List<VoiceRecording>>> getRecordings();
  Future<Either<Failure, void>> deleteRecording(String id);
  Future<Either<Failure, void>> playRecording(String filePath);
  Future<Either<Failure, void>> pausePlayback();
  Future<Either<Failure, void>> stopPlayback();
  Future<bool> isRecording();
  Future<bool> isPlaying();
  Stream<Duration>? get recordingDuration;
  Stream<Duration>? get playbackPosition;
  void dispose();
}
